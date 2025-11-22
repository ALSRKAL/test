const Photographer = require('../models/Photographer');
const Booking = require('../models/Booking');
const User = require('../models/User');
const Review = require('../models/Review');

/**
 * Analytics Service
 * Provides analytics and statistics for the application
 */

/**
 * Get dashboard statistics
 * @returns {Promise<Object>} Dashboard stats
 */
const getDashboardStats = async () => {
  try {
    const [
      totalUsers,
      totalPhotographers,
      totalBookings,
      totalRevenue,
      pendingVerifications,
      activeSubscriptions,
    ] = await Promise.all([
      User.countDocuments({ role: 'client' }),
      Photographer.countDocuments(),
      Booking.countDocuments(),
      Booking.aggregate([
        { $match: { status: 'completed' } },
        { $group: { _id: null, total: { $sum: '$price' } } },
      ]),
      Photographer.countDocuments({ 'verification.status': 'pending' }),
      Photographer.countDocuments({
        'subscription.isActive': true,
        'subscription.plan': { $ne: 'basic' },
      }),
    ]);

    return {
      totalUsers,
      totalPhotographers,
      totalBookings,
      totalRevenue: totalRevenue[0]?.total || 0,
      pendingVerifications,
      activeSubscriptions,
    };
  } catch (error) {
    throw new Error(`Failed to get dashboard stats: ${error.message}`);
  }
};

/**
 * Get photographer analytics
 * @param {string} photographerId - Photographer ID
 * @returns {Promise<Object>} Photographer analytics
 */
const getPhotographerAnalytics = async (photographerId) => {
  try {
    const photographer = await Photographer.findById(photographerId);
    if (!photographer) {
      throw new Error('Photographer not found');
    }

    const [bookings, reviews, earnings] = await Promise.all([
      Booking.find({ photographer: photographerId }),
      Review.find({ photographer: photographerId }),
      Booking.aggregate([
        {
          $match: {
            photographer: photographer._id,
            status: 'completed',
          },
        },
        {
          $group: {
            _id: null,
            total: { $sum: '$price' },
            count: { $sum: 1 },
          },
        },
      ]),
    ]);

    const bookingsByStatus = bookings.reduce((acc, booking) => {
      acc[booking.status] = (acc[booking.status] || 0) + 1;
      return acc;
    }, {});

    return {
      totalBookings: bookings.length,
      bookingsByStatus,
      totalReviews: reviews.length,
      averageRating: photographer.rating.average,
      totalEarnings: earnings[0]?.total || 0,
      completedBookings: earnings[0]?.count || 0,
      profileViews: photographer.stats.views,
    };
  } catch (error) {
    throw new Error(`Failed to get photographer analytics: ${error.message}`);
  }
};

/**
 * Get booking trends
 * @param {number} days - Number of days to analyze
 * @returns {Promise<Array>} Booking trends
 */
const getBookingTrends = async (days = 30) => {
  try {
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    const trends = await Booking.aggregate([
      {
        $match: {
          createdAt: { $gte: startDate },
        },
      },
      {
        $group: {
          _id: {
            $dateToString: { format: '%Y-%m-%d', date: '$createdAt' },
          },
          count: { $sum: 1 },
          revenue: { $sum: '$price' },
        },
      },
      {
        $sort: { _id: 1 },
      },
    ]);

    return trends;
  } catch (error) {
    throw new Error(`Failed to get booking trends: ${error.message}`);
  }
};

/**
 * Get popular categories
 * @returns {Promise<Array>} Popular categories
 */
const getPopularCategories = async () => {
  try {
    const categories = await Photographer.aggregate([
      { $unwind: '$specialties' },
      {
        $group: {
          _id: '$specialties',
          count: { $sum: 1 },
        },
      },
      { $sort: { count: -1 } },
    ]);

    return categories;
  } catch (error) {
    throw new Error(`Failed to get popular categories: ${error.message}`);
  }
};

/**
 * Get revenue report
 * @param {Date} startDate - Start date
 * @param {Date} endDate - End date
 * @returns {Promise<Object>} Revenue report
 */
const getRevenueReport = async (startDate, endDate) => {
  try {
    const report = await Booking.aggregate([
      {
        $match: {
          status: 'completed',
          createdAt: { $gte: startDate, $lte: endDate },
        },
      },
      {
        $group: {
          _id: null,
          totalRevenue: { $sum: '$price' },
          totalBookings: { $sum: 1 },
          averageBookingValue: { $avg: '$price' },
        },
      },
    ]);

    return report[0] || { totalRevenue: 0, totalBookings: 0, averageBookingValue: 0 };
  } catch (error) {
    throw new Error(`Failed to get revenue report: ${error.message}`);
  }
};

module.exports = {
  getDashboardStats,
  getPhotographerAnalytics,
  getBookingTrends,
  getPopularCategories,
  getRevenueReport,
};
