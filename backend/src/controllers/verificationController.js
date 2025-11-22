const Photographer = require('../models/Photographer');
const emailService = require('../services/emailService');
const logger = require('../utils/logger');

// @desc    Submit verification request
// @route   POST /api/verification/submit
// @access  Private (photographer)
exports.submitVerification = async (req, res, next) => {
  try {
    const { photographerId, documents } = req.body;

    const photographer = await Photographer.findById(photographerId);

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

    // Check if already verified
    if (photographer.verification.status === 'approved') {
      return res.status(400).json({
        success: false,
        message: 'Already verified',
      });
    }

    // Update verification
    photographer.verification = {
      status: 'pending',
      documents: {
        idCard: documents.idCard,
        portfolioSamples: documents.portfolioSamples || [],
      },
      submittedAt: new Date(),
    };

    await photographer.save();

    logger.info(`Verification submitted: ${photographerId}`);

    res.status(200).json({
      success: true,
      message: 'Verification request submitted successfully',
      data: photographer.verification,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get verification status
// @route   GET /api/verification/status
// @access  Private (photographer)
exports.getVerificationStatus = async (req, res, next) => {
  try {
    const photographer = await Photographer.findOne({ user: req.user._id });

    if (!photographer) {
      return res.status(404).json({
        success: false,
        message: 'Photographer profile not found',
      });
    }

    res.status(200).json({
      success: true,
      data: photographer.verification,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get pending verifications (Admin)
// @route   GET /api/verification/pending
// @access  Private (admin)
exports.getPendingVerifications = async (req, res, next) => {
  try {
    const photographers = await Photographer.find({
      'verification.status': 'pending',
    })
      .populate('user', 'name email phone')
      .sort('verification.submittedAt');

    res.status(200).json({
      success: true,
      data: photographers,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Approve verification (Admin)
// @route   PUT /api/verification/:photographerId/approve
// @access  Private (admin)
exports.approveVerification = async (req, res, next) => {
  try {
    const photographer = await Photographer.findById(req.params.photographerId).populate('user');

    if (!photographer) {
      return res.status(404).json({
        success: false,
        message: 'Photographer not found',
      });
    }

    photographer.verification.status = 'approved';
    photographer.verification.reviewedAt = new Date();
    photographer.verification.reviewedBy = req.user._id;

    await photographer.save();

    // Send email notification
    await emailService.sendVerificationApprovalEmail(photographer.user);

    logger.info(`Verification approved: ${req.params.photographerId}`);

    res.status(200).json({
      success: true,
      message: 'Verification approved successfully',
      data: photographer.verification,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Reject verification (Admin)
// @route   PUT /api/verification/:photographerId/reject
// @access  Private (admin)
exports.rejectVerification = async (req, res, next) => {
  try {
    const { reason } = req.body;

    const photographer = await Photographer.findById(req.params.photographerId).populate('user');

    if (!photographer) {
      return res.status(404).json({
        success: false,
        message: 'Photographer not found',
      });
    }

    photographer.verification.status = 'rejected';
    photographer.verification.reviewedAt = new Date();
    photographer.verification.reviewedBy = req.user._id;
    photographer.verification.rejectionReason = reason;

    await photographer.save();

    // Send email notification
    await emailService.sendVerificationRejectionEmail(photographer.user, reason);

    logger.info(`Verification rejected: ${req.params.photographerId}`);

    res.status(200).json({
      success: true,
      message: 'Verification rejected',
      data: photographer.verification,
    });
  } catch (error) {
    next(error);
  }
};
