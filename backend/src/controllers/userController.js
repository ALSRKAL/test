const User = require('../models/User');
const Photographer = require('../models/Photographer');
const logger = require('../utils/logger');
const cloudinary = require('../config/cloudinary');

// @desc    Get user profile
// @route   GET /api/users/profile
// @access  Private
exports.getProfile = async (req, res, next) => {
  try {
    const user = await User.findById(req.user._id).populate('favorites');

    logger.info(`Getting profile for user: ${req.user._id}`);

    // Get user statistics
    const Booking = require('../models/Booking');
    const Review = require('../models/Review');

    const [totalBookings, completedBookings, cancelledBookings, totalReviews] =
      await Promise.all([
        Booking.countDocuments({ client: req.user._id }),
        Booking.countDocuments({ client: req.user._id, status: 'completed' }),
        Booking.countDocuments({ client: req.user._id, status: 'cancelled' }),
        Review.countDocuments({ client: req.user._id }),
      ]);

    const statistics = {
      totalBookings,
      completedBookings,
      cancelledBookings,
      totalReviews,
      favoritesCount: user.favorites?.length || 0,
    };

    logger.info(`Profile loaded for user ${req.user._id} with statistics:`, statistics);

    res.status(200).json({
      success: true,
      data: {
        ...user.toJSON(),
        statistics,
      },
    });
  } catch (error) {
    logger.error('Error in getProfile:', error);
    next(error);
  }
};

// @desc    Update user profile
// @route   PUT /api/users/profile
// @access  Private
exports.updateProfile = async (req, res, next) => {
  try {
    const { name, phone, avatar } = req.body;

    const user = await User.findByIdAndUpdate(
      req.user._id,
      { name, phone, avatar },
      { new: true, runValidators: true }
    );

    logger.info(`User profile updated: ${user.email}`);

    res.status(200).json({
      success: true,
      message: 'Profile updated successfully',
      data: user,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get user favorites
// @route   GET /api/users/favorites
// @access  Private
exports.getFavorites = async (req, res, next) => {
  try {
    const user = await User.findById(req.user._id).populate({
      path: 'favorites',
      populate: { path: 'user', select: 'name email avatar' },
    });

    res.status(200).json({
      success: true,
      data: user.favorites,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Add photographer to favorites
// @route   POST /api/users/favorites/:photographerId
// @access  Private
exports.addToFavorites = async (req, res, next) => {
  try {
    const { photographerId } = req.params;

    // Check if photographer exists
    const photographer = await Photographer.findById(photographerId);
    if (!photographer) {
      return res.status(404).json({
        success: false,
        message: 'Photographer not found',
      });
    }

    // Check if already in favorites
    if (req.user.favorites.includes(photographerId)) {
      return res.status(400).json({
        success: false,
        message: 'Photographer already in favorites',
      });
    }

    req.user.favorites.push(photographerId);
    await req.user.save();

    res.status(200).json({
      success: true,
      message: 'Added to favorites',
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Remove photographer from favorites
// @route   DELETE /api/users/favorites/:photographerId
// @access  Private
exports.removeFromFavorites = async (req, res, next) => {
  try {
    const { photographerId } = req.params;

    req.user.favorites = req.user.favorites.filter(
      (id) => id.toString() !== photographerId
    );
    await req.user.save();

    res.status(200).json({
      success: true,
      message: 'Removed from favorites',
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Upload/Update avatar
// @route   POST /api/users/avatar
// @access  Private
exports.uploadAvatar = async (req, res, next) => {
  try {
    logger.info(`Avatar upload request - User: ${req.user._id}, File: ${req.file ? 'YES' : 'NO'}`);
    
    if (!req.file) {
      logger.error('Avatar upload failed: No file provided');
      return res.status(400).json({
        success: false,
        message: 'Please upload an image',
      });
    }

    const user = await User.findById(req.user._id);

    // Delete old avatar from Cloudinary if exists
    if (user.avatar) {
      try {
        // Extract public_id from Cloudinary URL
        // URL format: https://res.cloudinary.com/{cloud_name}/image/upload/v{version}/{folder}/{public_id}.{format}
        const urlParts = user.avatar.split('/');

        // Find the index of 'upload' in the URL
        const uploadIndex = urlParts.indexOf('upload');

        if (uploadIndex !== -1 && uploadIndex < urlParts.length - 1) {
          // Get everything after 'upload' (skip version if exists)
          let pathAfterUpload = urlParts.slice(uploadIndex + 1);

          // Skip version (starts with 'v' followed by numbers)
          if (pathAfterUpload[0] && pathAfterUpload[0].match(/^v\d+$/)) {
            pathAfterUpload = pathAfterUpload.slice(1);
          }

          // Join the remaining parts and remove extension
          const fullPath = pathAfterUpload.join('/');
          const publicId = fullPath.substring(0, fullPath.lastIndexOf('.')) || fullPath;

          await cloudinary.uploader.destroy(publicId);
          logger.info(`Old avatar deleted from Cloudinary: ${publicId}`);
        }
      } catch (deleteError) {
        logger.error(`Error deleting old avatar: ${deleteError.message}`);
        // Continue even if deletion fails
      }
    }

    // Upload new avatar to Cloudinary
    const result = await new Promise((resolve, reject) => {
      const uploadStream = cloudinary.uploader.upload_stream(
        {
          folder: 'hajzy/avatars',
          transformation: [
            { width: 500, height: 500, crop: 'fill', gravity: 'face' },
            { quality: 'auto:good' },
            { fetch_format: 'auto' }
          ]
        },
        (error, result) => {
          if (error) reject(error);
          else resolve(result);
        }
      );
      uploadStream.end(req.file.buffer);
    });

    // Update user avatar
    user.avatar = result.secure_url;
    await user.save();

    logger.info(`Avatar uploaded for user: ${user.email}`);

    res.status(200).json({
      success: true,
      message: 'Avatar uploaded successfully',
      data: {
        avatar: result.secure_url,
      },
    });
  } catch (error) {
    logger.error(`Error uploading avatar: ${error.message}`);
    next(error);
  }
};

// @desc    Delete avatar
// @route   DELETE /api/users/avatar
// @access  Private
exports.deleteAvatar = async (req, res, next) => {
  try {
    const user = await User.findById(req.user._id);

    if (!user.avatar) {
      return res.status(400).json({
        success: false,
        message: 'No avatar to delete',
      });
    }

    // Delete from Cloudinary
    try {
      // Extract public_id from Cloudinary URL
      const urlParts = user.avatar.split('/');

      // Find the index of 'upload' in the URL
      const uploadIndex = urlParts.indexOf('upload');

      if (uploadIndex !== -1 && uploadIndex < urlParts.length - 1) {
        // Get everything after 'upload' (skip version if exists)
        let pathAfterUpload = urlParts.slice(uploadIndex + 1);

        // Skip version (starts with 'v' followed by numbers)
        if (pathAfterUpload[0] && pathAfterUpload[0].match(/^v\d+$/)) {
          pathAfterUpload = pathAfterUpload.slice(1);
        }

        // Join the remaining parts and remove extension
        const fullPath = pathAfterUpload.join('/');
        const publicId = fullPath.substring(0, fullPath.lastIndexOf('.')) || fullPath;

        await cloudinary.uploader.destroy(publicId);
        logger.info(`Avatar deleted from Cloudinary: ${publicId}`);
      }
    } catch (deleteError) {
      logger.error(`Error deleting avatar from Cloudinary: ${deleteError.message}`);
    }

    // Remove avatar from user
    user.avatar = null;
    await user.save();

    res.status(200).json({
      success: true,
      message: 'Avatar deleted successfully',
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Delete user account
// @route   DELETE /api/users/account
// @access  Private
exports.deleteAccount = async (req, res, next) => {
  try {
    const cleanupService = require('../services/cleanupService');

    await cleanupService.deleteUserComplete(req.user._id);

    // logger.info is handled inside cleanupService, but we can add extra context if needed
    // logger.info(`User account deleted: ${req.user.email}`);

    res.status(200).json({
      success: true,
      message: 'Account deleted successfully',
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update OneSignal Player ID
// @route   PUT /api/users/onesignal-player-id
// @access  Private
exports.updateOneSignalPlayerId = async (req, res, next) => {
  try {
    const { playerId } = req.body;

    if (!playerId) {
      return res.status(400).json({
        success: false,
        message: 'Player ID is required',
      });
    }

    const user = await User.findById(req.user._id);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    user.oneSignalPlayerId = playerId;
    await user.save();

    logger.info(`OneSignal Player ID updated for user ${user._id}: ${playerId}`);

    res.status(200).json({
      success: true,
      message: 'OneSignal Player ID updated successfully',
    });
  } catch (error) {
    logger.error('Error in updateOneSignalPlayerId:', error);
    next(error);
  }
};

// @desc    Update notification settings
// @route   PUT /api/users/notification-settings
// @access  Private
exports.updateNotificationSettings = async (req, res, next) => {
  try {
    const { notificationSettings } = req.body;

    if (!notificationSettings) {
      return res.status(400).json({
        success: false,
        message: 'Notification settings are required',
      });
    }

    const user = await User.findById(req.user._id);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    user.notificationSettings = {
      messages: notificationSettings.messages ?? user.notificationSettings.messages,
      bookings: notificationSettings.bookings ?? user.notificationSettings.bookings,
      reviews: notificationSettings.reviews ?? user.notificationSettings.reviews,
    };

    await user.save();

    logger.info(`Notification settings updated for user ${user._id}`);

    res.status(200).json({
      success: true,
      message: 'Notification settings updated successfully',
      data: user.notificationSettings,
    });
  } catch (error) {
    logger.error('Error in updateNotificationSettings:', error);
    next(error);
  }
};

// @desc    Get user statistics
// @route   GET /api/users/statistics
// @access  Private
exports.getUserStatistics = async (req, res, next) => {
  try {
    const Booking = require('../models/Booking');
    const Review = require('../models/Review');

    logger.info(`Getting statistics for user: ${req.user._id}`);

    const [totalBookings, completedBookings, cancelledBookings, totalReviews] =
      await Promise.all([
        Booking.countDocuments({ client: req.user._id }),
        Booking.countDocuments({ client: req.user._id, status: 'completed' }),
        Booking.countDocuments({ client: req.user._id, status: 'cancelled' }),
        Review.countDocuments({ client: req.user._id }),
      ]);

    const statistics = {
      totalBookings,
      completedBookings,
      cancelledBookings,
      totalReviews,
      favoritesCount: req.user.favorites?.length || 0,
    };

    logger.info(`Statistics for user ${req.user._id}:`, statistics);

    res.status(200).json({
      success: true,
      data: statistics,
    });
  } catch (error) {
    logger.error('Error in getUserStatistics:', error);
    next(error);
  }
};
