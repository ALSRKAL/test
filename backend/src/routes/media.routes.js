const express = require('express');
const router = express.Router();
const mediaController = require('../controllers/mediaController');
const { protect, authorize } = require('../middleware/auth.middleware');
const { uploadImage, uploadImages, uploadVideo, handleMulterError } = require('../middleware/upload.middleware');
const { uploadLimiter } = require('../middleware/rateLimit.middleware');

// Upload routes
router.post('/upload/image', protect, uploadLimiter, uploadImage, handleMulterError, mediaController.uploadImage);
router.post('/upload/images', protect, uploadLimiter, uploadImages, handleMulterError, mediaController.uploadImages);
router.post('/upload/video', protect, uploadLimiter, uploadVideo, handleMulterError, mediaController.uploadVideo);

// Portfolio routes
router.post('/portfolio/:photographerId/images', protect, authorize('photographer'), mediaController.addPortfolioImages);
router.post('/portfolio/:photographerId/video', protect, authorize('photographer'), mediaController.addPortfolioVideo);
router.delete('/portfolio/:photographerId/images/:imageId', protect, authorize('photographer'), mediaController.deletePortfolioImage);
router.delete('/portfolio/:photographerId/video', protect, authorize('photographer'), mediaController.deletePortfolioVideo);

// Simplified portfolio routes (uses current user's photographer profile)
router.delete('/portfolio/images/:imageId', protect, authorize('photographer'), mediaController.deleteMyPortfolioImage);
router.delete('/portfolio/video', protect, authorize('photographer'), mediaController.deleteMyPortfolioVideo);

module.exports = router;
