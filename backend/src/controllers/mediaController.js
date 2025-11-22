const cloudinary = require('../config/cloudinary');
const Photographer = require('../models/Photographer');
const logger = require('../utils/logger');
const imageService = require('../services/imageService');
const videoService = require('../services/videoService');

// @desc    Upload single image
// @route   POST /api/media/upload/image
// @access  Private
exports.uploadImage = async (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'Please upload an image',
      });
    }

    // Upload to Cloudinary
    const result = await new Promise((resolve, reject) => {
      const uploadStream = cloudinary.uploader.upload_stream(
        {
          folder: 'hajzy/images',
          transformation: [
            { width: 1200, height: 1200, crop: 'limit' },
            { quality: 'auto' },
          ],
        },
        (error, result) => {
          if (error) reject(error);
          else resolve(result);
        }
      );
      uploadStream.end(req.file.buffer);
    });

    logger.info(`Image uploaded: ${result.public_id}`);

    res.status(200).json({
      success: true,
      message: 'Image uploaded successfully',
      data: {
        url: result.secure_url,
        publicId: result.public_id,
      },
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Upload multiple images
// @route   POST /api/media/upload/images
// @access  Private (photographer)
exports.uploadImages = async (req, res, next) => {
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Please upload at least one image',
      });
    }

    // Get photographer ID from authenticated user
    const photographer = await Photographer.findOne({ user: req.user._id });
    if (!photographer) {
      return res.status(404).json({
        success: false,
        message: 'Photographer profile not found',
      });
    }

    // Check portfolio limit
    if (photographer.portfolio.images.length + req.files.length > imageService.MAX_IMAGES) {
      return res.status(400).json({
        success: false,
        message: `Portfolio can have maximum ${imageService.MAX_IMAGES} images`,
      });
    }

    // Extract file buffers
    const fileBuffers = req.files.map((file) => file.buffer);

    // Upload using imageService with photographer-specific folder (portfolio subfolder)
    const uploadedImages = await imageService.uploadMultipleImages(
      fileBuffers,
      photographer._id.toString(),
      'portfolio' // Subfolder for portfolio images
    );

    // Add images to portfolio automatically
    uploadedImages.forEach((image) => {
      photographer.portfolio.images.push({
        url: image.url,
        publicId: image.publicId,
      });
    });

    await photographer.save();

    logger.info(`${uploadedImages.length} images uploaded and added to portfolio for photographer ${photographer._id}`);

    res.status(200).json({
      success: true,
      message: 'Images uploaded and added to portfolio successfully',
      data: uploadedImages,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Upload video
// @route   POST /api/media/upload/video
// @access  Private (photographer)
exports.uploadVideo = async (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'Please upload a video',
      });
    }

    // Get photographer ID from authenticated user
    const photographer = await Photographer.findOne({ user: req.user._id });
    if (!photographer) {
      return res.status(404).json({
        success: false,
        message: 'Photographer profile not found',
      });
    }

    // Upload using videoService with photographer-specific folder
    const videoData = await videoService.uploadVideo(
      req.file.buffer,
      photographer._id.toString(),
      req.file.originalname
    );

    // Add video to portfolio automatically
    photographer.portfolio.video = {
      url: videoData.url,
      publicId: videoData.publicId,
      thumbnail: videoData.thumbnail,
      duration: videoData.duration,
      size: videoData.size,
    };

    await photographer.save();

    logger.info(`Video uploaded and added to portfolio for photographer ${photographer._id}: ${videoData.publicId}`);

    res.status(200).json({
      success: true,
      message: 'Video uploaded and added to portfolio successfully',
      data: videoData,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Add images to portfolio
// @route   POST /api/media/portfolio/:photographerId/images
// @access  Private (photographer owner)
exports.addPortfolioImages = async (req, res, next) => {
  try {
    const { images } = req.body; // Array of {url, publicId}

    const photographer = await Photographer.findById(req.params.photographerId);

    if (!photographer) {
      return res.status(404).json({
        success: false,
        message: 'Photographer not found',
      });
    }

    // Check ownership
    if (photographer.user.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized',
      });
    }

    // Check portfolio limit (max 20 images)
    if (photographer.portfolio.images.length + images.length > 20) {
      return res.status(400).json({
        success: false,
        message: 'Portfolio can have maximum 20 images',
      });
    }

    // Add images
    images.forEach((image) => {
      photographer.portfolio.images.push({
        url: image.url,
        publicId: image.publicId,
      });
    });

    await photographer.save();

    res.status(200).json({
      success: true,
      message: 'Images added to portfolio',
      data: photographer.portfolio.images,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Add video to portfolio
// @route   POST /api/media/portfolio/:photographerId/video
// @access  Private (photographer owner)
exports.addPortfolioVideo = async (req, res, next) => {
  try {
    const { url, publicId, thumbnail, duration, size } = req.body;

    const photographer = await Photographer.findById(req.params.photographerId);

    if (!photographer) {
      return res.status(404).json({
        success: false,
        message: 'Photographer not found',
      });
    }

    // Check ownership
    if (photographer.user.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized',
      });
    }

    // Delete old video from Cloudinary if exists
    if (photographer.portfolio.video?.publicId) {
      await cloudinary.uploader.destroy(photographer.portfolio.video.publicId, {
        resource_type: 'video',
      });
    }

    // Add new video
    photographer.portfolio.video = {
      url,
      publicId,
      thumbnail,
      duration,
      size,
      uploadedAt: new Date(),
    };

    await photographer.save();

    res.status(200).json({
      success: true,
      message: 'Video added to portfolio',
      data: photographer.portfolio.video,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Delete image from portfolio
// @route   DELETE /api/media/portfolio/:photographerId/images/:imageId
// @access  Private (photographer owner)
exports.deletePortfolioImage = async (req, res, next) => {
  try {
    const photographer = await Photographer.findById(req.params.photographerId);

    if (!photographer) {
      return res.status(404).json({
        success: false,
        message: 'Photographer not found',
      });
    }

    // Check ownership
    if (photographer.user.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized',
      });
    }

    // Find image
    const image = photographer.portfolio.images.id(req.params.imageId);
    if (!image) {
      return res.status(404).json({
        success: false,
        message: 'Image not found',
      });
    }

    // Delete from Cloudinary
    await cloudinary.uploader.destroy(image.publicId);

    // Remove from portfolio
    photographer.portfolio.images.pull(req.params.imageId);
    await photographer.save();

    logger.info(`Portfolio image deleted: ${image.publicId}`);

    res.status(200).json({
      success: true,
      message: 'Image deleted from portfolio',
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Delete video from portfolio
// @route   DELETE /api/media/portfolio/:photographerId/video
// @access  Private (photographer owner)
exports.deletePortfolioVideo = async (req, res, next) => {
  try {
    const photographer = await Photographer.findById(req.params.photographerId);

    if (!photographer) {
      return res.status(404).json({
        success: false,
        message: 'Photographer not found',
      });
    }

    // Check ownership
    if (photographer.user.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized',
      });
    }

    if (!photographer.portfolio.video) {
      return res.status(404).json({
        success: false,
        message: 'No video in portfolio',
      });
    }

    // Delete from Cloudinary
    await cloudinary.uploader.destroy(photographer.portfolio.video.publicId, {
      resource_type: 'video',
    });

    // Remove from portfolio
    photographer.portfolio.video = undefined;
    await photographer.save();

    logger.info(`Portfolio video deleted`);

    res.status(200).json({
      success: true,
      message: 'Video deleted from portfolio',
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Delete image from current user's portfolio
// @route   DELETE /api/media/portfolio/images/:imageId
// @access  Private (photographer)
exports.deleteMyPortfolioImage = async (req, res, next) => {
  try {
    // Get photographer profile from current user
    const photographer = await Photographer.findOne({ user: req.user._id });

    if (!photographer) {
      return res.status(404).json({
        success: false,
        message: 'Photographer profile not found',
      });
    }

    // Find image
    const image = photographer.portfolio.images.id(req.params.imageId);
    if (!image) {
      return res.status(404).json({
        success: false,
        message: 'Image not found in portfolio',
      });
    }

    // Delete from Cloudinary
    try {
      await cloudinary.uploader.destroy(image.publicId);
      logger.info(`Image deleted from Cloudinary: ${image.publicId}`);
    } catch (cloudinaryError) {
      logger.error(`Failed to delete from Cloudinary: ${cloudinaryError.message}`);
      // Continue anyway to remove from database
    }

    // Remove from portfolio
    photographer.portfolio.images.pull(req.params.imageId);
    await photographer.save();

    logger.info(`Portfolio image deleted for photographer ${photographer._id}`);

    res.status(200).json({
      success: true,
      message: 'Image deleted from portfolio successfully',
      data: {
        remainingImages: photographer.portfolio.images.length,
      },
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Delete video from current user's portfolio
// @route   DELETE /api/media/portfolio/video
// @access  Private (photographer)
exports.deleteMyPortfolioVideo = async (req, res, next) => {
  try {
    // Get photographer profile from current user
    const photographer = await Photographer.findOne({ user: req.user._id });

    if (!photographer) {
      return res.status(404).json({
        success: false,
        message: 'Photographer profile not found',
      });
    }

    if (!photographer.portfolio.video) {
      return res.status(404).json({
        success: false,
        message: 'No video in portfolio',
      });
    }

    const videoPublicId = photographer.portfolio.video.publicId;

    // Validate publicId before attempting deletion
    if (!videoPublicId || videoPublicId.trim() === '') {
      logger.error('Video publicId is missing or empty');
      // Still remove from database
      photographer.portfolio.video = undefined;
      await photographer.save();
      
      return res.status(200).json({
        success: true,
        message: 'Video removed from portfolio (Cloudinary deletion skipped - no publicId)',
      });
    }

    // Delete from Cloudinary
    try {
      await cloudinary.uploader.destroy(videoPublicId, {
        resource_type: 'video',
      });
      logger.info(`Video deleted from Cloudinary: ${videoPublicId}`);
    } catch (cloudinaryError) {
      logger.error(`Failed to delete video from Cloudinary: ${cloudinaryError.message}`);
      // Continue anyway to remove from database
    }

    // Remove from portfolio
    photographer.portfolio.video = undefined;
    await photographer.save();

    logger.info(`Portfolio video deleted for photographer ${photographer._id}`);

    res.status(200).json({
      success: true,
      message: 'Video deleted from portfolio successfully',
    });
  } catch (error) {
    next(error);
  }
};
