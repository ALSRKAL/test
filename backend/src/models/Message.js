const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema(
  {
    conversation: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Conversation',
      required: true,
      index: true,
    },
    sender: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    receiver: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    content: {
      type: String,
      required: [true, 'Message content is required'],
      maxlength: [2000, 'Message cannot be more than 2000 characters'],
      trim: true,
    },
    type: {
      type: String,
      enum: ['text', 'image', 'file', 'booking'],
      default: 'text',
    },
    attachment: {
      url: String,
      publicId: String,
      filename: String,
      size: Number,
      mimeType: String,
    },
    bookingReference: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Booking',
    },
    replyToMessageId: {
      type: String,
    },
    replyToMessageText: {
      type: String,
    },
    replyToSenderName: {
      type: String,
    },
    isRead: {
      type: Boolean,
      default: false,
      index: true,
    },
    readAt: Date,
    isDeleted: {
      type: Boolean,
      default: false,
    },
    deletedAt: Date,
  },
  {
    timestamps: true,
  }
);

// Indexes for performance
messageSchema.index({ conversation: 1, createdAt: -1 });
messageSchema.index({ sender: 1, receiver: 1, createdAt: -1 });
messageSchema.index({ receiver: 1, isRead: 1 });

// Virtual for formatted time
messageSchema.virtual('formattedTime').get(function () {
  return this.createdAt.toLocaleTimeString('ar-EG', {
    hour: '2-digit',
    minute: '2-digit'
  });
});

// Conversation Schema
const conversationSchema = new mongoose.Schema(
  {
    participants: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
      },
    ],
    participantDetails: {
      client: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
      },
      photographer: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
      },
    },
    lastMessage: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Message',
    },
    lastMessageText: String,
    lastMessageTime: Date,
    unreadCount: {
      type: Map,
      of: Number,
      default: {},
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    isBlocked: {
      type: Boolean,
      default: false,
    },
    blockedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
  },
  {
    timestamps: true,
  }
);

// Indexes for performance
conversationSchema.index({ participants: 1 });
conversationSchema.index({ 'participantDetails.client': 1 });
conversationSchema.index({ 'participantDetails.photographer': 1 });
conversationSchema.index({ updatedAt: -1 });

// Method to get unread count for a user
conversationSchema.methods.getUnreadCount = function (userId) {
  return this.unreadCount.get(userId.toString()) || 0;
};

// Method to increment unread count
conversationSchema.methods.incrementUnreadCount = async function (userId) {
  const currentCount = this.getUnreadCount(userId);
  this.unreadCount.set(userId.toString(), currentCount + 1);
  await this.save();
};

// Method to reset unread count
conversationSchema.methods.resetUnreadCount = async function (userId) {
  this.unreadCount.set(userId.toString(), 0);
  await this.save();
};

// Static method to find or create conversation
conversationSchema.statics.findOrCreate = async function (user1Id, user2Id) {
  let conversation = await this.findOne({
    participants: { $all: [user1Id, user2Id] },
  })
    .populate('participants', 'name avatar role')
    .populate('lastMessage');

  if (!conversation) {
    // Determine who is client and who is photographer
    const User = mongoose.model('User');
    const user1 = await User.findById(user1Id);
    const user2 = await User.findById(user2Id);

    const participantDetails = {};
    if (user1.role === 'photographer') {
      participantDetails.photographer = user1Id;
      participantDetails.client = user2Id;
    } else {
      participantDetails.client = user1Id;
      participantDetails.photographer = user2Id;
    }

    conversation = await this.create({
      participants: [user1Id, user2Id],
      participantDetails,
      unreadCount: new Map([
        [user1Id.toString(), 0],
        [user2Id.toString(), 0],
      ]),
    });

    conversation = await conversation.populate('participants', 'name avatar role');
  }

  return conversation;
};

const Message = mongoose.model('Message', messageSchema);
const Conversation = mongoose.model('Conversation', conversationSchema);

module.exports = { Message, Conversation };
