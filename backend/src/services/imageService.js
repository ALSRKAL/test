const cloudinary = require('../config/cloudinary');

/**
 * Image Service
 * Handles image upload, compression, and processing
 */

const MAX_IMAGES = 20;

/**
 * Upload image to Cloudinary with photographer-specific folder
 * @param {Buffer} fileBuffer - Image file buffer
 * @param {string} photographerId - Photographer ID for folder organization
 * @param {string} subfolder - Subfolder name (e.g., 'portfolio', 'profile', 'verification')
 * @returns {Promise<Object>} Image details
 */
const uploadImage = async (fileBuffer, photographerId, subfolder = 'portfolio') => {
  try {
    // Validate file buffer
    if (!fileBuffer || !Buffer.isBuffer(fileBuffer)) {
      throw new Error('Empty file');
    }

    // Create organized folder structure: hajzy/photographers/{photographerId}/{subfolder}
    const photographerFolder = `hajzy/photographers/${photographerId}/${subfolder}`;
    
    const result = await new Promise((resolve, reject) => {
      const uploadStream = cloudinary.uploader.upload_stream(
        {
          folder: photographerFolder,
          // Universal image upload settings - works with all formats
          quality: 'auto:good',
          fetch_format: 'auto',
          // Allow all common image formats
          allowed_formats: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'tiff', 'svg', 'heic', 'heif'],
          // Automatic format conversion for optimal delivery
          flags: 'progressive',
          // Limit size while maintaining quality
          transformation: [
            {
              width: 1920,
              height: 1080,
              crop: 'limit',
              quality: 'auto:good',
            },
          ],
        },
        (error, result) => {
          if (error) {
            const errorMsg = error.message || error.toString();
            if (errorMsg.includes('size') || errorMsg.includes('large')) {
              reject(new Error('حجم الصورة كبير جداً. الرجاء استخدام صورة أصغر.'));
            } else if (errorMsg.includes('format') || errorMsg.includes('type')) {
              reject(new Error('صيغة الصورة غير مدعومة. الرجاء استخدام JPG, PNG, أو WebP.'));
            } else {
              reject(error);
            }
          } else {
            resolve(result);
          }
        }
      );

      uploadStream.end(fileBuffer);
    });

    return {
      url: result.secure_url,
      publicId: result.public_id,
      width: result.width,
      height: result.height,
      format: result.format,
      size: result.bytes,
    };
  } catch (error) {
    const errorMsg = error.message || error.toString() || 'Unknown error';
    throw new Error(`Image upload failed: ${errorMsg}`);
  }
};

/**
 * Upload multiple images for a photographer
 * @param {Array<Buffer>} fileBuffers - Array of image file buffers
 * @param {string} photographerId - Photographer ID for folder organization
 * @param {string} subfolder - Subfolder name (e.g., 'portfolio', 'profile', 'verification')
 * @returns {Promise<Array>} Array of image details
 */
const uploadMultipleImages = async (fileBuffers, photographerId, subfolder = 'portfolio') => {
  try {
    if (fileBuffers.length > MAX_IMAGES) {
      throw new Error(`Maximum ${MAX_IMAGES} images allowed`);
    }

    const uploadPromises = fileBuffers.map((buffer) =>
      uploadImage(buffer, photographerId, subfolder)
    );

    const results = await Promise.all(uploadPromises);
    return results;
  } catch (error) {
    throw new Error(`Multiple images upload failed: ${error.message}`);
  }
};

/**
 * Delete image from Cloudinary
 * @param {string} publicId - Cloudinary public ID
 * @returns {Promise<Object>} Deletion result
 */
const deleteImage = async (publicId) => {
  try {
    const result = await cloudinary.uploader.destroy(publicId);
    return result;
  } catch (error) {
    throw new Error(`Image deletion failed: ${error.message}`);
  }
};

/**
 * Delete multiple images
 * @param {Array<string>} publicIds - Array of Cloudinary public IDs
 * @returns {Promise<Array>} Array of deletion results
 */
const deleteMultipleImages = async (publicIds) => {
  try {
    const deletePromises = publicIds.map((publicId) => deleteImage(publicId));
    const results = await Promise.all(deletePromises);
    return results;
  } catch (error) {
    throw new Error(`Multiple images deletion failed: ${error.message}`);
  }
};

module.exports = {
  uploadImage,
  uploadMultipleImages,
  deleteImage,
  deleteMultipleImages,
  MAX_IMAGES,
};
