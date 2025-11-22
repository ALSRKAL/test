const Photographer = require('../models/Photographer');
const logger = require('../utils/logger');

/**
 * Add package to photographer
 */
exports.addPackage = async (photographerId, userId, packageData) => {
  const { name, price, duration, features } = packageData;

  const photographer = await Photographer.findById(photographerId);

  if (!photographer) {
    throw new Error('Photographer not found');
  }

  // Check ownership
  if (photographer.user.toString() !== userId.toString()) {
    throw new Error('Not authorized');
  }

  photographer.packages.push({
    name,
    price,
    duration,
    features,
  });

  await photographer.save();

  logger.info(`Package added to photographer: ${photographerId}`);

  return photographer.packages;
};

/**
 * Update package
 */
exports.updatePackage = async (photographerId, packageId, userId, updateData) => {
  const { name, price, duration, features, isActive } = updateData;

  const photographer = await Photographer.findById(photographerId);

  if (!photographer) {
    throw new Error('Photographer not found');
  }

  // Check ownership
  if (photographer.user.toString() !== userId.toString()) {
    throw new Error('Not authorized');
  }

  const packageIndex = photographer.packages.findIndex(
    (pkg) => pkg._id.toString() === packageId
  );

  if (packageIndex === -1) {
    throw new Error('Package not found');
  }

  photographer.packages[packageIndex] = {
    ...photographer.packages[packageIndex].toObject(),
    name: name || photographer.packages[packageIndex].name,
    price: price || photographer.packages[packageIndex].price,
    duration: duration || photographer.packages[packageIndex].duration,
    features: features || photographer.packages[packageIndex].features,
    isActive: isActive !== undefined ? isActive : photographer.packages[packageIndex].isActive,
  };

  await photographer.save();

  logger.info(`Package updated for photographer: ${photographerId}`);

  return photographer.packages;
};

/**
 * Delete package
 */
exports.deletePackage = async (photographerId, packageId, userId) => {
  const photographer = await Photographer.findById(photographerId);

  if (!photographer) {
    throw new Error('Photographer not found');
  }

  // Check ownership
  if (photographer.user.toString() !== userId.toString()) {
    throw new Error('Not authorized');
  }

  photographer.packages = photographer.packages.filter(
    (pkg) => pkg._id.toString() !== packageId
  );

  await photographer.save();

  logger.info(`Package deleted from photographer: ${photographerId}`);

  return true;
};
