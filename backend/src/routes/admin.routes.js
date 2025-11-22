
const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const { adminOnly, superAdminOnly } = require('../middleware/auth.middleware');
const {
  getAdmins,
  createAdmin,
  updateAdmin,
  deleteAdmin,
  getMe
} = require('../controllers/adminUser.controller');
const {
  createUser,
  updateUser
} = require('../controllers/user.controller');

// Public routes
router.post('/login', adminController.login);

// Protected admin routes
// router.use(protect); // adminOnly already checks for token and user
router.use(adminOnly);

router.get('/me', getMe);

// Admin User Management (Super Admin Only)
router.get('/admins', superAdminOnly, getAdmins);
router.post('/admins', superAdminOnly, createAdmin);
router.put('/admins/:id', superAdminOnly, updateAdmin);
router.delete('/admins/:id', superAdminOnly, deleteAdmin);

// Dashboard
router.get('/dashboard', adminController.getDashboard);

// Users management
router.get('/users', adminController.getUsers);
router.post('/users', superAdminOnly, createUser);
router.put('/users/:id', superAdminOnly, updateUser);
router.patch('/users/:userId/block', adminController.toggleUserBlock);
router.delete('/users/:userId', adminController.deleteUser);

// Photographers management
router.get('/photographers', adminController.getAllPhotographers);
router.get('/photographers/pending', adminController.getPendingVerifications);
router.patch('/photographers/:photographerId/approve', adminController.approvePhotographer);
router.patch('/photographers/:photographerId/reject', adminController.rejectPhotographer);
router.patch('/photographers/:photographerId/revoke', adminController.revokePhotographerVerification);

// Bookings management
router.get('/bookings', adminController.getBookings);

// Revenue
router.get('/revenue', adminController.getRevenueReport);

// Content moderation
router.get('/reviews', adminController.getReviews);
router.delete('/reviews/:reviewId', adminController.deleteReview);

// Notifications
router.post('/notifications/broadcast', adminController.broadcastNotification);

// Subscriptions
router.get('/subscriptions/stats', adminController.getSubscriptionStats);

// Analytics
router.get('/analytics', adminController.getAnalytics);

// Reports
router.get('/reports', adminController.getReports);
router.patch('/reports/:reportId/resolve', adminController.resolveReport);

module.exports = router;

// End of routes
