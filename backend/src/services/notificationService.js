const axios = require('axios');
const logger = require('../utils/logger');

class NotificationService {
  constructor() {
    this.appId = process.env.ONESIGNAL_APP_ID || 'db0f9546-9d0c-411d-a59a-e331483b0d98';
    this.restApiKey = process.env.ONESIGNAL_REST_API_KEY || 'os_v2_app_3mhzkru5brar3jm24myuqoyntaw3t2mypk2uxxmoxk3suf345nq3ditj5reeo5gjyicog6inzvntxkx53g4cxy7vuy2i3do72kt3hni';
    this.apiUrl = 'https://onesignal.com/api/v1/notifications';
    this.isConfigured = !!(this.appId && this.restApiKey);

    if (this.isConfigured) {
      logger.info('OneSignal notification service initialized');
    } else {
      logger.warn('OneSignal not configured properly');
    }
  }

  /**
   * Send notification to user
   * @param {String} userId - User ID
   * @param {Object} notification - Notification data
   */
  async sendToUser(userId, notification) {
    try {
      if (!this.isConfigured) {
        logger.warn('OneSignal not configured, skipping notification');
        return;
      }

      const payload = {
        app_id: this.appId,
        include_external_user_ids: [userId],
        headings: { en: notification.title, ar: notification.title },
        contents: { en: notification.body, ar: notification.body },
        data: notification.data || {},
      };

      const response = await axios.post(this.apiUrl, payload, {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Basic ${this.restApiKey}`,
        },
      });

      logger.info(`Notification sent to user ${userId}: ${notification.title}`);
      return response.data;
    } catch (error) {
      logger.error(`Failed to send notification: ${error.message}`);
      throw error;
    }
  }

  /**
   * Send notification to multiple users
   * @param {Array} userIds - Array of user IDs
   * @param {Object} notification - Notification data
   */
  async sendToMultipleUsers(userIds, notification) {
    try {
      if (!this.isConfigured) {
        logger.warn('OneSignal not configured, skipping notification');
        return;
      }

      const payload = {
        app_id: this.appId,
        include_external_user_ids: userIds,
        headings: { en: notification.title, ar: notification.title },
        contents: { en: notification.body, ar: notification.body },
        data: notification.data || {},
      };

      const response = await axios.post(this.apiUrl, payload, {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Basic ${this.restApiKey}`,
        },
      });

      logger.info(`Notification sent to ${userIds.length} users: ${notification.title}`);
      return response.data;
    } catch (error) {
      logger.error(`Failed to send bulk notification: ${error.message}`);
      throw error;
    }
  }

  /**
   * Send new booking notification to photographer
   */
  async sendNewBookingNotification(photographerUserId, bookingData) {
    try {
      if (!this.isConfigured) {
        logger.warn('OneSignal not configured, skipping notification');
        return;
      }

      const { id, clientName, clientAvatar, date, time, packageName, location, price } = bookingData;

      const payload = {
        app_id: this.appId,
        include_external_user_ids: [photographerUserId],

        headings: {
          en: '🎉 حجز جديد!',
          ar: '🎉 حجز جديد!'
        },
        contents: {
          en: `لديك حجز جديد من ${clientName}`,
          ar: `لديك حجز جديد من ${clientName}`
        },

        data: {
          type: 'new_booking',
          bookingId: id,
          clientName: clientName,
          clientAvatar: clientAvatar || '',
          date: date,
          time: time,
          packageName: packageName,
          location: location,
          price: price,
          screen: 'bookings',
        },

        small_icon: 'ic_stat_onesignal_default',
        large_icon: clientAvatar || undefined,

        ios_badgeType: 'Increase',
        ios_badgeCount: 1,

        priority: 10,
        android_accent_color: 'FF9C27B0',
      };

      const response = await axios.post(this.apiUrl, payload, {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Basic ${this.restApiKey}`,
        },
      });

      logger.info(`📅 New booking notification sent to photographer ${photographerUserId}`);
      return response.data;
    } catch (error) {
      logger.error(`Failed to send new booking notification: ${error.message}`);
      throw error;
    }
  }

  /**
   * Send booking status update notification to client
   */
  async sendBookingStatusNotification(clientUserId, bookingData) {
    try {
      if (!this.isConfigured) {
        logger.warn('OneSignal not configured, skipping notification');
        return;
      }

      const { id, status, oldStatus, date, timeSlot, photographerName, photographerAvatar, packageName, location } = bookingData;

      // Define status messages and icons
      const statusInfo = {
        confirmed: {
          title: '✅ تم تأكيد الحجز',
          body: `تم تأكيد حجزك مع ${photographerName}`,
          emoji: '✅',
          color: 'FF4CAF50',
        },
        completed: {
          title: '✨ تم إكمال الحجز',
          body: `تم إكمال حجزك مع ${photographerName}. نتمنى أن تكون راضياً عن الخدمة!`,
          emoji: '✨',
          color: 'FF9C27B0',
        },
        cancelled: {
          title: '❌ تم إلغاء الحجز',
          body: `تم إلغاء حجزك مع ${photographerName}`,
          emoji: '❌',
          color: 'FFF44336',
        },
        pending: {
          title: '⏳ حجز قيد الانتظار',
          body: `حجزك مع ${photographerName} قيد المراجعة`,
          emoji: '⏳',
          color: 'FFFF9800',
        },
      };

      const info = statusInfo[status] || {
        title: 'تحديث الحجز',
        body: `تم تحديث حالة حجزك مع ${photographerName}`,
        emoji: '📅',
        color: 'FF2196F3',
      };

      const payload = {
        app_id: this.appId,
        include_external_user_ids: [clientUserId],

        headings: {
          en: info.title,
          ar: info.title
        },
        contents: {
          en: info.body,
          ar: info.body
        },

        data: {
          type: 'booking_status',
          bookingId: id,
          status: status,
          oldStatus: oldStatus,
          photographerName: photographerName,
          photographerAvatar: photographerAvatar || '',
          date: date,
          timeSlot: timeSlot,
          packageName: packageName,
          location: location,
          screen: 'bookings',
        },

        small_icon: 'ic_stat_onesignal_default',
        large_icon: photographerAvatar || undefined,

        ios_badgeType: 'Increase',
        ios_badgeCount: 1,

        priority: 10,
        android_accent_color: info.color,
      };

      const response = await axios.post(this.apiUrl, payload, {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Basic ${this.restApiKey}`,
        },
      });

      logger.info(`📅 Booking status notification sent to client ${clientUserId}: ${oldStatus} → ${status}`);
      return response.data;
    } catch (error) {
      logger.error(`Failed to send booking status notification: ${error.message}`);
      throw error;
    }
  }

  /**
   * Send booking cancellation notification
   */
  async sendBookingCancellationNotification(userId, cancellationData) {
    try {
      if (!this.isConfigured) {
        logger.warn('OneSignal not configured, skipping notification');
        return;
      }

      const { id, cancelledBy, clientName, photographerName, date, timeSlot, packageName, reason } = cancellationData;

      let title, body, cancellerName;

      if (cancelledBy === 'client') {
        // Notification to photographer
        cancellerName = clientName;
        title = '❌ تم إلغاء الحجز';
        body = `قام ${clientName} بإلغاء الحجز`;
      } else if (cancelledBy === 'photographer') {
        // Notification to client
        cancellerName = photographerName;
        title = '❌ تم إلغاء الحجز';
        body = `قام ${photographerName} بإلغاء الحجز`;
      } else {
        // Admin cancelled
        title = '❌ تم إلغاء الحجز';
        body = 'تم إلغاء الحجز من قبل الإدارة';
      }

      const payload = {
        app_id: this.appId,
        include_external_user_ids: [userId],

        headings: {
          en: title,
          ar: title
        },
        contents: {
          en: body,
          ar: body
        },

        data: {
          type: 'booking_cancelled',
          bookingId: id,
          cancelledBy: cancelledBy,
          cancellerName: cancellerName,
          date: date,
          timeSlot: timeSlot,
          packageName: packageName,
          reason: reason,
          screen: 'bookings',
        },

        small_icon: 'ic_stat_onesignal_default',

        ios_badgeType: 'Increase',
        ios_badgeCount: 1,

        priority: 10,
        android_accent_color: 'FFF44336',
      };

      const response = await axios.post(this.apiUrl, payload, {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Basic ${this.restApiKey}`,
        },
      });

      logger.info(`📅 Booking cancellation notification sent to user ${userId}`);
      return response.data;
    } catch (error) {
      logger.error(`Failed to send booking cancellation notification: ${error.message}`);
      throw error;
    }
  }

  /**
   * Send new message notification
   */
  async sendNewMessageNotification(receiverUserId, senderData, messageData) {
    try {
      if (!this.isConfigured) {
        logger.warn('OneSignal not configured, skipping notification');
        return;
      }

      const { name: senderName, avatar: senderAvatar, _id: senderId } = senderData;
      const { content, conversationId, type = 'text' } = messageData;

      // Format message preview based on type
      let messagePreview = content;
      if (type === 'image') {
        messagePreview = '📷 صورة';
      } else if (type === 'video') {
        messagePreview = '🎥 فيديو';
      } else if (type === 'audio') {
        messagePreview = '🎵 رسالة صوتية';
      } else if (type === 'file') {
        messagePreview = '📎 ملف';
      }

      // Truncate long messages
      if (messagePreview.length > 100) {
        messagePreview = messagePreview.substring(0, 97) + '...';
      }

      const payload = {
        app_id: this.appId,
        include_external_user_ids: [receiverUserId],

        // Notification content
        headings: {
          en: senderName,
          ar: senderName
        },
        contents: {
          en: messagePreview,
          ar: messagePreview
        },

        // Custom data for app navigation
        data: {
          type: 'chat_message',
          conversationId: conversationId,
          senderId: senderId.toString(),
          senderName: senderName,
          senderAvatar: senderAvatar || '',
          messageType: type,
          screen: 'chat',
        },

        // Android specific settings (don't specify channel_id, let OneSignal use default)
        small_icon: 'ic_stat_onesignal_default',
        large_icon: senderAvatar || undefined,

        // iOS specific settings
        ios_badgeType: 'Increase',
        ios_badgeCount: 1,

        // Priority settings
        priority: 10,
        android_accent_color: 'FF9C27B0',
      };

      const response = await axios.post(this.apiUrl, payload, {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Basic ${this.restApiKey}`,
        },
      });

      logger.info(`💬 Message notification sent to user ${receiverUserId} from ${senderName}`);
      return response.data;
    } catch (error) {
      logger.error(`Failed to send message notification: ${error.message}`);
      // Don't throw error to prevent message sending from failing
    }
  }

  /**
   * Send new review notification to photographer
   */
  async sendNewReviewNotification(photographerUserId, reviewData) {
    try {
      if (!this.isConfigured) {
        logger.warn('OneSignal not configured, skipping notification');
        return;
      }

      const { id, rating, comment, clientName, clientAvatar, packageName, date } = reviewData;

      // Generate star emojis
      const stars = '⭐'.repeat(rating);

      // Rating messages based on score
      const ratingMessages = {
        5: 'ممتاز! 🌟',
        4: 'جيد جداً! 👍',
        3: 'جيد',
        2: 'يحتاج تحسين',
        1: 'ضعيف',
      };

      const ratingMessage = ratingMessages[rating] || '';

      const payload = {
        app_id: this.appId,
        include_external_user_ids: [photographerUserId],

        headings: {
          en: `${stars} تقييم جديد ${ratingMessage}`,
          ar: `${stars} تقييم جديد ${ratingMessage}`
        },
        contents: {
          en: `${clientName} قيّمك بـ ${rating} نجوم`,
          ar: `${clientName} قيّمك بـ ${rating} نجوم`
        },

        data: {
          type: 'new_review',
          reviewId: id,
          rating: rating,
          comment: comment,
          clientName: clientName,
          clientAvatar: clientAvatar || '',
          packageName: packageName,
          date: date,
          screen: 'reviews',
        },

        small_icon: 'ic_stat_onesignal_default',
        large_icon: clientAvatar || undefined,

        ios_badgeType: 'Increase',
        ios_badgeCount: 1,

        priority: 10,
        android_accent_color: rating >= 4 ? 'FFFFC107' : 'FFFF9800', // Gold for 4-5 stars, Orange for 1-3
      };

      const response = await axios.post(this.apiUrl, payload, {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Basic ${this.restApiKey}`,
        },
      });

      logger.info(`⭐ New review notification sent to photographer ${photographerUserId}: ${rating}/5 stars`);
      return response.data;
    } catch (error) {
      logger.error(`Failed to send new review notification: ${error.message}`);
      throw error;
    }
  }

  /**
   * Send new favorite notification to photographer
   */
  async sendNewFavoriteNotification(photographerUserId, favoriteData) {
    try {
      if (!this.isConfigured) {
        logger.warn('OneSignal not configured, skipping notification');
        return;
      }

      const { clientName, clientAvatar, photographerName } = favoriteData;

      const payload = {
        app_id: this.appId,
        include_external_user_ids: [photographerUserId],

        headings: {
          en: '❤️ إعجاب جديد!',
          ar: '❤️ إعجاب جديد!'
        },
        contents: {
          en: `أعجب ${clientName} بملفك الشخصي`,
          ar: `أعجب ${clientName} بملفك الشخصي`
        },

        data: {
          type: 'new_favorite',
          clientName: clientName,
          clientAvatar: clientAvatar || '',
          photographerName: photographerName,
          screen: 'profile',
        },

        small_icon: 'ic_stat_onesignal_default',
        large_icon: clientAvatar || undefined,

        ios_badgeType: 'Increase',
        ios_badgeCount: 1,

        priority: 5, // Lower priority than bookings/reviews
        android_accent_color: 'FFE91E63', // Pink color for likes
      };

      const response = await axios.post(this.apiUrl, payload, {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Basic ${this.restApiKey}`,
        },
      });

      logger.info(`❤️ New favorite notification sent to photographer ${photographerUserId} from ${clientName}`);
      return response.data;
    } catch (error) {
      logger.error(`Failed to send new favorite notification: ${error.message}`);
      throw error;
    }
  }

  /**
   * Send booking reminder notification
   */
  async sendBookingReminderNotification(userId, bookingData, hoursUntil) {
    await this.sendToUser(userId, {
      title: 'تذكير بالحجز',
      body: `لديك حجز بعد ${hoursUntil} ساعة`,
      data: {
        type: 'booking_reminder',
        bookingId: bookingData.id,
      },
    });
  }
  /**
   * Send verification approved notification
   */
  async sendVerificationApprovedNotification(userId) {
    await this.sendToUser(userId, {
      title: '✅ تم توثيق حسابك',
      body: 'تهانينا! تم قبول طلب توثيق حسابك بنجاح.',
      data: {
        type: 'verification_approved',
        screen: 'profile',
      },
    });
  }

  /**
   * Send verification rejected notification
   */
  async sendVerificationRejectedNotification(userId, reason) {
    await this.sendToUser(userId, {
      title: '❌ تم رفض طلب التوثيق',
      body: `عذراً، تم رفض طلب توثيق حسابك. السبب: ${reason}`,
      data: {
        type: 'verification_rejected',
        screen: 'profile',
      },
    });
  }

  /**
   * Send account blocked notification
   */
  async sendAccountBlockedNotification(userId, reason) {
    await this.sendToUser(userId, {
      title: '⛔ تم حظر حسابك',
      body: `تم حظر حسابك من قبل الإدارة. السبب: ${reason}`,
      data: {
        type: 'account_blocked',
        reason: reason,
      },
    });
  }
}

module.exports = new NotificationService();
