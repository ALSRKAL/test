const cloudinary = require('cloudinary').v2;
const logger = require('../utils/logger');

// Configure Cloudinary
const config = {
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
};

// Log config for debugging (without exposing secret)
logger.info(`Cloudinary Config: cloud_name=${config.cloud_name}, api_key=${config.api_key ? 'SET' : 'MISSING'}, api_secret=${config.api_secret ? 'SET' : 'MISSING'}`);

cloudinary.config(config);

// Test connection
const testConnection = async () => {
  try {
    await cloudinary.api.ping();
    logger.info('✅ Cloudinary connected successfully');
  } catch (error) {
    logger.error(`❌ Cloudinary connection error: ${error.message}`);
  }
};

testConnection();

module.exports = cloudinary;
