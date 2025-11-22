const express = require('express');
const router = express.Router();
const verificationController = require('../controllers/verificationController');
const { protect, authorize } = require('../middleware/auth.middleware');

// Photographer routes
router.post('/submit', protect, authorize('photographer'), verificationController.submitVerification);
router.get('/status', protect, authorize('photographer'), verificationController.getVerificationStatus);

// Admin routes
router.get('/pending', protect, authorize('admin'), verificationController.getPendingVerifications);
router.put('/:photographerId/approve', protect, authorize('admin'), verificationController.approveVerification);
router.put('/:photographerId/reject', protect, authorize('admin'), verificationController.rejectVerification);

module.exports = router;
