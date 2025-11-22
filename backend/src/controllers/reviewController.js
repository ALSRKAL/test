const Review = require('../models/Review');
const Booking = require('../models/Booking');
const Photographer = require('../models/Photographer');
const logger = require('../utils/logger');

// @desc    Create review
// @route   POST /api/reviews
// @access  Private (client)
exports.createReview = async (req, res, next) => {
  try {
    const { photographer, booking, rating, comment } = req.body;

    // Check if booking exists and is completed
    const bookingDoc = await Booking.findById(booking);
    if (!bookingDoc) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found',
      });
    }

    if (bookingDoc.status !== 'completed') {
      return res.status(400).json({
        success: false,
        message: 'Can only review completed bookings',
      });
    }

    // Check if client is the booking owner
    if (bookingDoc.client.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized',
      });
    }

    // Check if review already exists
    const existingReview = await Review.findOne({
      client: req.user._id,
      booking,
    });

    if (existingReview) {
      return res.status(400).json({
        success: false,
        message: 'You have already reviewed this booking',
      });
    }

    // Create review
    const review = await Review.create({
      client: req.user._id,
      photographer,
      booking,
      rating,
      comment,
    });

    // Populate review with client and booking details
    await review.populate('client', 'name avatar');
    await review.populate('booking', 'package.name date');

    logger.info(`New review created: ${review._id} - Rating: ${rating}/5`);

    // Send notification to photographer
    const notificationService = require('../services/notificationService');
    const photographerDoc = await Photographer.findById(photographer).populate('user', 'name');

    if (photographerDoc) {
      try {
        logger.info(`🔍 Sending new review notification to photographer ${photographerDoc.user._id}`);

        await notificationService.sendNewReviewNotification(
          photographerDoc.user._id.toString(),
          {
            id: review._id.toString(),
            rating: rating,
            comment: comment,
            clientName: req.user.name,
            clientAvatar: req.user.avatar,
            packageName: bookingDoc.package.name,
            date: bookingDoc.date.toLocaleDateString('ar-EG', {
              year: 'numeric',
              month: 'long',
              day: 'numeric'
            }),
          }
        );

        logger.info(`✅ New review notification sent successfully`);
      } catch (notifError) {
        logger.error(`❌ Failed to send review notification: ${notifError.message}`);
        logger.error(`Error stack: ${notifError.stack}`);
      }
    }

    res.status(201).json({
      success: true,
      message: 'Review created successfully',
      data: review,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get reviews for photographer
// @route   GET /api/reviews/photographer/:photographerId
// @access  Public
exports.getPhotographerReviews = async (req, res, next) => {
  try {
    const { photographerId } = req.params;
    const { page = 1, limit = 10, rating } = req.query;

    const query = { photographer: photographerId };
    if (rating) query.rating = parseInt(rating);

    const reviews = await Review.find(query)
      .populate('client', 'name avatar')
      .populate('booking', 'package.name date')
      .sort('-createdAt')
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const count = await Review.countDocuments(query);

    res.status(200).json({
      success: true,
      data: reviews,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: count,
        pages: Math.ceil(count / limit),
      },
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get reviews for current photographer
// @route   GET /api/reviews
// @access  Private (photographer)
exports.getMyPhotographerReviews = async (req, res, next) => {
  try {
    const { page = 1, limit = 100, rating } = req.query;

    // Check if user is photographer
    if (req.user.role !== 'photographer') {
      return res.status(403).json({
        success: false,
        message: 'Only photographers can access this endpoint',
      });
    }

    // Find photographer profile
    const photographer = await Photographer.findOne({ user: req.user._id });
    if (!photographer) {
      return res.status(404).json({
        success: false,
        message: 'Photographer profile not found',
      });
    }

    const query = { photographer: photographer._id };
    if (rating) query.rating = parseInt(rating);

    const reviews = await Review.find(query)
      .populate('client', 'name avatar')
      .populate('booking', 'package.name date')
      .sort('-createdAt')
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const count = await Review.countDocuments(query);

    logger.info(`Photographer ${req.user._id} retrieved ${reviews.length} reviews`);

    res.status(200).json({
      success: true,
      data: reviews,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: count,
        pages: Math.ceil(count / limit),
      },
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get review by ID
// @route   GET /api/reviews/:id
// @access  Public
exports.getReviewById = async (req, res, next) => {
  try {
    const review = await Review.findById(req.params.id)
      .populate('client', 'name avatar')
      .populate('photographer')
      .populate('booking', 'package.name date');

    if (!review) {
      return res.status(404).json({
        success: false,
        message: 'Review not found',
      });
    }

    res.status(200).json({
      success: true,
      data: review,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update review
// @route   PUT /api/reviews/:id
// @access  Private (review owner)
exports.updateReview = async (req, res, next) => {
  try {
    const { rating, comment } = req.body;

    let review = await Review.findById(req.params.id);

    if (!review) {
      return res.status(404).json({
        success: false,
        message: 'Review not found',
      });
    }

    // Check ownership
    if (review.client.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized',
      });
    }

    review.rating = rating || review.rating;
    review.comment = comment || review.comment;

    await review.save();

    res.status(200).json({
      success: true,
      message: 'Review updated successfully',
      data: review,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Delete review
// @route   DELETE /api/reviews/:id
// @access  Private (review owner or admin)
exports.deleteReview = async (req, res, next) => {
  try {
    const review = await Review.findById(req.params.id);

    if (!review) {
      return res.status(404).json({
        success: false,
        message: 'Review not found',
      });
    }

    // Check authorization
    if (
      review.client.toString() !== req.user._id.toString() &&
      req.user.role !== 'admin' && req.user.role !== 'superadmin'
    ) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized',
      });
    }

    await review.deleteOne();

    logger.info(`Review deleted: ${req.params.id}`);

    res.status(200).json({
      success: true,
      message: 'Review deleted successfully',
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Reply to review
// @route   POST /api/reviews/:id/reply
// @access  Private (photographer owner)
exports.replyToReview = async (req, res, next) => {
  try {
    const { text } = req.body;

    const review = await Review.findById(req.params.id);

    if (!review) {
      return res.status(404).json({
        success: false,
        message: 'Review not found',
      });
    }

    // Check if user is the photographer
    const photographer = await Photographer.findById(review.photographer);
    if (photographer.user.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized',
      });
    }

    review.reply = {
      text,
      repliedAt: new Date(),
    };

    await review.save();

    res.status(200).json({
      success: true,
      message: 'Reply added successfully',
      data: review,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Report review
// @route   POST /api/reviews/:id/report
// @access  Private
exports.reportReview = async (req, res, next) => {
  try {
    const { reason } = req.body;

    const review = await Review.findById(req.params.id);

    if (!review) {
      return res.status(404).json({
        success: false,
        message: 'Review not found',
      });
    }

    review.isReported = true;
    review.reportReason = reason;

    await review.save();

    logger.info(`Review reported: ${req.params.id}`);

    res.status(200).json({
      success: true,
      message: 'Review reported successfully',
    });
  } catch (error) {
    next(error);
  }
};
