const User = require('../models/User');
const Photographer = require('../models/Photographer');
const Booking = require('../models/Booking');
const Review = require('../models/Review');
const Report = require('../models/Report');
const Notification = require('../models/Notification');
const logger = require('../utils/logger');
const jwt = require('jsonwebtoken');

// @desc    Admin login
// @route   POST /api/admin/login
// @access  Public
exports.login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    // Check if user exists
    const user = await User.findOne({ email }).select('+password');
    if (!user) {
      console.log(`Login failed: User ${email} not found`);
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials',
      });
    }

    // Check if user is admin
    if (user.role !== 'admin' && user.role !== 'superadmin') {
      console.log(`Login failed: User ${email} is not admin (role: ${user.role})`);
      return res.status(403).json({
        success: false,
        message: 'Access denied. Admin only.',
      });
    }

    // Check password
    const isPasswordMatch = await user.comparePassword(password);
    if (!isPasswordMatch) {
      console.log(`Login failed: Password mismatch for ${email}`);
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials',
      });
    }

    // Generate token
    const token = jwt.sign(
      { userId: user._id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRE || '7d' }
    );

    logger.info(`Admin logged in: ${user.email}`);

    res.status(200).json({
      success: true,
      message: 'Login successful',
      data: {
        user: {
          _id: user._id,
          id: user._id,
          name: user.name,
          email: user.email,
          phone: user.phone || '',
          role: user.role,
          avatar: user.avatar,
          isBlocked: user.isBlocked || false,
          createdAt: user.createdAt,
          updatedAt: user.updatedAt,
        },
        token,
      },
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get dashboard statistics
// @route   GET /api/admin/dashboard
// @access  Private (Admin)
exports.getDashboard = async (req, res, next) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const [
      totalUsers,
      activeUsersToday,
      totalClients,
      totalPhotographers,
      verifiedPhotographers,
      pendingVerifications,
      totalBookings,
      pendingBookings,
      confirmedBookings,
      completedBookings,
      cancelledBookings,
      totalReviews,
      revenueData,
    ] = await Promise.all([
      User.countDocuments(),
      User.countDocuments({ updatedAt: { $gte: today } }),
      User.countDocuments({ role: 'client' }),
      Photographer.countDocuments(),
      Photographer.countDocuments({ 'verification.status': 'approved' }),
      Photographer.countDocuments({ 'verification.status': 'pending' }),
      Booking.countDocuments(),
      Booking.countDocuments({ status: 'pending' }),
      Booking.countDocuments({ status: 'confirmed' }),
      Booking.countDocuments({ status: 'completed' }),
      Booking.countDocuments({ status: 'cancelled' }),
      Review.countDocuments(),
      calculateRevenue(),
    ]);

    // Calculate conversion rate
    const conversionRate = totalUsers > 0
      ? ((completedBookings / totalUsers) * 100).toFixed(2)
      : 0;

    // Calculate cancellation rate
    const cancellationRate = totalBookings > 0
      ? ((cancelledBookings / totalBookings) * 100).toFixed(2)
      : 0;

    res.status(200).json({
      success: true,
      data: {
        users: {
          total: totalUsers,
          activeToday: activeUsersToday,
          clients: totalClients,
          photographers: totalPhotographers,
        },
        photographers: {
          total: totalPhotographers,
          verified: verifiedPhotographers,
          pendingVerification: pendingVerifications,
        },
        bookings: {
          total: totalBookings,
          pending: pendingBookings,
          confirmed: confirmedBookings,
          completed: completedBookings,
          cancelled: cancelledBookings,
        },
        reviews: {
          total: totalReviews,
        },
        revenue: revenueData,
        metrics: {
          conversionRate: parseFloat(conversionRate),
          cancellationRate: parseFloat(cancellationRate),
        },
      },
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get all users with filters
// @route   GET /api/admin/users
// @access  Private (Admin)
exports.getUsers = async (req, res, next) => {
  try {
    const {
      page = 1,
      limit = 20,
      search,
      role,
      isBlocked,
      sortBy = 'createdAt',
      sortOrder = 'desc',
    } = req.query;

    const query = {};

    // Search filter
    if (search) {
      query.$or = [
        { name: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } },
        { phone: { $regex: search, $options: 'i' } },
      ];
    }

    // Role filter
    if (role) query.role = role;

    // Blocked filter
    if (isBlocked !== undefined) query.isBlocked = isBlocked === 'true';

    // Sort options
    const sort = {};
    sort[sortBy] = sortOrder === 'desc' ? -1 : 1;

    const users = await User.find(query)
      .select('-password -refreshToken')
      .sort(sort)
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const count = await User.countDocuments(query);

    res.status(200).json({
      success: true,
      data: users,
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

// @desc    Toggle user block status
// @route   PATCH /api/admin/users/:userId/block
// @access  Private (Admin)
exports.toggleUserBlock = async (req, res, next) => {
  try {
    const { userId } = req.params;
    const { reason } = req.body;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    if (user.role === 'superadmin') {
      return res.status(403).json({
        success: false,
        message: 'Cannot block superadmin users',
      });
    }

    user.isBlocked = !user.isBlocked;
    await user.save();

    logger.info(`User ${user.isBlocked ? 'blocked' : 'unblocked'}: ${user.email} by admin`);

    // Send notification and socket event to user
    try {
      const notificationService = require('../services/notificationService');
      const io = req.app.get('io');

      if (user.isBlocked) {
        // User is being blocked
        await notificationService.sendAccountBlockedNotification(user._id.toString(), reason || 'تم حظر حسابك من قبل الإدارة');

        // Emit socket event for immediate logout
        if (io) {
          io.to(`user_${user._id}`).emit('user_banned', {
            reason: reason || 'تم حظر حسابك من قبل الإدارة',
            isBlocked: true
          });
          logger.info(`Socket event user_banned emitted to user_${user._id}`);
        }
      } else {
        // User is being unblocked
        await notificationService.sendToUser(user._id.toString(), {
          title: 'تم فتح الحساب',
          body: 'تم فتح حسابك. يمكنك الآن استخدام التطبيق بشكل طبيعي.',
          data: { type: 'account_unblocked' }
        });

        // Emit socket event for immediate update
        if (io) {
          io.to(`user_${user._id}`).emit('user_unblocked', {
            message: 'تم فتح حسابك. يمكنك الآن استخدام التطبيق بشكل طبيعي.',
            isBlocked: false
          });
          logger.info(`Socket event user_unblocked emitted to user_${user._id}`);
        }
      }
    } catch (notifyError) {
      logger.error(`Failed to send block/unblock notification: ${notifyError.message}`);
      // Don't fail the request if notification fails
    }

    res.status(200).json({
      success: true,
      message: `User ${user.isBlocked ? 'blocked' : 'unblocked'} successfully`,
      data: user,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Delete user
// @route   DELETE /api/admin/users/:userId
// @access  Private (Admin)
exports.deleteUser = async (req, res, next) => {
  try {
    const { userId } = req.params;
    const cleanupService = require('../services/cleanupService');

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    if (user.role === 'superadmin') {
      return res.status(403).json({
        success: false,
        message: 'Cannot delete superadmin users',
      });
    }

    await cleanupService.deleteUserComplete(userId);

    res.status(200).json({
      success: true,
      message: 'User deleted successfully',
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get all photographers
// @route   GET /api/admin/photographers
// @access  Private (Admin)
exports.getAllPhotographers = async (req, res, next) => {
  try {
    const { page = 1, limit = 20, status, search } = req.query;

    const query = {};
    if (status && status !== 'all') {
      query['verification.status'] = status;
    }

    if (search) {
      const searchRegex = { $regex: search, $options: 'i' };
      // We need to find users first if searching by name/email since they are in User model
      const users = await User.find({
        $or: [{ name: searchRegex }, { email: searchRegex }, { phone: searchRegex }]
      }).select('_id');

      const userIds = users.map(u => u._id);

      // Or search in Photographer specific fields
      query.$or = [
        { user: { $in: userIds } },
        { 'location.city': searchRegex },
        { 'location.area': searchRegex }
      ];
    }

    const photographers = await Photographer.find(query)
      .populate('user', 'name email phone avatar')
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const count = await Photographer.countDocuments(query);

    res.status(200).json({
      success: true,
      data: photographers,
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

// @desc    Get pending photographer verifications
// @route   GET /api/admin/photographers/pending
// @access  Private (Admin)
exports.getPendingVerifications = async (req, res, next) => {
  try {
    const { page = 1, limit = 20 } = req.query;

    const photographers = await Photographer.find({
      'verification.status': 'pending',
    })
      .populate('user', 'name email phone avatar')
      .sort({ 'verification.submittedAt': -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const count = await Photographer.countDocuments({
      'verification.status': 'pending',
    });

    res.status(200).json({
      success: true,
      data: photographers,
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

// @desc    Approve photographer verification
// @route   PATCH /api/admin/photographers/:photographerId/approve
// @access  Private (Admin)
exports.approvePhotographer = async (req, res, next) => {
  try {
    const { photographerId } = req.params;

    const photographer = await Photographer.findById(photographerId).populate(
      'user',
      'name email'
    );

    if (!photographer) {
      return res.status(404).json({
        success: false,
        message: 'Photographer not found',
      });
    }

    photographer.verification.status = 'approved';
    photographer.verification.reviewedAt = new Date();
    photographer.verification.reviewedBy = req.user._id;
    await photographer.save();

    logger.info(`Photographer approved: ${photographer.user.email}`);

    // Send notification
    const notificationService = require('../services/notificationService');
    await notificationService.sendVerificationApprovedNotification(
      photographer.user._id.toString()
    );

    res.status(200).json({
      success: true,
      message: 'Photographer approved successfully',
      data: photographer,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Reject photographer verification
// @route   PATCH /api/admin/photographers/:photographerId/reject
// @access  Private (Admin)
exports.rejectPhotographer = async (req, res, next) => {
  try {
    const { photographerId } = req.params;
    const { reason } = req.body;

    const photographer = await Photographer.findById(photographerId).populate(
      'user',
      'name email'
    );

    if (!photographer) {
      return res.status(404).json({
        success: false,
        message: 'Photographer not found',
      });
    }

    photographer.verification.status = 'rejected';
    photographer.verification.reviewedAt = new Date();
    photographer.verification.reviewedBy = req.user._id;
    photographer.verification.rejectionReason = reason;
    await photographer.save();

    logger.info(`Photographer rejected: ${photographer.user.email}`);

    // Send notification
    const notificationService = require('../services/notificationService');
    await notificationService.sendVerificationRejectedNotification(
      photographer.user._id.toString(),
      reason
    );

    res.status(200).json({
      success: true,
      message: 'Photographer rejected',
      data: photographer,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Revoke photographer verification
// @route   PATCH /api/admin/photographers/:photographerId/revoke
// @access  Private (Admin)
exports.revokePhotographerVerification = async (req, res, next) => {
  try {
    const { photographerId } = req.params;
    const { reason } = req.body;

    const photographer = await Photographer.findById(photographerId).populate(
      'user',
      'name email'
    );

    if (!photographer) {
      return res.status(404).json({
        success: false,
        message: 'Photographer not found',
      });
    }

    // Reset verification status
    photographer.verification.status = 'not_submitted';
    photographer.verification.reviewedAt = new Date();
    photographer.verification.reviewedBy = req.user._id;
    // We can keep the documents or clear them. Let's keep them but mark as revoked.
    // Actually, if we set to not_submitted, the user can re-submit.

    await photographer.save();

    logger.info(`Photographer verification revoked: ${photographer.user.email}`);

    // Send notification
    const notificationService = require('../services/notificationService');
    // We might need a specific notification for revocation
    await notificationService.sendToUser(photographer.user._id.toString(), {
      title: 'تم سحب التوثيق',
      body: reason || 'تم سحب شارة التوثيق من حسابك. يرجى مراجعة الإدارة أو تقديم طلب جديد.',
      data: { type: 'verification_revoked' }
    });

    res.status(200).json({
      success: true,
      message: 'Verification revoked successfully',
      data: photographer,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get all bookings with filters
// @route   GET /api/admin/bookings
// @access  Private (Admin)
exports.getBookings = async (req, res, next) => {
  try {
    const {
      page = 1,
      limit = 20,
      status,
      startDate,
      endDate,
      sortBy = 'createdAt',
      sortOrder = 'desc',
    } = req.query;

    const query = {};

    if (status) query.status = status;

    if (startDate || endDate) {
      query.date = {};
      if (startDate) query.date.$gte = new Date(startDate);
      if (endDate) query.date.$lte = new Date(endDate);
    }

    const sort = {};
    sort[sortBy] = sortOrder === 'desc' ? -1 : 1;

    const bookings = await Booking.find(query)
      .populate('client', 'name email phone avatar')
      .populate({
        path: 'photographer',
        populate: { path: 'user', select: 'name email phone avatar' },
      })
      .sort(sort)
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

// @desc    Get revenue report
// @route   GET /api/admin/revenue
// @access  Private (Admin)
exports.getRevenueReport = async (req, res, next) => {
  try {
    const { period = '30d', startDate, endDate } = req.query;

    let dateFilter = {};
    if (startDate && endDate) {
      dateFilter = {
        createdAt: {
          $gte: new Date(startDate),
          $lte: new Date(endDate),
        },
      };
    } else {
      const days = parseInt(period);
      const date = new Date();
      date.setDate(date.getDate() - days);
      dateFilter = { createdAt: { $gte: date } };
    }

    const bookings = await Booking.find({
      ...dateFilter,
      status: 'completed',
    });

    const totalRevenue = bookings.reduce((sum, b) => sum + b.payment.amount, 0);
    const totalCommission = bookings.reduce((sum, b) => sum + b.payment.commission, 0);

    // Group by date
    const revenueByDate = {};
    bookings.forEach((booking) => {
      const date = booking.createdAt.toISOString().split('T')[0];
      if (!revenueByDate[date]) {
        revenueByDate[date] = {
          date,
          revenue: 0,
          commission: 0,
          bookings: 0,
        };
      }
      revenueByDate[date].revenue += booking.payment.amount;
      revenueByDate[date].commission += booking.payment.commission;
      revenueByDate[date].bookings += 1;
    });

    const chartData = Object.values(revenueByDate).sort((a, b) =>
      a.date.localeCompare(b.date)
    );

    res.status(200).json({
      success: true,
      data: {
        totalRevenue,
        totalCommission,
        totalBookings: bookings.length,
        averageBookingValue: bookings.length > 0 ? totalRevenue / bookings.length : 0,
        chartData,
      },
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Delete review
// @route   DELETE /api/admin/reviews/:reviewId
// @access  Private (Admin)
exports.deleteReview = async (req, res, next) => {
  try {
    const { reviewId } = req.params;

    const review = await Review.findById(reviewId);
    if (!review) {
      return res.status(404).json({
        success: false,
        message: 'Review not found',
      });
    }

    await review.deleteOne();

    // Update photographer rating
    const photographer = await Photographer.findById(review.photographer);
    if (photographer) {
      const reviews = await Review.find({ photographer: photographer._id });
      const avgRating =
        reviews.length > 0
          ? reviews.reduce((sum, r) => sum + r.rating, 0) / reviews.length
          : 0;

      photographer.rating.average = avgRating;
      photographer.rating.count = reviews.length;
      await photographer.save();
    }

    logger.info(`Review deleted by admin: ${reviewId}`);

    res.status(200).json({
      success: true,
      message: 'Review deleted successfully',
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get all reviews with filters
// @route   GET /api/admin/reviews
// @access  Private (Admin)
exports.getReviews = async (req, res, next) => {
  try {
    const { page = 1, limit = 20, search, rating, sortBy = 'createdAt', sortOrder = 'desc' } = req.query;

    const query = {};

    if (rating) query.rating = rating;

    const sort = {};
    sort[sortBy] = sortOrder === 'desc' ? -1 : 1;

    const reviews = await Review.find(query)
      .populate('client', 'name email avatar')
      .populate({
        path: 'photographer',
        populate: { path: 'user', select: 'name email avatar' }
      })
      .sort(sort)
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const count = await Review.countDocuments(query);

    res.status(200).json({
      success: true,
      data: reviews,
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

// @desc    Broadcast notification
// @route   POST /api/admin/notifications/broadcast
// @access  Private (Admin)
exports.broadcastNotification = async (req, res, next) => {
  try {
    const { title, body, target = 'all' } = req.body;

    if (!title || !body) {
      return res.status(400).json({
        success: false,
        message: 'Title and body are required',
      });
    }

    let query = {};
    if (target === 'clients') {
      query.role = 'client';
    } else if (target === 'photographers') {
      query.role = 'photographer';
    }

    const users = await User.find(query).select('_id');
    const userIds = users.map((u) => u._id.toString());

    if (userIds.length > 0) {
      const notificationService = require('../services/notificationService');

      // 1. Send OneSignal Notification
      await notificationService.sendToMultipleUsers(userIds, {
        title,
        body,
        data: { type: 'broadcast' },
      });

      // 2. Save to Database for each user
      const notificationsToSave = userIds.map(userId => ({
        recipient: userId,
        type: 'system',
        title: `إدارة حجزي: ${title}`,
        message: body,
        data: {
          type: 'broadcast',
          senderName: 'إدارة حجزي'
        },
        read: false
      }));

      await Notification.insertMany(notificationsToSave);
    }

    logger.info(`Broadcast notification sent and saved for ${userIds.length} users (${target})`);

    res.status(200).json({
      success: true,
      message: `Notification sent to ${userIds.length} users`,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get analytics data
// @route   GET /api/admin/analytics
// @access  Private (Admin)
exports.getAnalytics = async (req, res, next) => {
  try {
    const { period = '30d' } = req.query;
    const days = parseInt(period);
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    // Users growth
    const usersGrowth = await getUsersGrowth(startDate);

    // Bookings trend
    const bookingsTrend = await getBookingsTrend(startDate);

    // Revenue trend
    const revenueTrend = await getRevenueTrend(startDate);

    // Top photographers
    const topPhotographers = await getTopPhotographers(10);

    // Popular specialties
    const popularSpecialties = await getPopularSpecialties();

    res.status(200).json({
      success: true,
      data: {
        usersGrowth,
        bookingsTrend,
        revenueTrend,
        topPhotographers,
        popularSpecialties,
      },
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get subscription statistics
// @route   GET /api/admin/subscriptions/stats
// @access  Private (Admin)
exports.getSubscriptionStats = async (req, res, next) => {
  try {
    const stats = await Photographer.aggregate([
      {
        $group: {
          _id: '$subscription.plan',
          count: { $sum: 1 },
        },
      },
    ]);

    const planCounts = {
      basic: 0,
      pro: 0,
      premium: 0,
    };

    stats.forEach((stat) => {
      if (stat._id) {
        planCounts[stat._id] = stat.count;
      }
    });

    const totalPhotographers = await Photographer.countDocuments();
    const activeSubscriptions = await Photographer.countDocuments({
      'subscription.isActive': true,
      'subscription.plan': { $ne: 'basic' },
    });

    // Calculate estimated monthly revenue from subscriptions
    // Assuming Pro = 10, Premium = 20 (as per subscriptionController)
    const proPrice = parseFloat(process.env.SUBSCRIPTION_PRO_PRICE) || 10;
    const premiumPrice = parseFloat(process.env.SUBSCRIPTION_PREMIUM_PRICE) || 20;

    const estimatedRevenue =
      planCounts.pro * proPrice + planCounts.premium * premiumPrice;

    res.status(200).json({
      success: true,
      data: {
        planCounts,
        totalPhotographers,
        activeSubscriptions,
        estimatedRevenue,
      },
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get all reports
// @route   GET /api/admin/reports
// @access  Private (Admin)
exports.getReports = async (req, res, next) => {
  try {
    const { page = 1, limit = 20, status, sortBy = 'createdAt', sortOrder = 'desc' } = req.query;

    const query = {};
    if (status) query.status = status;

    const sort = {};
    sort[sortBy] = sortOrder === 'desc' ? -1 : 1;

    const reports = await Report.find(query)
      .populate('reporter', 'name email avatar')
      .populate('reportedUser', 'name email avatar')
      .sort(sort)
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const count = await Report.countDocuments(query);

    res.status(200).json({
      success: true,
      data: reports,
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

// @desc    Resolve a report
// @route   PATCH /api/admin/reports/:reportId/resolve
// @access  Private (Admin)
exports.resolveReport = async (req, res, next) => {
  try {
    const { reportId } = req.params;
    const { resolution, status } = req.body;

    const report = await Report.findById(reportId);
    if (!report) {
      return res.status(404).json({
        success: false,
        message: 'Report not found',
      });
    }

    report.status = status || 'resolved';
    report.resolution = resolution;
    report.resolvedBy = req.user._id;
    report.resolvedAt = new Date();
    await report.save();

    logger.info(`Report resolved by admin: ${reportId}`);

    res.status(200).json({
      success: true,
      message: 'Report resolved successfully',
      data: report,
    });
  } catch (error) {
    next(error);
  }
};

// Helper functions
async function calculateRevenue() {
  const completedBookings = await Booking.find({ status: 'completed' });

  const totalRevenue = completedBookings.reduce((sum, b) => sum + b.payment.amount, 0);
  const totalCommission = completedBookings.reduce((sum, b) => sum + b.payment.commission, 0);

  // Monthly revenue
  const thisMonth = new Date();
  thisMonth.setDate(1);
  thisMonth.setHours(0, 0, 0, 0);

  const monthlyBookings = await Booking.find({
    status: 'completed',
    createdAt: { $gte: thisMonth },
  });

  const monthlyRevenue = monthlyBookings.reduce((sum, b) => sum + b.payment.amount, 0);

  // Average booking value
  const averageBookingValue = completedBookings.length > 0
    ? totalRevenue / completedBookings.length
    : 0;

  return {
    totalRevenue,
    totalCommission,
    monthlyRevenue,
    averageBookingValue,
  };
}

async function getUsersGrowth(startDate) {
  const users = await User.aggregate([
    { $match: { createdAt: { $gte: startDate } } },
    {
      $group: {
        _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
        count: { $sum: 1 },
      },
    },
    { $sort: { _id: 1 } },
  ]);

  return users.map((u) => ({ date: u._id, count: u.count }));
}

async function getBookingsTrend(startDate) {
  const bookings = await Booking.aggregate([
    { $match: { createdAt: { $gte: startDate } } },
    {
      $group: {
        _id: {
          date: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
          status: '$status',
        },
        count: { $sum: 1 },
      },
    },
    { $sort: { '_id.date': 1 } },
  ]);

  return bookings;
}

async function getRevenueTrend(startDate) {
  const revenue = await Booking.aggregate([
    {
      $match: {
        createdAt: { $gte: startDate },
        status: 'completed',
      },
    },
    {
      $group: {
        _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
        revenue: { $sum: '$payment.amount' },
        commission: { $sum: '$payment.commission' },
        count: { $sum: 1 },
      },
    },
    { $sort: { _id: 1 } },
  ]);

  return revenue.map((r) => ({
    date: r._id,
    revenue: r.revenue,
    commission: r.commission,
    bookings: r.count,
  }));
}

async function getTopPhotographers(limit) {
  const photographers = await Photographer.find()
    .populate('user', 'name email avatar')
    .sort({ 'stats.completedBookings': -1, 'rating.average': -1 })
    .limit(limit);

  return photographers.map((p) => ({
    id: p._id,
    name: p.user.name,
    email: p.user.email,
    avatar: p.user.avatar,
    completedBookings: p.stats.completedBookings,
    totalEarnings: p.stats.totalEarnings,
    rating: p.rating.average,
    reviewsCount: p.rating.count,
  }));
}

async function getPopularSpecialties() {
  const specialties = await Photographer.aggregate([
    { $unwind: '$specialties' },
    {
      $group: {
        _id: '$specialties',
        count: { $sum: 1 },
      },
    },
    { $sort: { count: -1 } },
  ]);

  return specialties.map((s) => ({
    specialty: s._id,
    count: s.count,
  }));
}

module.exports = exports;
