const Booking = require('../models/Booking');
const Photographer = require('../models/Photographer');
const logger = require('../utils/logger');

// @desc    Create new booking
// @route   POST /api/bookings
// @access  Private (client)
exports.createBooking = async (req, res, next) => {
  try {
    const { photographer, package: pkg, date, timeSlot, location, notes } = req.body;

    // Check if photographer exists
    const photographerDoc = await Photographer.findById(photographer).populate('user', 'name email');
    if (!photographerDoc) {
      return res.status(404).json({
        success: false,
        message: 'Photographer not found',
      });
    }

    // Check if date is available
    const bookingDate = new Date(date);
    const isDateBlocked = photographerDoc.availability.blockedDates.some(
      (blockedDate) =>
        blockedDate.toDateString() === bookingDate.toDateString()
    );

    if (isDateBlocked) {
      return res.status(400).json({
        success: false,
        message: 'This date is not available',
      });
    }

    // Check for existing booking on same date and time
    const existingBooking = await Booking.findOne({
      photographer,
      date: bookingDate,
      timeSlot,
      status: { $in: ['pending', 'confirmed'] },
    });

    if (existingBooking) {
      return res.status(400).json({
        success: false,
        message: 'This time slot is already booked',
      });
    }

    // Create booking
    const booking = await Booking.create({
      client: req.user._id,
      photographer,
      package: pkg || null,
      date: bookingDate,
      timeSlot,
      location,
      notes,
      payment: {
        amount: pkg ? pkg.price : 0,
      },
    });

    // Populate booking with client details
    await booking.populate('client', 'name email phone avatar');

    logger.info(`New booking created: ${booking._id}`);

    // Send realtime notification to photographer via Socket.IO
    const io = req.app.get('io');
    if (io) {
      const photographerUserId = photographerDoc.user._id.toString();

      logger.info(`📤 Sending Socket.IO events to photographer ${photographerUserId}`);
      logger.info(`   Room: user_${photographerUserId}`);

      // Emit to photographer's user room
      const newBookingData = {
        bookingId: booking._id,
        clientName: req.user.name,
        clientAvatar: req.user.avatar,
        date: bookingDate.toISOString(),
        timeSlot,
        packageName: pkg ? pkg.name : 'بدون باقة',
        location,
        price: pkg ? pkg.price : 0,
        status: 'pending',
        createdAt: booking.createdAt,
      };

      logger.info(`   Event: new_booking`);
      logger.info(`   Data: ${JSON.stringify(newBookingData)}`);
      io.to(`user_${photographerUserId}`).emit('new_booking', newBookingData);

      // Also emit pending bookings count update
      const pendingCount = await Booking.countDocuments({
        photographer: photographer,
        status: 'pending',
      });

      logger.info(`   Event: pending_bookings_update`);
      logger.info(`   Count: ${pendingCount}`);
      io.to(`user_${photographerUserId}`).emit('pending_bookings_update', {
        count: pendingCount,
      });

      logger.info(`✅ Realtime booking notifications sent to photographer ${photographerUserId}`);
    } else {
      logger.warn(`⚠️ Socket.IO not available`);
    }

    // Send push notification via OneSignal
    const notificationService = require('../services/notificationService');
    try {
      logger.info(`🔍 Sending new booking notification to photographer ${photographerDoc.user._id}`);
      await notificationService.sendNewBookingNotification(
        photographerDoc.user._id.toString(),
        {
          id: booking._id.toString(),
          date: bookingDate.toLocaleDateString('ar-EG', {
            weekday: 'long',
            year: 'numeric',
            month: 'long',
            day: 'numeric'
          }),
          time: timeSlot,
          clientName: req.user.name,
          clientAvatar: req.user.avatar,
          packageName: pkg ? pkg.name : 'بدون باقة',
          location: location,
          price: pkg ? pkg.price : 0,
        }
      );
      logger.info(`✅ New booking notification sent successfully`);
    } catch (notifError) {
      logger.error(`❌ Failed to send push notification: ${notifError.message}`);
      logger.error(`Error stack: ${notifError.stack}`);
      // Don't fail the booking if notification fails
    }

    // Send notification via Socket.IO for real-time updates
    if (io) {
      const photographerUserId = photographerDoc.user._id.toString();

      logger.info(`📤 Sending new_notification event via Socket.IO`);
      io.to(`user_${photographerUserId}`).emit('new_notification', {
        id: `notif_${booking._id}_${Date.now()}`,
        type: 'booking',
        title: '🎉 حجز جديد!',
        body: `لديك حجز جديد من ${req.user.name}`,
        data: {
          bookingId: booking._id.toString(),
          clientName: req.user.name,
          clientAvatar: req.user.avatar,
          date: bookingDate.toISOString(),
          timeSlot: timeSlot,
          packageName: pkg ? pkg.name : 'بدون باقة',
          location: location,
          price: pkg ? pkg.price : 0,
        },
        isRead: false,
        createdAt: new Date().toISOString(),
      });

      // Send notification count update (increment by 1)
      io.to(`user_${photographerUserId}`).emit('notification_count_update', {
        count: 1, // Just increment by 1
        increment: true, // Flag to indicate this should be added to current count
      });

      logger.info(`✅ Socket.IO notification events sent`);
    }

    res.status(201).json({
      success: true,
      message: 'Booking created successfully',
      data: booking,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get all bookings (for client or photographer)
// @route   GET /api/bookings
// @access  Private
exports.getBookings = async (req, res, next) => {
  try {
    const { status, page = 1, limit = 10 } = req.query;

    // Build query based on user role
    const query = {};
    if (req.user.role === 'client') {
      query.client = req.user._id;
    } else if (req.user.role === 'photographer') {
      const photographer = await Photographer.findOne({ user: req.user._id });
      if (!photographer) {
        return res.status(404).json({
          success: false,
          message: 'Photographer profile not found',
        });
      }
      query.photographer = photographer._id;
    }

    if (status) query.status = status;

    const bookings = await Booking.find(query)
      .populate('client', 'name email phone avatar')
      .populate({
        path: 'photographer',
        populate: { path: 'user', select: 'name email phone avatar' },
      })
      .sort('-createdAt')
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const count = await Booking.countDocuments(query);

    res.status(200).json({
      success: true,
      data: bookings,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: count,
        pages: Math.ceil(count / limit),
      },
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get booking by ID
// @route   GET /api/bookings/:id
// @access  Private
exports.getBookingById = async (req, res, next) => {
  try {
    const booking = await Booking.findById(req.params.id)
      .populate('client', 'name email phone avatar')
      .populate({
        path: 'photographer',
        populate: { path: 'user', select: 'name email phone avatar' },
      });

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found',
      });
    }

    // Check authorization
    const photographer = await Photographer.findById(booking.photographer._id);
    if (
      booking.client.toString() !== req.user._id.toString() &&
      photographer.user.toString() !== req.user._id.toString() &&
      req.user.role !== 'admin' && req.user.role !== 'superadmin'
    ) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to view this booking',
      });
    }

    res.status(200).json({
      success: true,
      data: booking,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update booking status
// @route   PUT /api/bookings/:id/status
// @access  Private (photographer or admin)
exports.updateBookingStatus = async (req, res, next) => {
  try {
    const { status } = req.body;

    const booking = await Booking.findById(req.params.id)
      .populate('client', 'name email phone avatar')
      .populate({
        path: 'photographer',
        populate: { path: 'user', select: 'name' }
      });

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found',
      });
    }

    // Check authorization (photographer only)
    const photographer = await Photographer.findById(booking.photographer._id);
    if (
      photographer.user.toString() !== req.user._id.toString() &&
      req.user.role !== 'admin' && req.user.role !== 'superadmin'
    ) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized',
      });
    }

    const oldStatus = booking.status;
    booking.status = status;

    // Update photographer stats if completed
    if (status === 'completed') {
      photographer.stats.completedBookings += 1;
      photographer.stats.totalEarnings += booking.payment.amount;
      await photographer.save();
    }

    await booking.save();

    logger.info(`Booking status updated: ${booking._id} -> ${status}`);

    // Send realtime notification to client via Socket.IO
    const io = req.app.get('io');
    if (io && booking.client) {
      const clientUserId = booking.client._id.toString();

      io.to(`user_${clientUserId}`).emit('booking_status_updated', {
        bookingId: booking._id,
        status,
        oldStatus,
        photographerName: booking.photographer.user.name,
        date: booking.date.toISOString(),
        timeSlot: booking.timeSlot,
        packageName: booking.package.name,
      });

      logger.info(`Realtime status update sent to client ${clientUserId}`);

      // Also send pending bookings count update to photographer
      const photographerUserId = photographer.user.toString();
      const pendingCount = await Booking.countDocuments({
        photographer: booking.photographer._id,
        status: 'pending',
      });

      io.to(`user_${photographerUserId}`).emit('pending_bookings_update', {
        count: pendingCount,
      });

      logger.info(`Pending bookings count update sent to photographer ${photographerUserId} (pending: ${pendingCount})`);
    }

    // Send push notification to client
    const notificationService = require('../services/notificationService');
    try {
      logger.info(`🔍 Sending booking status notification to client ${booking.client._id}`);
      logger.info(`   - Status: ${oldStatus} → ${status}`);
      logger.info(`   - Photographer: ${booking.photographer.user.name}`);

      await notificationService.sendBookingStatusNotification(
        booking.client._id.toString(),
        {
          id: booking._id.toString(),
          status,
          oldStatus,
          date: booking.date.toLocaleDateString('ar-EG', {
            weekday: 'long',
            year: 'numeric',
            month: 'long',
            day: 'numeric'
          }),
          timeSlot: booking.timeSlot,
          photographerName: booking.photographer.user.name,
          photographerAvatar: booking.photographer.user.avatar,
          packageName: booking.package.name,
          location: booking.location,
        }
      );
      logger.info(`✅ Booking status notification sent successfully`);
    } catch (notifError) {
      logger.error(`❌ Failed to send push notification: ${notifError.message}`);
      logger.error(`Error stack: ${notifError.stack}`);
    }

    // Send notification via Socket.IO for real-time updates to client
    if (io && booking.client) {
      const clientUserId = booking.client._id.toString();

      // Determine notification title and body based on status
      let notificationTitle = '';
      let notificationBody = '';

      switch (status) {
        case 'confirmed':
          notificationTitle = '✅ تم تأكيد الحجز';
          notificationBody = `تم تأكيد حجزك مع ${booking.photographer.user.name}`;
          break;
        case 'cancelled':
          notificationTitle = '❌ تم إلغاء الحجز';
          notificationBody = `تم إلغاء حجزك مع ${booking.photographer.user.name}`;
          break;
        case 'completed':
          notificationTitle = '✨ تم إكمال الحجز';
          notificationBody = `تم إكمال حجزك مع ${booking.photographer.user.name}`;
          break;
        default:
          notificationTitle = 'تحديث الحجز';
          notificationBody = `تم تحديث حالة حجزك مع ${booking.photographer.user.name}`;
      }

      logger.info(`📤 Sending new_notification event to client via Socket.IO`);
      io.to(`user_${clientUserId}`).emit('new_notification', {
        id: `notif_${booking._id}_${Date.now()}`,
        type: 'booking',
        title: notificationTitle,
        body: notificationBody,
        data: {
          bookingId: booking._id.toString(),
          status: status,
          oldStatus: oldStatus,
          photographerName: booking.photographer.user.name,
          photographerAvatar: booking.photographer.user.avatar,
          date: booking.date.toISOString(),
          timeSlot: booking.timeSlot,
          packageName: booking.package ? booking.package.name : 'بدون باقة',
          location: booking.location,
        },
        isRead: false,
        createdAt: new Date().toISOString(),
      });

      // Send notification count update (increment by 1)
      io.to(`user_${clientUserId}`).emit('notification_count_update', {
        count: 1, // Just increment by 1
        increment: true, // Flag to indicate this should be added to current count
      });

      logger.info(`✅ Socket.IO notification events sent to client`);
    }

    res.status(200).json({
      success: true,
      message: 'Booking status updated',
      data: booking,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Cancel booking
// @route   PUT /api/bookings/:id/cancel
// @access  Private
exports.cancelBooking = async (req, res, next) => {
  try {
    const { reason } = req.body;

    const booking = await Booking.findById(req.params.id);

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found',
      });
    }

    // Check authorization
    const photographer = await Photographer.findById(booking.photographer);
    const isClient = booking.client.toString() === req.user._id.toString();
    const isPhotographer = photographer.user.toString() === req.user._id.toString();

    if (!isClient && !isPhotographer && req.user.role !== 'admin' && req.user.role !== 'superadmin') {
      return res.status(403).json({
        success: false,
        message: 'Not authorized',
      });
    }

    // Check if can be cancelled
    if (booking.status === 'completed' || booking.status === 'cancelled') {
      return res.status(400).json({
        success: false,
        message: 'Cannot cancel this booking',
      });
    }

    booking.status = 'cancelled';
    booking.cancellation = {
      cancelledBy: isClient ? 'client' : isPhotographer ? 'photographer' : 'admin',
      reason,
      cancelledAt: new Date(),
    };

    await booking.save();

    // Populate booking details for notification
    await booking.populate('client', 'name email phone avatar');
    await booking.populate({
      path: 'photographer',
      populate: { path: 'user', select: 'name email phone avatar' }
    });

    logger.info(`Booking cancelled: ${booking._id} by ${booking.cancellation.cancelledBy}`);

    // Send notification to the other party
    const notificationService = require('../services/notificationService');
    const io = req.app.get('io');

    try {
      if (isClient) {
        // Client cancelled, notify photographer
        const photographerUserId = photographer.user.toString();

        logger.info(`🔍 Sending cancellation notification to photographer ${photographerUserId}`);

        // Send push notification
        await notificationService.sendBookingCancellationNotification(
          photographerUserId,
          {
            id: booking._id.toString(),
            cancelledBy: 'client',
            clientName: req.user.name,
            date: booking.date.toLocaleDateString('ar-EG', {
              weekday: 'long',
              year: 'numeric',
              month: 'long',
              day: 'numeric'
            }),
            timeSlot: booking.timeSlot,
            packageName: booking.package.name,
            reason: reason || 'لم يتم تحديد سبب',
          }
        );

        // Send realtime notification
        if (io) {
          io.to(`user_${photographerUserId}`).emit('booking_cancelled', {
            bookingId: booking._id,
            cancelledBy: 'client',
            clientName: req.user.name,
            reason: reason,
          });
        }

        logger.info(`✅ Cancellation notification sent to photographer`);
      } else if (isPhotographer) {
        // Photographer cancelled, notify client
        const clientUserId = booking.client._id.toString();

        logger.info(`🔍 Sending cancellation notification to client ${clientUserId}`);

        // Send push notification
        await notificationService.sendBookingCancellationNotification(
          clientUserId,
          {
            id: booking._id.toString(),
            cancelledBy: 'photographer',
            photographerName: booking.photographer.user.name,
            date: booking.date.toLocaleDateString('ar-EG', {
              weekday: 'long',
              year: 'numeric',
              month: 'long',
              day: 'numeric'
            }),
            timeSlot: booking.timeSlot,
            packageName: booking.package.name,
            reason: reason || 'لم يتم تحديد سبب',
          }
        );

        // Send realtime notification
        if (io) {
          io.to(`user_${clientUserId}`).emit('booking_cancelled', {
            bookingId: booking._id,
            cancelledBy: 'photographer',
            photographerName: booking.photographer.user.name,
            reason: reason,
          });
        }

        logger.info(`✅ Cancellation notification sent to client`);
      }
    } catch (notifError) {
      logger.error(`❌ Failed to send cancellation notification: ${notifError.message}`);
      logger.error(`Error stack: ${notifError.stack}`);
    }

    res.status(200).json({
      success: true,
      message: 'Booking cancelled successfully',
      data: booking,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Check photographer availability
// @route   GET /api/bookings/availability/:photographerId
// @access  Public
exports.checkAvailability = async (req, res, next) => {
  try {
    const { photographerId } = req.params;
    const { date } = req.query;

    if (!date) {
      return res.status(400).json({
        success: false,
        message: 'Date is required',
      });
    }

    const photographer = await Photographer.findById(photographerId);
    if (!photographer) {
      return res.status(404).json({
        success: false,
        message: 'Photographer not found',
      });
    }

    const checkDate = new Date(date);

    // Check if date is blocked
    const isBlocked = photographer.availability.blockedDates.some(
      (blockedDate) =>
        blockedDate.toDateString() === checkDate.toDateString()
    );

    if (isBlocked) {
      return res.status(200).json({
        success: true,
        data: {
          availableSlots: [],
          isAvailable: false,
          message: 'This date is blocked',
        },
      });
    }

    // Check existing bookings for this date
    const existingBookings = await Booking.find({
      photographer: photographerId,
      date: checkDate,
      status: { $in: ['pending', 'confirmed'] },
    });

    // Generate time slots (9 AM to 9 PM, 2-hour slots)
    const allSlots = [
      '09:00 - 11:00',
      '11:00 - 13:00',
      '13:00 - 15:00',
      '15:00 - 17:00',
      '17:00 - 19:00',
      '19:00 - 21:00',
    ];

    // Filter out booked slots
    const bookedSlots = existingBookings.map((b) => b.timeSlot);
    const availableSlots = allSlots.filter((slot) => !bookedSlots.includes(slot));

    res.status(200).json({
      success: true,
      data: {
        availableSlots,
        isAvailable: availableSlots.length > 0,
        bookedSlots,
      },
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get booked dates for photographer
// @route   GET /api/bookings/booked-dates/:photographerId
// @access  Public
exports.getBookedDates = async (req, res, next) => {
  try {
    const { photographerId } = req.params;
    const { startDate, endDate } = req.query;

    const photographer = await Photographer.findById(photographerId);
    if (!photographer) {
      return res.status(404).json({
        success: false,
        message: 'Photographer not found',
      });
    }

    // Build query for bookings
    const query = {
      photographer: photographerId,
      status: { $in: ['pending', 'confirmed'] },
    };

    // Add date range if provided
    if (startDate && endDate) {
      query.date = {
        $gte: new Date(startDate),
        $lte: new Date(endDate),
      };
    }

    // Get all bookings
    const bookings = await Booking.find(query).select('date timeSlot');

    // Group by date and count bookings per date
    const bookedDatesMap = {};
    bookings.forEach((booking) => {
      const dateKey = booking.date.toISOString().split('T')[0];
      if (!bookedDatesMap[dateKey]) {
        bookedDatesMap[dateKey] = {
          date: dateKey,
          bookingsCount: 0,
          bookedSlots: [],
        };
      }
      bookedDatesMap[dateKey].bookingsCount++;
      bookedDatesMap[dateKey].bookedSlots.push(booking.timeSlot);
    });

    // Convert to array
    const bookedDates = Object.values(bookedDatesMap);

    res.status(200).json({
      success: true,
      data: {
        bookedDates,
        blockedDates: photographer.availability.blockedDates,
      },
    });
  } catch (error) {
    next(error);
  }
};
