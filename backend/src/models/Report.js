const mongoose = require('mongoose');

const reportSchema = new mongoose.Schema({
    reporter: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
    },
    reportedUser: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
    },
    reportedItem: {
        type: mongoose.Schema.Types.ObjectId,
        refPath: 'itemModel',
    },
    itemModel: {
        type: String,
        enum: ['Booking', 'Review', 'Photographer'],
    },
    reason: {
        type: String,
        required: true,
        trim: true,
    },
    description: {
        type: String,
        trim: true,
    },
    status: {
        type: String,
        enum: ['pending', 'resolved', 'dismissed'],
        default: 'pending',
    },
    resolution: {
        type: String,
        trim: true,
    },
    resolvedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
    },
    resolvedAt: {
        type: Date,
    },
}, {
    timestamps: true,
});

module.exports = mongoose.model('Report', reportSchema);
