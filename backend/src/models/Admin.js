const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const adminSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Please provide a name'],
      trim: true,
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
    password: {
      type: String,
      required: [true, 'Please provide a password'],
      minlength: 8,
      select: false,
    },
    role: {
      type: String,
      enum: ['super_admin', 'moderator'],
      default: 'moderator',
    },
    permissions: {
      users: {
        view: { type: Boolean, default: true },
        edit: { type: Boolean, default: false },
        delete: { type: Boolean, default: false },
      },
      photographers: {
        view: { type: Boolean, default: true },
        approve: { type: Boolean, default: true },
        edit: { type: Boolean, default: false },
        delete: { type: Boolean, default: false },
      },
      bookings: {
        view: { type: Boolean, default: true },
        edit: { type: Boolean, default: false },
        delete: { type: Boolean, default: false },
      },
      content: {
        moderate: { type: Boolean, default: true },
        delete: { type: Boolean, default: false },
      },
      revenue: {
        view: { type: Boolean, default: false },
        edit: { type: Boolean, default: false },
      },
      settings: {
        view: { type: Boolean, default: false },
        edit: { type: Boolean, default: false },
      },
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    lastLogin: Date,
    activityLog: [
      {
        action: String,
        details: String,
        timestamp: {
          type: Date,
          default: Date.now,
        },
      },
    ],
  },
  {
    timestamps: true,
  }
);

// Hash password before saving
adminSchema.pre('save', async function (next) {
  if (!this.isModified('password')) {
    return next();
  }

  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

// Compare password
adminSchema.methods.comparePassword = async function (enteredPassword) {
  return await bcrypt.compare(enteredPassword, this.password);
};

// Log activity
adminSchema.methods.logActivity = function (action, details) {
  this.activityLog.push({ action, details });
  return this.save();
};

module.exports = mongoose.model('Admin', adminSchema);
