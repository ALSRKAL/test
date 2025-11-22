const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Please provide a name'],
      trim: true,
      maxlength: [50, 'Name cannot be more than 50 characters'],
    },
    email: {
      type: String,
      required: [true, 'Please provide an email'],
      unique: true,
      lowercase: true,
      match: [
        /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/,
        'Please provide a valid email',
      ],
    },
    phone: {
      type: String,
      required: [true, 'Please provide a phone number'],
      match: [
        /^((\+966|00966|966)?5[0-9]{8}|05[0-9]{8}|(\+967|00967|967)?[0-9]{9}|0[0-9]{9})$/,
        'Please provide a valid phone number',
      ],
    },
    password: {
      type: String,
      required: [true, 'Please provide a password'],
      minlength: [6, 'Password must be at least 6 characters'],
      select: false,
    },
    avatar: {
      type: String,
      default: null,
    },
    role: {
      type: String,
      enum: ['client', 'photographer', 'admin', 'superadmin', 'employee'],
      default: 'client',
    },
    permissions: [{
      type: String,
      enum: [
        'manage_users',
        'view_analytics',
        'manage_bookings',
        'manage_photographers',
        'manage_reviews',
        'manage_reports',
        'manage_subscriptions'
      ]
    }],
    isBlocked: {
      type: Boolean,
      default: false,
    },
    favorites: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Photographer',
      },
    ],
    refreshToken: {
      type: String,
      select: false,
    },
    oneSignalPlayerId: {
      type: String,
      default: null,
    },
    notificationSettings: {
      messages: {
        type: Boolean,
        default: true,
      },
      bookings: {
        type: Boolean,
        default: true,
      },
      reviews: {
        type: Boolean,
        default: true,
      },
    },
    resetPasswordToken: {
      type: String,
      select: false,
    },
    resetPasswordExpire: {
      type: Date,
      select: false,
    },
  },
  {
    timestamps: true,
  }
);

// Hash password before saving
userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) {
    return next();
  }

  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

// Compare password method
userSchema.methods.comparePassword = async function (candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

// Generate password reset token
userSchema.methods.getResetPasswordToken = function () {
  // Generate token
  const resetToken = Math.floor(100000 + Math.random() * 900000).toString();

  // Hash token and set to resetPasswordToken field
  const crypto = require('crypto');
  this.resetPasswordToken = crypto
    .createHash('sha256')
    .update(resetToken)
    .digest('hex');

  // Set expire (10 minutes)
  this.resetPasswordExpire = Date.now() + 10 * 60 * 1000;

  return resetToken;
};

// Remove sensitive data from JSON response
userSchema.methods.toJSON = function () {
  const user = this.toObject();
  delete user.password;
  delete user.refreshToken;
  delete user.resetPasswordToken;
  delete user.resetPasswordExpire;
  return user;
};

module.exports = mongoose.model('User', userSchema);
