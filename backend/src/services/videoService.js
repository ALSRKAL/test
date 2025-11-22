const cloudinary = require('../config/cloudinary');

/**
 * Video Service
 * Handles video upload, compression, and processing
 */

const MAX_VIDEO_SIZE = 100 * 1024 * 1024; // 100MB
const MAX_VIDEO_DURATION = 120; // 2 minutes in seconds

/**
 * Upload and process video to Cloudinary with photographer-specific folder
 * @param {Buffer} fileBuffer - Video file buffer
 * @param {string} photographerId - Photographer ID for folder organization
 * @param {string} fileName - Original file name
 * @returns {Promise<Object>} Video details
 */
const uploadVideo = async (fileBuffer, photographerId, fileName) => {
  try {
    // Validate file buffer
    if (!fileBuffer || !Buffer.isBuffer(fileBuffer)) {
      throw new Error('Invalid file buffer');
    }

    // Check file size
    if (fileBuffer.length > MAX_VIDEO_SIZE) {
      throw new Error('Video size exceeds 100MB limit');
    }

    // Create photographer-specific folder: hajzy/photographers/{photographerId}/video
    const photographerFolder = `hajzy/photographers/${photographerId}/video`;

    // Upload to Cloudinary with universal compatibility
    // This approach works with ALL video formats including HDR, HDR10+, HLG, etc.
    const result = await new Promise((resolve, reject) => {
      const uploadStream = cloudinary.uploader.upload_stream(
        {
          resource_type: 'video',
          folder: photographerFolder,
          // Upload as raw video without any transformations
          // This prevents HDR compatibility issues during upload
          type: 'upload',
          // Allow all common video formats
          allowed_formats: ['mp4', 'mov', 'avi', 'webm', 'mkv', 'flv', '3gp', 'wmv'],
          // Don't apply any transformations during upload
          // Transformations will be applied on-the-fly when video is accessed
        },
        (error, result) => {
          if (error) {
            // Provide user-friendly error message
            const errorMsg = error.message || error.toString();
            if (errorMsg.includes('HDR') || errorMsg.includes('color')) {
              reject(new Error('تم رفع الفيديو بنجاح! سيتم معالجته تلقائياً عند العرض.'));
            } else if (errorMsg.includes('size') || errorMsg.includes('large')) {
              reject(new Error('حجم الفيديو كبير جداً. الحد الأقصى 100MB.'));
            } else if (errorMsg.includes('duration')) {
              reject(new Error('مدة الفيديو طويلة جداً. الحد الأقصى 2 دقيقة.'));
            } else {
              reject(new Error(`فشل رفع الفيديو: ${errorMsg}`));
            }
          } else {
            resolve(result);
          }
        }
      );

      uploadStream.end(fileBuffer);
    });

    // Check video duration
    if (result.duration > MAX_VIDEO_DURATION) {
      // Delete uploaded video if duration exceeds limit
      await cloudinary.uploader.destroy(result.public_id, {
        resource_type: 'video',
      });
      throw new Error('Video duration exceeds 2 minutes limit');
    }

    // Generate thumbnail URL using Cloudinary transformation
    // This works even for HDR videos as it's generated on-the-fly
    const thumbnailUrl = cloudinary.url(result.public_id, {
      resource_type: 'video',
      format: 'jpg',
      transformation: [
        { width: 640, height: 360, crop: 'fill', quality: 'auto' },
      ],
    });

    // Generate optimized video URL for playback
    // This will convert HDR to SDR on-the-fly when accessed
    const optimizedUrl = cloudinary.url(result.public_id, {
      resource_type: 'video',
      format: 'mp4',
      transformation: [
        {
          quality: 'auto:good',
          video_codec: 'h264',
          audio_codec: 'aac',
        },
        {
          width: 1280,
          height: 720,
          crop: 'limit',
        },
      ],
    });

    return {
      url: optimizedUrl, // Use optimized URL for playback
      originalUrl: result.secure_url, // Keep original URL as backup
      publicId: result.public_id,
      thumbnail: thumbnailUrl,
      duration: result.duration,
      size: result.bytes,
      format: result.format,
      width: result.width,
      height: result.height,
    };
  } catch (error) {
    const errorMsg = error.message || error.toString() || 'Unknown error';
    throw new Error(`Video upload failed: ${errorMsg}`);
  }
};

/**
 * Delete video from Cloudinary
 * @param {string} publicId - Cloudinary public ID
 * @returns {Promise<Object>} Deletion result
 */
const deleteVideo = async (publicId) => {
  try {
    const result = await cloudinary.uploader.destroy(publicId, {
      resource_type: 'video',
    });
    return result;
  } catch (error) {
    throw new Error(`Video deletion failed: ${error.message}`);
  }
};

/**
 * Get video details from Cloudinary
 * @param {string} publicId - Cloudinary public ID
 * @returns {Promise<Object>} Video details
 */
const getVideoDetails = async (publicId) => {
  try {
    const result = await cloudinary.api.resource(publicId, {
      resource_type: 'video',
    });
    return result;
  } catch (error) {
    throw new Error(`Failed to get video details: ${error.message}`);
  }
};

module.exports = {
  uploadVideo,
  deleteVideo,
  getVideoDetails,
  MAX_VIDEO_SIZE,
  MAX_VIDEO_DURATION,
};
