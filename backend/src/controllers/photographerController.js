const photographerService = require('../services/photographerService');
const packageService = require('../services/photographerPackageService');
const favoriteService = require('../services/photographerFavoriteService');
const User = require('../models/User');
const logger = require('../utils/logger');

// @desc    Get all photographers
// @route   GET /api/photographers
// @access  Public
exports.getPhotographers = async (req, res, next) => {
  try {
    const filters = {
      city: req.query.city,
      specialty: req.query.specialty,
      minRating: req.query.minRating,
      featured: req.query.featured,
      sort: req.query.sort,
    };

    const pagination = {
      page: req.query.page || 1,
      limit: req.query.limit || 10,
    };

    const result = await photographerService.getPhotographers(filters, pagination);

    res.status(200).json({
      success: true,
      data: result.photographers,
      pagination: result.pagination,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get photographer by ID
// @route   GET /api/photographers/:id
// @access  Public
exports.getPhotographerById = async (req, res, next) => {
  try {
    const viewerId = req.user ? req.user._id : null;
    const photographer = await photographerService.getPhotographerById(req.params.id, viewerId);

    if (!photographer) {
      return res.status(404).json({
        success: false,
        message: 'Photographer not found',
      });
    }

    res.status(200).json({
      success: true,
      data: photographer,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get current user's photographer profile
// @route   GET /api/photographers/me/profile
// @access  Private (photographer role)
exports.getMyPhotographerProfile = async (req, res, next) => {
  try {
    const photographer = await photographerService.getPhotographerByUserId(req.user._id);

    if (!photographer) {
      return res.status(404).json({
        success: false,
        message: 'Photographer profile not found. Please create your profile first.',
      });
    }

    res.status(200).json({
      success: true,
      data: photographer,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Create photographer profile
// @route   POST /api/photographers
// @access  Private (photographer role)
exports.createPhotographerProfile = async (req, res, next) => {
  try {
    const { bio, specialties, location } = req.body;

    const photographer = await photographerService.createPhotographerProfile(
      req.user._id,
      { bio, specialties, location }
    );

    // Update user role
    req.user.role = 'photographer';
    await req.user.save();

    logger.info(`Photographer profile created: ${req.user.email}`);

    res.status(201).json({
      success: true,
      message: 'Photographer profile created successfully',
      data: photographer,
    });
  } catch (error) {
    if (error.message === 'Photographer profile already exists') {
      return res.status(400).json({
        success: false,
        message: error.message,
      });
    }
    next(error);
  }
};

// @desc    Update photographer profile
// @route   PUT /api/photographers/:id
// @access  Private (photographer owner)
exports.updatePhotographerProfile = async (req, res, next) => {
  try {
    const { bio, specialties, location } = req.body;

    const photographer = await photographerService.updatePhotographerProfile(
      req.params.id,
      req.user._id,
      { bio, specialties, location }
    );

    res.status(200).json({
      success: true,
      message: 'Profile updated successfully',
      data: photographer,
    });
  } catch (error) {
    if (error.message === 'Photographer not found') {
      return res.status(404).json({
        success: false,
        message: error.message,
      });
    }
    if (error.message === 'Not authorized to update this profile') {
      return res.status(403).json({
        success: false,
        message: error.message,
      });
    }
    next(error);
  }
};

// @desc    Update photographer profile (me)
// @route   PUT /api/photographers/me/profile
// @access  Private (photographer role)
exports.updateMyPhotographerProfile = async (req, res, next) => {
  try {
    const { bio, specialties, location, startingPrice, currency } = req.body;
    console.log('📸 DEBUG: updateMyPhotographerProfile called');
    console.log('User ID:', req.user._id);

    let photographer = await photographerService.getPhotographerByUserId(req.user._id);
    console.log('📸 DEBUG: Photographer found?', photographer ? 'Yes' : 'No');

    if (!photographer) {
      console.log('📸 DEBUG: Profile not found, creating new one...');
      // If profile not found, create it (Upsert)
      const newPhotographer = await photographerService.createPhotographerProfile(
        req.user._id,
        { bio, specialties, location, startingPrice, currency }
      );

      // Update user role
      req.user.role = 'photographer';
      await req.user.save();

      console.log('📸 DEBUG: Profile created successfully');
      return res.status(200).json({
        success: true,
        message: 'Profile created successfully',
        data: newPhotographer,
      });
    }

    console.log('📸 DEBUG: Profile found, updating directly...', photographer._id);

    // Update fields directly on the document
    if (bio !== undefined) photographer.bio = bio;
    if (specialties) photographer.specialties = specialties;
    if (startingPrice !== undefined) photographer.startingPrice = startingPrice;
    if (currency) photographer.currency = currency;
    if (location) {
      if (location.city) photographer.location.city = location.city;
      if (location.area) photographer.location.area = location.area;
    }

    await photographer.save();

    console.log('📸 DEBUG: Profile updated successfully');
    res.status(200).json({
      success: true,
      message: 'Profile updated successfully',
      data: photographer,
    });
  } catch (error) {
    console.error('📸 DEBUG: Error in updateMyPhotographerProfile:', error);
    next(error);
  }
};

// @desc    Update photographer availability (blocked dates)
// @route   PUT /api/photographers/me/availability
// @access  Private (photographer role)
exports.updateAvailability = async (req, res, next) => {
  try {
    const { blockedDates } = req.body;

    const photographer = await photographerService.updateAvailability(
      req.user._id,
      blockedDates
    );

    res.status(200).json({
      success: true,
      message: 'Availability updated successfully',
      data: photographer,
    });
  } catch (error) {
    if (error.message === 'Photographer profile not found') {
      return res.status(404).json({
        success: false,
        message: error.message,
      });
    }
    next(error);
  }
};

// @desc    Add package
// @route   POST /api/photographers/:id/packages
// @access  Private (photographer owner)
exports.addPackage = async (req, res, next) => {
  try {
    const { name, price, duration, features } = req.body;

    const packages = await packageService.addPackage(
      req.params.id,
      req.user._id,
      { name, price, duration, features }
    );

    res.status(201).json({
      success: true,
      message: 'Package added successfully',
      data: packages,
    });
  } catch (error) {
    if (error.message === 'Photographer not found') {
      return res.status(404).json({
        success: false,
        message: error.message,
      });
    }
    if (error.message === 'Not authorized') {
      return res.status(403).json({
        success: false,
        message: error.message,
      });
    }
    next(error);
  }
};

// @desc    Update package
// @route   PUT /api/photographers/:id/packages/:packageId
// @access  Private (photographer owner)
exports.updatePackage = async (req, res, next) => {
  try {
    const { name, price, duration, features, isActive } = req.body;

    const packages = await packageService.updatePackage(
      req.params.id,
      req.params.packageId,
      req.user._id,
      { name, price, duration, features, isActive }
    );

    res.status(200).json({
      success: true,
      message: 'Package updated successfully',
      data: packages,
    });
  } catch (error) {
    if (error.message === 'Photographer not found' || error.message === 'Package not found') {
      return res.status(404).json({
        success: false,
        message: error.message,
      });
    }
    if (error.message === 'Not authorized') {
      return res.status(403).json({
        success: false,
        message: error.message,
      });
    }
    next(error);
  }
};

// @desc    Delete package
// @route   DELETE /api/photographers/:id/packages/:packageId
// @access  Private (photographer owner)
exports.deletePackage = async (req, res, next) => {
  try {
    await packageService.deletePackage(
      req.params.id,
      req.params.packageId,
      req.user._id
    );

    res.status(200).json({
      success: true,
      message: 'Package deleted successfully',
    });
  } catch (error) {
    if (error.message === 'Photographer not found') {
      return res.status(404).json({
        success: false,
        message: error.message,
      });
    }
    if (error.message === 'Not authorized') {
      return res.status(403).json({
        success: false,
        message: error.message,
      });
    }
    next(error);
  }
};

// @desc    Search photographers
// @route   GET /api/photographers/search
// @access  Public
exports.searchPhotographers = async (req, res, next) => {
  try {
    const { q, city, specialty } = req.query;

    const photographers = await photographerService.searchPhotographers({
      q,
      city,
      specialty,
    });

    res.status(200).json({
      success: true,
      count: photographers.length,
      data: photographers,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get featured photographers
// @route   GET /api/photographers/featured
// @access  Public
exports.getFeaturedPhotographers = async (req, res, next) => {
  try {
    const photographers = await photographerService.getFeaturedPhotographers();

    res.status(200).json({
      success: true,
      data: photographers,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Add photographer to favorites
// @route   POST /api/photographers/:id/favorite
// @access  Private
exports.addToFavorites = async (req, res, next) => {
  try {
    const favorites = await favoriteService.addToFavorites(
      req.params.id,
      req.user._id,
      req.user.name,
      req.user.avatar
    );

    res.status(200).json({
      success: true,
      message: 'Added to favorites',
      data: favorites,
    });
  } catch (error) {
    if (error.message === 'Photographer not found') {
      return res.status(404).json({
        success: false,
        message: error.message,
      });
    }
    if (error.message === 'Photographer already in favorites') {
      return res.status(400).json({
        success: false,
        message: error.message,
      });
    }
    next(error);
  }
};

// @desc    Remove photographer from favorites
// @route   DELETE /api/photographers/:id/favorite
// @access  Private
exports.removeFromFavorites = async (req, res, next) => {
  try {
    const favorites = await favoriteService.removeFromFavorites(
      req.params.id,
      req.user._id
    );

    res.status(200).json({
      success: true,
      message: 'Removed from favorites',
      data: favorites,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get user's favorite photographers
// @route   GET /api/photographers/favorites
// @access  Private
exports.getFavorites = async (req, res, next) => {
  try {
    const favorites = await favoriteService.getFavorites(req.user._id);

    res.status(200).json({
      success: true,
      data: favorites,
    });
  } catch (error) {
    next(error);
  }
};
