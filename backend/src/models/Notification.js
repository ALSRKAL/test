const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema(
  {
    recipient: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    sender: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
    type: {
      type: String,
      required: true,
      enum: [
        'booking_request',
        'booking_confirmed',
        'booking_cancelled',
        'booking_completed',
        'new_review',
        'new_message',
        'photographer_verified',
        'favorite_added',
        'system',
      ],
    },
    title: {
      type: String,
      required: true,
    },
    message: {
      type: String,
      required: true,
    },
    data: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },
    read: {
      type: Boolean,
      default: false,
      index: true,
    },
    readAt: {
      type: Date,
    },
  },
  {
    timestamps: true,
  }
);

// Index for efficient queries
notificationSchema.index({ recipient: 1, read: 1, createdAt: -1 });

// Mark notification as read
notificationSchema.methods.markAsRead = function () {
  this.read = true;
  this.readAt = new Date();
  return this.save();
};

// Emit notification after save
notificationSchema.post('save', function (doc) {
  const notificationEmitter = require('../utils/notificationEmitter');
  notificationEmitter.emitNotification(doc.recipient.toString(), doc);
});

module.exports = mongoose.model('Notification', notificationSchema);
