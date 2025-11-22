const mongoose = require('mongoose');

const photographerSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true,
    },
    bio: {
      type: String,
      maxlength: [500, 'Bio cannot be more than 500 characters'],
    },
    startingPrice: {
      type: Number,
      min: [0, 'Starting price must be positive'],
    },
    currency: {
      type: String,
      enum: ['USD', 'YER', 'SAR'],
      default: 'YER',
    },
    specialties: [
      {
        type: String,
        enum: [
          'weddings',
          'events',
          'portraits',
          'children',
          'products',
          'fashion',
          'nature',
          'other',
        ],
      },
    ],
    location: {
      city: {
        type: String,
        required: [true, 'Please provide a city'],
      },
      area: {
        type: String,
        required: [true, 'Please provide an area'],
      },
    },
    portfolio: {
      images: [
        {
          url: String,
          publicId: String,
          uploadedAt: {
            type: Date,
            default: Date.now,
          },
        },
      ],
      video: {
        url: String,
        publicId: String,
        thumbnail: String,
        duration: Number,
        size: Number,
        uploadedAt: Date,
      },
    },
    packages: [
      {
        name: {
          type: String,
          required: true,
        },
        price: {
          type: Number,
          required: true,
        },
        duration: {
          type: String,
          required: true,
        },
        features: [String],
        isActive: {
          type: Boolean,
          default: true,
        },
      },
    ],
    rating: {
      average: {
        type: Number,
        default: 0,
        min: 0,
        max: 5,
      },
      count: {
        type: Number,
        default: 0,
      },
    },
    subscription: {
      plan: {
        type: String,
        enum: ['basic', 'pro', 'premium'],
        default: 'basic',
      },
      startDate: Date,
      endDate: Date,
      isActive: {
        type: Boolean,
        default: true,
      },
    },
    featured: {
      isActive: {
        type: Boolean,
        default: false,
      },
      startDate: Date,
      endDate: Date,
    },
    verification: {
      status: {
        type: String,
        enum: ['not_submitted', 'pending', 'approved', 'rejected'],
        default: 'not_submitted',
      },
      documents: {
        idCard: String,
        portfolioSamples: [String],
      },
      submittedAt: Date,
      reviewedAt: Date,
      reviewedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
      },
      rejectionReason: String,
    },
    availability: {
      blockedDates: [Date],
    },
    stats: {
      totalBookings: {
        type: Number,
        default: 0,
      },
      completedBookings: {
        type: Number,
        default: 0,
      },
      totalEarnings: {
        type: Number,
        default: 0,
      },
      views: {
        type: Number,
        default: 0,
      },
      viewedBy: [
        {
          type: mongoose.Schema.Types.ObjectId,
          ref: 'User',
        },
      ],
    },
  },
  {
    timestamps: true,
  }
);

// Indexes for better query performance
photographerSchema.index({ 'location.city': 1 });
photographerSchema.index({ specialties: 1 });
photographerSchema.index({ 'rating.average': -1 });
photographerSchema.index({ 'featured.isActive': 1 });

// Validate portfolio limits
photographerSchema.pre('save', function (next) {
  if (this.portfolio.images.length > 20) {
    return next(new Error('Maximum 20 images allowed in portfolio'));
  }
  next();
});

module.exports = mongoose.model('Photographer', photographerSchema);
