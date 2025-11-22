const mongoose = require('mongoose');

const reviewSchema = new mongoose.Schema(
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
    booking: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Booking',
      required: true,
    },
    rating: {
      type: Number,
      required: [true, 'Please provide a rating'],
      min: 1,
      max: 5,
    },
    comment: {
      type: String,
      required: [true, 'Please provide a comment'],
      maxlength: [500, 'Comment cannot be more than 500 characters'],
    },
    reply: {
      text: String,
      repliedAt: Date,
    },
    isReported: {
      type: Boolean,
      default: false,
    },
    reportReason: String,
  },
  {
    timestamps: true,
  }
);

// Indexes
reviewSchema.index({ photographer: 1, createdAt: -1 });
reviewSchema.index({ client: 1 });
reviewSchema.index({ rating: -1 });

// Prevent duplicate reviews for same booking
reviewSchema.index({ client: 1, booking: 1 }, { unique: true });

// Update photographer rating after review is saved
reviewSchema.post('save', async function () {
  const Photographer = mongoose.model('Photographer');
  
  const stats = await this.constructor.aggregate([
    { $match: { photographer: this.photographer } },
    {
      $group: {
        _id: '$photographer',
        averageRating: { $avg: '$rating' },
        count: { $sum: 1 },
      },
    },
  ]);

  if (stats.length > 0) {
    await Photographer.findByIdAndUpdate(this.photographer, {
      'rating.average': Math.round(stats[0].averageRating * 10) / 10,
      'rating.count': stats[0].count,
    });
  }
});

module.exports = mongoose.model('Review', reviewSchema);
