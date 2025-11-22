const rateLimit = require('express-rate-limit');

// General rate limiter 
const generalLimiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
  message: {
    success: false,
    message: 'Too many requests, please try again later',
  },
  standardHeaders: true,
  legacyHeaders: false,
  validate: { trustProxy: false },
});

// Strict rate limiter for auth routes
// DISABLED FOR DEVELOPMENT - Enable in production!
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 1000, // Increased to 1000 for development (was 5)
  message: {
    success: false,
    message: 'Too many login attempts, please try again after 15 minutes',
  },
  skipSuccessfulRequests: true,
  validate: { trustProxy: false },
});

// Upload rate limiter
// INCREASED FOR DEVELOPMENT - Adjust in production!
const uploadLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 20, // Increased to 200 for development (was 20)
  message: {
    success: false,
    message: 'Too many uploads, please try again later',
  },
  validate: { trustProxy: false },
});

module.exports = {
  generalLimiter,
  authLimiter,
  uploadLimiter,
};
