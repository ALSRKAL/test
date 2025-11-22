const express = require('express');
const router = express.Router();
const photographerController = require('../controllers/photographerController');
const { protect, authorize } = require('../middleware/auth.middleware');

// Public routes
router.get('/', photographerController.getPhotographers);
router.get('/search', photographerController.searchPhotographers);
router.get('/featured', photographerController.getFeaturedPhotographers);

// Get current user's photographer profile (MUST be before /:id route)
router.get('/me/profile', protect, photographerController.getMyPhotographerProfile);

// Update availability (blocked dates)
router.put('/me/availability', protect, authorize('photographer'), photographerController.updateAvailability);

// Update profile
router.put('/me/profile', protect, authorize('photographer'), photographerController.updateMyPhotographerProfile);

// Favorites routes (MUST be before /:id route)
router.get('/favorites', protect, photographerController.getFavorites);

// Get photographer by ID (MUST be after specific routes like /me/profile)
router.get('/:id', photographerController.getPhotographerById);

// Protected routes
router.post('/', protect, authorize('photographer'), photographerController.createPhotographerProfile);
router.put('/:id', protect, authorize('photographer'), photographerController.updatePhotographerProfile);

// Package routes
router.post('/:id/packages', protect, authorize('photographer'), photographerController.addPackage);
router.put('/:id/packages/:packageId', protect, authorize('photographer'), photographerController.updatePackage);
router.delete('/:id/packages/:packageId', protect, authorize('photographer'), photographerController.deletePackage);

// Favorites routes
router.post('/:id/favorite', protect, photographerController.addToFavorites);
router.delete('/:id/favorite', protect, photographerController.removeFromFavorites);

module.exports = router;
