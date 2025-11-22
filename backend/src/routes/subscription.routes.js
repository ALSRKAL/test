const express = require('express');
const router = express.Router();
const subscriptionController = require('../controllers/subscriptionController');
const { protect, authorize } = require('../middleware/auth.middleware');

// Public routes
router.get('/plans', subscriptionController.getPlans);

// Photographer routes
router.get('/my-subscription', protect, authorize('photographer'), subscriptionController.getMySubscription);
router.post('/subscribe', protect, authorize('photographer'), subscriptionController.subscribe);
router.post('/cancel', protect, authorize('photographer'), subscriptionController.cancelSubscription);
router.post('/featured', protect, authorize('photographer'), subscriptionController.requestFeatured);

module.exports = router;
