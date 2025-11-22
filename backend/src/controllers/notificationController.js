const Notification = require('../models/Notification');
const logger = require('../utils/logger');

// @desc    Get all notifications for current user
// @route   GET /api/notifications
// @access  Private
exports.getNotifications = async (req, res, next) => {
  try {
    const { page = 1, limit = 20, unreadOnly = false } = req.query;
    const skip = (page - 1) * limit;

    const query = { recipient: req.user.id };
    if (unreadOnly === 'true') {
      query.read = false;
    }

    const notifications = await Notification.find(query)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit))
      .populate('sender', 'name avatar')
      .lean();

    const total = await Notification.countDocuments(query);

    res.status(200).json({
      success: true,
      data: notifications,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    logger.error('Get notifications error:', error);
    next(error);
  }
};

// @desc    Get unread notifications count
// @route   GET /api/notifications/unread-count
// @access  Private
exports.getUnreadCount = async (req, res, next) => {
  try {
    const count = await Notification.countDocuments({
      recipient: req.user.id,
      read: false,
    });

    res.status(200).json({
      success: true,
      data: { count },
    });
  } catch (error) {
    logger.error('Get unread count error:', error);
    next(error);
  }
};

// @desc    Get notification by ID
// @route   GET /api/notifications/:id
// @access  Private
exports.getNotificationById = async (req, res, next) => {
  try {
    const notification = await Notification.findOne({
      _id: req.params.id,
      recipient: req.user.id,
    }).populate('sender', 'name avatar');

    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found',
      });
    }

    res.status(200).json({
      success: true,
      data: notification,
    });
  } catch (error) {
    logger.error('Get notification by ID error:', error);
    next(error);
  }
};

// @desc    Mark notification as read
// @route   PUT /api/notifications/:id/read
// @access  Private
exports.markAsRead = async (req, res, next) => {
  try {
    const notification = await Notification.findOneAndUpdate(
      {
        _id: req.params.id,
        recipient: req.user.id,
      },
      { read: true },
      { new: true }
    );

    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found',
      });
    }

    res.status(200).json({
      success: true,
      data: notification,
    });

    // Emit update event
    const notificationEmitter = require('../utils/notificationEmitter');
    const io = notificationEmitter.getIo();
    io.to(`user_${req.user.id}`).emit('notification_updated', notification);
    io.to(`user_${req.user.id}`).emit('notification_count_update', {
      increment: false,
      count: await Notification.countDocuments({ recipient: req.user.id, read: false })
    });
  } catch (error) {
    logger.error('Mark notification as read error:', error);
    next(error);
  }
};

// @desc    Mark all notifications as read
// @route   PUT /api/notifications/mark-all-read
// @access  Private
exports.markAllAsRead = async (req, res, next) => {
  try {
    await Notification.updateMany(
      {
        recipient: req.user.id,
        read: false,
      },
      { read: true }
    );

    res.status(200).json({
      success: true,
      message: 'All notifications marked as read',
    });

    // Emit update event
    const notificationEmitter = require('../utils/notificationEmitter');
    const io = notificationEmitter.getIo();
    io.to(`user_${req.user.id}`).emit('notifications_marked_all_read');
    io.to(`user_${req.user.id}`).emit('notification_count_update', {
      increment: false,
      count: 0
    });
  } catch (error) {
    logger.error('Mark all notifications as read error:', error);
    next(error);
  }
};

// @desc    Delete notification
// @route   DELETE /api/notifications/:id
// @access  Private
exports.deleteNotification = async (req, res, next) => {
  try {
    const notification = await Notification.findOneAndDelete({
      _id: req.params.id,
      recipient: req.user.id,
    });

    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found',
      });
    }

    res.status(200).json({
      success: true,
      message: 'Notification deleted successfully',
    });

    // Emit update event
    const notificationEmitter = require('../utils/notificationEmitter');
    const io = notificationEmitter.getIo();
    io.to(`user_${req.user.id}`).emit('notification_deleted', { id: req.params.id });
    io.to(`user_${req.user.id}`).emit('notification_count_update', {
      increment: false,
      count: await Notification.countDocuments({ recipient: req.user.id, read: false })
    });
  } catch (error) {
    logger.error('Delete notification error:', error);
    next(error);
  }
};

// @desc    Delete all notifications
// @route   DELETE /api/notifications
// @access  Private
exports.deleteAllNotifications = async (req, res, next) => {
  try {
    await Notification.deleteMany({ recipient: req.user.id });

    res.status(200).json({
      success: true,
      message: 'All notifications deleted successfully',
    });
  } catch (error) {
    logger.error('Delete all notifications error:', error);
    next(error);
  }
};
