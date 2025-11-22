const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { protect } = require('../middleware/auth.middleware');
const { validate, schemas } = require('../middleware/validation.middleware');
const { authLimiter } = require('../middleware/rateLimit.middleware');

// Public routes
router.post(
  '/register',
  authLimiter,
  validate(schemas.register),
  authController.register
);

router.post(
  '/login',
  authLimiter,
  validate(schemas.login),
  authController.login
);

router.post('/refresh-token', authController.refreshToken);

// Password reset routes
router.post('/forgot-password', authLimiter, authController.forgotPassword);
router.post('/verify-reset-code', authLimiter, authController.verifyResetCode);
router.post('/reset-password', authLimiter, authController.resetPassword);

// Protected routes
router.post('/logout', protect, authController.logout);

module.exports = router;
