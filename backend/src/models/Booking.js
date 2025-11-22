const mongoose = require('mongoose');

const bookingSchema = new mongoose.Schema(
  {
    client: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    photographer: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Photographer',
      required: true,
    },
    package: {
      name: String,
      price: Number,
      duration: String,
      features: [String],
    },
    date: {
      type: Date,
      required: [true, 'Please provide a booking date'],
    },
    timeSlot: {
      type: String,
      required: [true, 'Please provide a booking time slot'],
    },
    location: {
      type: String,
      required: [true, 'Please provide a location'],
    },
    notes: {
      type: String,
      maxlength: [500, 'Notes cannot be more than 500 characters'],
    },
    status: {
      type: String,
      enum: ['pending', 'confirmed', 'completed', 'cancelled'],
      default: 'pending',
    },
    payment: {
      amount: {
        type: Number,
        required: true,
      },
      commission: {
        type: Number,
        default: 0,
      },
      status: {
        type: String,
        enum: ['pending', 'paid', 'refunded'],
        default: 'pending',
      },
      paidAt: Date,
    },
    cancellation: {
      cancelledBy: {
        type: String,
        enum: ['client', 'photographer', 'admin'],
      },
      reason: String,
      cancelledAt: Date,
    },
  },
  {
    timestamps: true,
  }
);

// Indexes
bookingSchema.index({ client: 1, createdAt: -1 });
bookingSchema.index({ photographer: 1, createdAt: -1 });
bookingSchema.index({ date: 1 });
bookingSchema.index({ status: 1 });

// Calculate commission before saving
bookingSchema.pre('save', function (next) {
  if (this.payment && this.payment.amount && !this.payment.commission) {
    const commissionRate = parseFloat(process.env.COMMISSION_RATE) || 0.1;
    this.payment.commission = this.payment.amount * commissionRate;
  }
  next();
});

module.exports = mongoose.model('Booking', bookingSchema);
