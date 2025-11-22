const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const { protect } = require('../middleware/auth.middleware');

// All routes require authentication
router.use(protect);

// Get all notifications for current user
router.get('/', notificationController.getNotifications);

// Get unread count - must be before /:id route
router.get('/unread-count', notificationController.getUnreadCount);

// Mark all notifications as read - must be before /:id route
router.patch('/read-all', notificationController.markAllAsRead);

// Get notification by ID
router.get('/:id', notificationController.getNotificationById);

// Mark notification as read
router.put('/:id/read', notificationController.markAsRead);

// Delete notification
router.delete('/:id', notificationController.deleteNotification);

// Delete all notifications
router.delete('/', notificationController.deleteAllNotifications);

module.exports = router;
