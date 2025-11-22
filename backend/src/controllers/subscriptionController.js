const Photographer = require('../models/Photographer');
const logger = require('../utils/logger');

// Subscription plans
const PLANS = {
  basic: {
    name: 'Basic',
    price: 0,
    features: [
      'حتى 5 حجوزات شهرياً',
      'معرض أعمال (10 صور)',
      'دعم فني أساسي',
    ],
    maxBookings: 5,
    maxPortfolioImages: 10,
  },
  pro: {
    name: 'Pro',
    price: parseFloat(process.env.SUBSCRIPTION_PRO_PRICE) || 10,
    features: [
      'حجوزات غير محدودة',
      'معرض أعمال (20 صورة + فيديو)',
      'دعم فني ذو أولوية',
      'إحصائيات متقدمة',
    ],
    maxBookings: -1, // unlimited
    maxPortfolioImages: 20,
  },
  premium: {
    name: 'Premium',
    price: parseFloat(process.env.SUBSCRIPTION_PREMIUM_PRICE) || 20,
    features: [
      'جميع مميزات Pro',
      'ظهور مميز في البحث',
      'شارة Premium',
      'تقارير مفصلة',
      'دعم فني VIP',
    ],
    maxBookings: -1, // unlimited
    maxPortfolioImages: 20,
    featured: true,
  },
};

// @desc    Get subscription plans
// @route   GET /api/subscriptions/plans
// @access  Public
exports.getPlans = async (req, res, next) => {
  try {
    res.status(200).json({
      success: true,
      data: PLANS,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get my subscription
// @route   GET /api/subscriptions/my-subscription
// @access  Private (photographer)
exports.getMySubscription = async (req, res, next) => {
  try {
    const photographer = await Photographer.findOne({ user: req.user._id });

    if (!photographer) {
      return res.status(404).json({
        success: false,
        message: 'Photographer profile not found',
      });
    }

    res.status(200).json({
      success: true,
      data: {
        subscription: photographer.subscription,
        plan: PLANS[photographer.subscription.plan],
      },
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Subscribe to plan
// @route   POST /api/subscriptions/subscribe
// @access  Private (photographer)
exports.subscribe = async (req, res, next) => {
  try {
    const { plan } = req.body;

    // Validate plan
    if (!PLANS[plan]) {
      return res.status(400).json({
        success: false,
        message: 'Invalid plan',
      });
    }

    const photographer = await Photographer.findOne({ user: req.user._id });

    if (!photographer) {
      return res.status(404).json({
        success: false,
        message: 'Photographer profile not found',
      });
    }

    // Calculate end date (30 days from now)
    const startDate = new Date();
    const endDate = new Date();
    endDate.setDate(endDate.getDate() + 30);

    // Update subscription
    photographer.subscription = {
      plan,
      startDate,
      endDate,
      isActive: true,
    };

    await photographer.save();

    logger.info(`Photographer subscribed to ${plan}: ${photographer._id}`);

    // TODO: Process payment (if not basic plan)

    res.status(200).json({
      success: true,
      message: 'Subscription activated successfully',
      data: {
        subscription: photographer.subscription,
        plan: PLANS[plan],
      },
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Cancel subscription
// @route   POST /api/subscriptions/cancel
// @access  Private (photographer)
exports.cancelSubscription = async (req, res, next) => {
  try {
    const photographer = await Photographer.findOne({ user: req.user._id });

    if (!photographer) {
      return res.status(404).json({
        success: false,
        message: 'Photographer profile not found',
      });
    }

    // Downgrade to basic
    photographer.subscription = {
      plan: 'basic',
      isActive: true,
    };

    await photographer.save();

    logger.info(`Subscription cancelled: ${photographer._id}`);

    res.status(200).json({
      success: true,
      message: 'Subscription cancelled, downgraded to Basic plan',
      data: photographer.subscription,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Request featured listing
// @route   POST /api/subscriptions/featured
// @access  Private (photographer with premium)
exports.requestFeatured = async (req, res, next) => {
  try {
    const photographer = await Photographer.findOne({ user: req.user._id });

    if (!photographer) {
      return res.status(404).json({
        success: false,
        message: 'Photographer profile not found',
      });
    }

    // Check if has premium subscription
    if (photographer.subscription.plan !== 'premium') {
      return res.status(403).json({
        success: false,
        message: 'Featured listing is only available for Premium subscribers',
      });
    }

    // Calculate end date (30 days from now)
    const startDate = new Date();
    const endDate = new Date();
    endDate.setDate(endDate.getDate() + 30);

    // Activate featured
    photographer.featured = {
      isActive: true,
      startDate,
      endDate,
    };

    await photographer.save();

    logger.info(`Featured listing activated: ${photographer._id}`);

    res.status(200).json({
      success: true,
      message: 'Featured listing activated',
      data: photographer.featured,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Check subscription status (Cron job)
// @route   Internal
exports.checkExpiredSubscriptions = async () => {
  try {
    const now = new Date();

    // Find expired subscriptions
    const expiredPhotographers = await Photographer.find({
      'subscription.endDate': { $lt: now },
      'subscription.isActive': true,
    });

    for (const photographer of expiredPhotographers) {
      // Downgrade to basic
      photographer.subscription = {
        plan: 'basic',
        isActive: true,
      };

      await photographer.save();

      logger.info(`Subscription expired, downgraded to basic: ${photographer._id}`);

      // TODO: Send notification
    }

    // Find expired featured listings
    const expiredFeatured = await Photographer.find({
      'featured.endDate': { $lt: now },
      'featured.isActive': true,
    });

    for (const photographer of expiredFeatured) {
      photographer.featured.isActive = false;
      await photographer.save();

      logger.info(`Featured listing expired: ${photographer._id}`);

      // TODO: Send notification
    }
  } catch (error) {
    logger.error(`Error checking expired subscriptions: ${error.message}`);
  }
};
