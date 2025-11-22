const express = require('express');
const router = express.Router();
const reviewController = require('../controllers/reviewController');
const { protect } = require('../middleware/auth.middleware');
const { validate, schemas } = require('../middleware/validation.middleware');

// Protected routes - must come before public routes with params
router.get('/', protect, reviewController.getMyPhotographerReviews);
router.post('/', protect, validate(schemas.createReview), reviewController.createReview);
router.put('/:id', protect, reviewController.updateReview);
router.delete('/:id', protect, reviewController.deleteReview);
router.post('/:id/reply', protect, reviewController.replyToReview);
router.post('/:id/report', protect, reviewController.reportReview);

// Public routes - must come after specific routes
router.get('/photographer/:photographerId', reviewController.getPhotographerReviews);
router.get('/:id', reviewController.getReviewById);

module.exports = router;
