const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Admin = require('../models/Admin');

// Protect routes - verify JWT token
exports.protect = async (req, res, next) => {
  try {
    let token;

    // Check for token in headers
    if (
      req.headers.authorization &&
      req.headers.authorization.startsWith('Bearer')
    ) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Not authorized to access this route',
      });
    }

    try {
      // Verify token
      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      // Get user from token (support both id and userId)
      const userId = decoded.userId || decoded.id;
      req.user = await User.findById(userId).select('-password');

      if (!req.user) {
        return res.status(401).json({
          success: false,
          message: 'User not found',
        });
      }

      // Check if user is blocked
      if (req.user.isBlocked) {
        return res.status(403).json({
          success: false,
          message: 'Your account has been blocked',
        });
      }

      next();
    } catch (error) {
      return res.status(401).json({
        success: false,
        message: 'Invalid or expired token',
      });
    }
  } catch (error) {
    next(error);
  }
};

// Grant access to specific roles
exports.authorize = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: `User role '${req.user.role}' is not authorized to access this route`,
      });
    }
    next();
  };
};

// Admin only middleware
exports.adminOnly = async (req, res, next) => {
  try {
    let token;

    // Check for token in headers
    if (
      req.headers.authorization &&
      req.headers.authorization.startsWith('Bearer')
    ) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Not authorized - Admin access required',
      });
    }

    try {
      // Verify token
      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      // Get user from token (support both id and userId)
      const userId = decoded.userId || decoded.id;

      // For admin routes, check if user is admin
      const user = await User.findById(userId).select('-password');

      if (!user) {
        return res.status(401).json({
          success: false,
          message: 'User not found',
        });
      }

      // Check if user is admin
      if (user.role !== 'admin' && user.role !== 'superadmin') {
        console.log(`Admin access denied: User ${user.email} has role ${user.role}`);
        return res.status(403).json({
          success: false,
          message: 'Admin access required',
        });
      }

      // Check if user is blocked
      if (user.isBlocked) {
        console.log(`Admin access denied: User ${user.email} is blocked`);
        return res.status(403).json({
          success: false,
          message: 'Account is blocked',
        });
      }

      req.user = user;
      next();
    } catch (error) {
      return res.status(401).json({
        success: false,
        message: 'Invalid or expired token',
      });
    }
  } catch (error) {
    next(error);
  }
};

// Super Admin only middleware
exports.superAdminOnly = async (req, res, next) => {
  if (req.user.role !== 'superadmin') {
    return res.status(403).json({
      success: false,
      message: 'Super Admin access required',
    });
  }
  next();
};
