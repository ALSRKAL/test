const multer = require('multer');
const path = require('path');

// Configure multer storage (memory storage for Cloudinary upload)
// Using memory storage because we upload directly to Cloudinary using buffers
const storage = multer.memoryStorage();

// File filter
const fileFilter = (req, file, cb) => {
  // Allowed image types
  const imageTypes = /jpeg|jpg|png|gif|webp/;
  // Allowed video types
  const videoTypes = /mp4|mov|avi|mkv/;

  const extname = path.extname(file.originalname).toLowerCase();
  const mimetype = file.mimetype;

  if (file.fieldname === 'image' || file.fieldname === 'images' || file.fieldname === 'avatar') {
    // Check image
    if (
      imageTypes.test(extname.slice(1)) &&
      mimetype.startsWith('image/')
    ) {
      return cb(null, true);
    }
    return cb(new Error('Only image files are allowed'));
  }

  if (file.fieldname === 'video') {
    // Check video
    if (
      videoTypes.test(extname.slice(1)) &&
      mimetype.startsWith('video/')
    ) {
      return cb(null, true);
    }
    return cb(new Error('Only video files are allowed'));
  }

  cb(new Error('Invalid file field'));
};

// Upload configurations
const uploadImage = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB
  },
}).single('image');

const uploadAvatar = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB
  },
}).single('avatar');

const uploadImages = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB per file
  },
}).array('images', 20); // Max 20 images

const uploadVideo = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: 100 * 1024 * 1024, // 100MB
  },
}).single('video');

// Error handler for multer
const handleMulterError = (err, req, res, next) => {
  if (err instanceof multer.MulterError) {
    if (err.code === 'LIMIT_FILE_SIZE') {
      return res.status(400).json({
        success: false,
        message: 'File size too large',
      });
    }
    if (err.code === 'LIMIT_FILE_COUNT') {
      return res.status(400).json({
        success: false,
        message: 'Too many files',
      });
    }
    return res.status(400).json({
      success: false,
      message: err.message,
    });
  }

  if (err) {
    return res.status(400).json({
      success: false,
      message: err.message,
    });
  }

  next();
};

// Generic single file upload
const uploadSingle = (fieldName) => multer({
  storage,
  fileFilter,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB
  },
}).single(fieldName);

module.exports = {
  uploadImage,
  uploadAvatar,
  uploadImages,
  uploadVideo,
  uploadSingle,
  handleMulterError,
};
