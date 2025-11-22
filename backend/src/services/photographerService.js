const Photographer = require('../models/Photographer');
const User = require('../models/User');
const logger = require('../utils/logger');

/**
 * Get photographers with filters and pagination
 */
exports.getPhotographers = async (filters, pagination) => {
  const {
    city,
    specialty,
    minRating,
    featured,
    sort = '-rating.average -rating.count -createdAt', // الترتيب: الأعلى تقييماً ثم الأكثر تقييمات ثم الأحدث
  } = filters;

  const { page = 1, limit = 10 } = pagination;

  // Build query
  const query = {};

  if (city) query['location.city'] = city;
  if (specialty) query.specialties = specialty;
  if (minRating) query['rating.average'] = { $gte: parseFloat(minRating) };
  if (featured === 'true') query['featured.isActive'] = true;

  // Execute query with pagination
  const photographers = await Photographer.find(query)
    .populate('user', 'name email avatar')
    .sort(sort)
    .limit(limit * 1)
    .skip((page - 1) * limit);

  const count = await Photographer.countDocuments(query);

  return {
    photographers,
    pagination: {
      page: parseInt(page),
      limit: parseInt(limit),
      total: count,
      pages: Math.ceil(count / limit),
    },
  };
};

/**
 * Get photographer by ID
 */
exports.getPhotographerById = async (id, viewerId = null) => {
  const photographer = await Photographer.findById(id)
    .populate('user', 'name email avatar phone');

  if (!photographer) {
    return null;
  }

  // Increment views if viewer is unique and not the owner
  if (viewerId && viewerId.toString() !== photographer.user._id.toString()) {
    const hasViewed = photographer.stats.viewedBy.includes(viewerId);

    if (!hasViewed) {
      photographer.stats.views += 1;
      photographer.stats.viewedBy.push(viewerId);
      await photographer.save();
    }
  } else if (!viewerId) {
    // Optional: Increment for anonymous views if desired, but user requested "each user"
    // For now, we only track logged-in users as per request "each user sees their record"
    // If we want to track anonymous views, we'd need IP tracking which is more complex
  }

  return photographer;
};

/**
 * Get photographer profile by user ID
 */
exports.getPhotographerByUserId = async (userId) => {
  return await Photographer.findOne({ user: userId })
    .populate('user', 'name email avatar phone');
};

/**
 * Create photographer profile
 */
exports.createPhotographerProfile = async (userId, profileData) => {
  const { bio, specialties, location, startingPrice, currency } = profileData;

  // Check if photographer profile already exists
  const existingProfile = await Photographer.findOne({ user: userId });
  if (existingProfile) {
    throw new Error('Photographer profile already exists');
  }

  // Create photographer profile
  const photographer = await Photographer.create({
    user: userId,
    bio,
    specialties,
    location,
    startingPrice,
    currency,
  });

  logger.info(`Photographer profile created: ${userId}`);

  return photographer;
};

/**
 * Update photographer profile
 */
exports.updatePhotographerProfile = async (photographerId, userId, updateData) => {
  const { bio, specialties, location, startingPrice, currency } = updateData;

  let photographer = await Photographer.findById(photographerId);

  if (!photographer) {
    throw new Error('Photographer not found');
  }

  // Check ownership
  if (photographer.user.toString() !== userId.toString()) {
    throw new Error('Not authorized to update this profile');
  }

  // Update fields
  if (bio !== undefined) photographer.bio = bio;
  if (specialties) photographer.specialties = specialties;
  if (startingPrice !== undefined) photographer.startingPrice = startingPrice;
  if (currency) photographer.currency = currency;
  if (location) {
    if (location.city) photographer.location.city = location.city;
    if (location.area) photographer.location.area = location.area;
  }

  await photographer.save();

  logger.info(`Photographer profile updated: ${photographerId}`);

  return photographer;
};

/**
 * Update photographer availability
 */
exports.updateAvailability = async (userId, blockedDates) => {
  const photographer = await Photographer.findOne({ user: userId });

  if (!photographer) {
    throw new Error('Photographer profile not found');
  }

  // Update blocked dates
  photographer.availability.blockedDates = blockedDates.map(date => new Date(date));
  await photographer.save();

  logger.info(`Photographer availability updated: ${photographer._id}`);

  return photographer;
};

/**
 * Search photographers
 */
/**
 * Search photographers
 */
exports.searchPhotographers = async (searchParams) => {
  const { q, city, specialty } = searchParams;

  const pipeline = [];

  // 1. Lookup User to get name and other details
  pipeline.push({
    $lookup: {
      from: 'users',
      localField: 'user',
      foreignField: '_id',
      as: 'user',
    },
  });

  // 2. Unwind user array
  pipeline.push({
    $unwind: '$user',
  });

  // 3. Build Match Stage
  const matchStage = {};

  if (q && q.trim()) {
    const searchTerm = q.trim();

    // Normalize search term for Arabic
    // Remove diacritics and normalize alef, ya, ha
    const normalizeText = (text) => {
      return text
        .replace(/[ًٌٍَُِّْ]/g, '')
        .replace(/[أإآ]/g, 'ا')
        .replace(/[ىي]/g, 'ي')
        .replace(/ة/g, 'ه');
    };

    const normalizedSearch = normalizeText(searchTerm);
    const regexPattern = new RegExp(normalizedSearch, 'i'); // Case insensitive

    // We can't use the simple regex for Arabic normalization in MongoDB directly without text index or complex regex
    // So we will use a broad regex that tries to match. 
    // Ideally, we should store a normalized version of the text in the DB, but for now we'll use $or

    // Note: For better Arabic search, we should ideally normalize the fields in the DB too.
    // Since we can't easily change the DB schema right now, we'll rely on regex.
    // A common trick is to replace the variable characters in the regex with character classes.
    // e.g. 'ا' becomes '[اأإآ]', 'ي' becomes '[يى]', 'ه' becomes '[هة]'

    const createFlexibleRegex = (text) => {
      let pattern = text
        .replace(/[ًٌٍَُِّْ]/g, '') // Remove diacritics
        .replace(/[أإآا]/g, '[أإآا]')
        .replace(/[ىي]/g, '[ىي]')
        .replace(/[ةه]/g, '[ةه]');
      return new RegExp(pattern, 'i');
    };

    const flexibleRegex = createFlexibleRegex(searchTerm);

    matchStage.$or = [
      { 'user.name': flexibleRegex },
      { bio: flexibleRegex },
      { 'location.city': flexibleRegex },
      { 'location.area': flexibleRegex },
      { specialties: flexibleRegex },
    ];
  }

  if (city) {
    matchStage['location.city'] = city;
  }

  if (specialty) {
    matchStage.specialties = specialty;
  }

  if (Object.keys(matchStage).length > 0) {
    pipeline.push({ $match: matchStage });
  }

  // 4. Sort by rating
  pipeline.push({
    $sort: {
      'rating.average': -1,
      'rating.count': -1,
    },
  });

  // 5. Limit results
  pipeline.push({ $limit: 50 });

  // 6. Project fields (optional, but good for performance and security)
  // We need to keep the structure expected by the frontend (User populated)
  // Since we unwound 'user', it is now an object, which matches what populate does (mostly)
  // But we should ensure we don't leak sensitive user info if any
  pipeline.push({
    $project: {
      user: {
        _id: 1,
        name: 1,
        email: 1,
        avatar: 1,
      },
      bio: 1,
      specialties: 1,
      location: 1,
      portfolio: 1,
      packages: 1,
      rating: 1,
      subscription: 1,
      featured: 1,
      verification: 1,
      availability: 1,
      stats: 1,
      startingPrice: 1,
      currency: 1,
      createdAt: 1,
      updatedAt: 1,
    },
  });

  const photographers = await Photographer.aggregate(pipeline);

  return photographers;
};

/**
 * Get featured photographers
 */
exports.getFeaturedPhotographers = async () => {
  return await Photographer.find({
    'featured.isActive': true,
    'featured.endDate': { $gte: new Date() },
  })
    .populate('user', 'name email avatar')
    .sort('-rating.average -rating.count') // الترتيب حسب التقييم
    .limit(10);
};
