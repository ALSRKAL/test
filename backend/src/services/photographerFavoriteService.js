const Photographer = require('../models/Photographer');
const User = require('../models/User');
const logger = require('../utils/logger');
const notificationService = require('./notificationService');

/**
 * Add photographer to favorites
 */
exports.addToFavorites = async (photographerId, userId, userName, userAvatar) => {
  const photographer = await Photographer.findById(photographerId);

  if (!photographer) {
    throw new Error('Photographer not found');
  }

  const user = await User.findById(userId);

  if (user.favorites.includes(photographerId)) {
    throw new Error('Photographer already in favorites');
  }

  user.favorites.push(photographerId);
  await user.save();

  // Populate photographer details
  await photographer.populate('user', 'name avatar');

  // Send notification to photographer
  try {
    logger.info(`🔍 Sending favorite notification to photographer ${photographer.user._id}`);
    
    await notificationService.sendNewFavoriteNotification(
      photographer.user._id.toString(),
      {
        clientName: userName,
        clientAvatar: userAvatar,
        photographerName: photographer.user.name,
      }
    );
    
    logger.info(`✅ Favorite notification sent successfully`);
  } catch (notifError) {
    logger.error(`❌ Failed to send favorite notification: ${notifError.message}`);
    logger.error(`Error stack: ${notifError.stack}`);
  }

  return user.favorites;
};

/**
 * Remove photographer from favorites
 */
exports.removeFromFavorites = async (photographerId, userId) => {
  const user = await User.findById(userId);

  user.favorites = user.favorites.filter(
    (fav) => fav.toString() !== photographerId
  );
  await user.save();

  return user.favorites;
};

/**
 * Get user's favorite photographers
 */
exports.getFavorites = async (userId) => {
  const user = await User.findById(userId).populate({
    path: 'favorites',
    populate: {
      path: 'user',
      select: 'name email avatar',
    },
  });

  return user.favorites;
};
