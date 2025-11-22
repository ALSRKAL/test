const { Message, Conversation } = require('../models/Message');
const User = require('../models/User');
const logger = require('../utils/logger');
const mongoose = require('mongoose');

// @desc    Get or create conversation
// @route   POST /api/chat/conversations
// @access  Private
exports.getOrCreateConversation = async (req, res, next) => {
  try {
    const { participantId } = req.body;

    if (!participantId) {
      return res.status(400).json({
        success: false,
        message: 'Participant ID is required',
      });
    }

    // Validate ObjectId format
    if (!mongoose.Types.ObjectId.isValid(participantId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid participant ID format',
      });
    }

    // Validate participant exists
    const participant = await User.findById(participantId);
    if (!participant) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    // Check if trying to chat with self
    if (participantId === req.user._id.toString()) {
      return res.status(400).json({
        success: false,
        message: 'Cannot create conversation with yourself',
      });
    }

    // Use static method to find or create
    const conversation = await Conversation.findOrCreate(
      req.user._id,
      participantId
    );

    // Get other participant info
    const otherParticipant = conversation.participants.find(
      p => p._id.toString() !== req.user._id.toString()
    );

    // Format response with proper unreadCount
    const conversationData = conversation.toObject();
    conversationData.unreadCount = conversation.getUnreadCount(req.user._id);
    conversationData.otherParticipant = otherParticipant;

    res.status(200).json({
      success: true,
      data: conversationData,
    });
  } catch (error) {
    logger.error('Error in getOrCreateConversation:', error);

    // Handle cast errors specifically
    if (error.name === 'CastError') {
      return res.status(400).json({
        success: false,
        message: 'Invalid ID format',
      });
    }

    next(error);
  }
};

// @desc    Get user conversations
// @route   GET /api/chat/conversations
// @access  Private
exports.getConversations = async (req, res, next) => {
  try {
    const conversations = await Conversation.find({
      participants: req.user._id,
      isActive: true,
    })
      .populate('participants', 'name avatar role phoneNumber')
      .populate({
        path: 'lastMessage',
        select: 'content type createdAt sender',
      })
      .sort('-updatedAt')
      .lean();

    // Format conversations with additional info
    const formattedConversations = conversations.map(conv => {
      const otherParticipant = conv.participants.find(
        p => p._id.toString() !== req.user._id.toString()
      );

      return {
        ...conv,
        otherParticipant,
        unreadCount: conv.unreadCount?.get?.(req.user._id.toString()) || 0,
      };
    });

    res.status(200).json({
      success: true,
      count: formattedConversations.length,
      data: formattedConversations,
    });
  } catch (error) {
    logger.error('Error in getConversations:', error);
    next(error);
  }
};

// @desc    Get conversation by ID
// @route   GET /api/chat/conversations/:conversationId
// @access  Private
exports.getConversation = async (req, res, next) => {
  try {
    const { conversationId } = req.params;

    const conversation = await Conversation.findById(conversationId)
      .populate('participants', 'name avatar role phoneNumber')
      .populate('lastMessage');

    if (!conversation) {
      return res.status(404).json({
        success: false,
        message: 'Conversation not found',
      });
    }

    // Check if user is participant
    if (!conversation.participants.some(p => p._id.toString() === req.user._id.toString())) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to access this conversation',
      });
    }

    const otherParticipant = conversation.participants.find(
      p => p._id.toString() !== req.user._id.toString()
    );

    res.status(200).json({
      success: true,
      data: {
        ...conversation.toObject(),
        otherParticipant,
        unreadCount: conversation.getUnreadCount(req.user._id),
      },
    });
  } catch (error) {
    logger.error('Error in getConversation:', error);
    next(error);
  }
};

// @desc    Get conversation messages
// @route   GET /api/chat/conversations/:conversationId/messages
// @access  Private
exports.getMessages = async (req, res, next) => {
  try {
    const { conversationId } = req.params;
    const { page = 1, limit = 50 } = req.query;

    // Check if user is participant
    const conversation = await Conversation.findById(conversationId);
    if (!conversation) {
      return res.status(404).json({
        success: false,
        message: 'Conversation not found',
      });
    }

    if (!conversation.participants.some(p => p._id.toString() === req.user._id.toString())) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to access this conversation',
      });
    }

    const messages = await Message.find({
      conversation: conversationId,
      isDeleted: false,
    })
      .populate('sender', 'name avatar role')
      .populate('receiver', 'name avatar role')
      .sort('-createdAt')
      .limit(limit * 1)
      .skip((page - 1) * limit)
      .lean();

    const count = await Message.countDocuments({
      conversation: conversationId,
      isDeleted: false,
    });

    // Mark messages as read
    await Message.updateMany(
      {
        conversation: conversationId,
        receiver: req.user._id,
        isRead: false,
      },
      {
        $set: {
          isRead: true,
          readAt: new Date(),
        },
      }
    );

    // Reset unread count for this user
    await conversation.resetUnreadCount(req.user._id);

    // Emit read receipt via socket
    const io = req.app.get('io');
    const otherParticipant = conversation.participants.find(
      p => p._id.toString() !== req.user._id.toString()
    );
    if (otherParticipant) {
      // Send to other participant's personal room
      io.to(`user_${otherParticipant}`).emit('messages_read', {
        conversationId,
        readBy: req.user._id,
      });

      // Also send to conversation room for real-time updates
      io.to(`conversation_${conversationId}`).emit('messages_read', {
        conversationId,
        readBy: req.user._id,
      });

      logger.info(`📖 Messages read in conversation ${conversationId} by ${req.user._id} (from getMessages)`);
    }

    res.status(200).json({
      success: true,
      data: messages.reverse(),
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: count,
        pages: Math.ceil(count / limit),
      },
    });
  } catch (error) {
    logger.error('Error in getMessages:', error);
    next(error);
  }
};

// @desc    Send message
// @route   POST /api/chat/messages
// @access  Private
exports.sendMessage = async (req, res, next) => {
  try {
    const {
      conversationId,
      receiverId,
      content,
      type,
      attachment,
      bookingReference,
      replyToMessageId,
      replyToMessageText,
      replyToSenderName
    } = req.body;

    if (!conversationId || !receiverId || !content) {
      return res.status(400).json({
        success: false,
        message: 'Conversation ID, receiver ID, and content are required',
      });
    }

    // Verify conversation exists and user is participant
    const conversation = await Conversation.findById(conversationId);
    if (!conversation) {
      return res.status(404).json({
        success: false,
        message: 'Conversation not found',
      });
    }

    if (!conversation.participants.some(p => p._id.toString() === req.user._id.toString())) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized',
      });
    }

    // Create message
    const message = await Message.create({
      conversation: conversationId,
      sender: req.user._id,
      receiver: receiverId,
      content: content.trim(),
      type: type || 'text',
      attachment,
      bookingReference,
      replyToMessageId,
      replyToMessageText,
      replyToSenderName,
    });

    // Update conversation
    await Conversation.findByIdAndUpdate(conversationId, {
      lastMessage: message._id,
      lastMessageText: content.substring(0, 100),
      lastMessageTime: message.createdAt,
    });

    // Increment unread count for receiver
    await conversation.incrementUnreadCount(receiverId);

    // Populate sender info
    await message.populate('sender', 'name avatar role');
    await message.populate('receiver', 'name avatar role');

    // Emit socket event
    const io = req.app.get('io');

    // Send to receiver's personal room
    io.to(`user_${receiverId}`).emit('new_message', {
      ...message.toObject(),
      conversationId,
    });

    // Send to conversation room (only to receiver, not sender)
    // Sender already has the message via optimistic update
    // Note: We can't use broadcast here since this is HTTP request, not socket
    // So we just send to receiver's room which is sufficient
    // The conversation room listener is mainly for socket-based sends

    // Send push notification to receiver
    try {
      const notificationService = require('../services/notificationService');
      const receiver = await User.findById(receiverId);

      logger.info(`🔍 Attempting to send chat notification:`);
      logger.info(`  - Receiver ID: ${receiverId}`);
      logger.info(`  - Receiver found: ${!!receiver}`);
      logger.info(`  - Receiver name: ${receiver?.name}`);
      logger.info(`  - Sender ID: ${req.user._id}`);
      logger.info(`  - Sender name: ${req.user.name}`);
      logger.info(`  - Message content: ${content.substring(0, 50)}...`);

      if (receiver) {
        // Send notification using external user ID (more reliable than player ID)
        await notificationService.sendNewMessageNotification(
          receiverId.toString(), // Convert to string to ensure compatibility
          {
            name: req.user.name,
            avatar: req.user.avatar,
            _id: req.user._id,
          },
          {
            content: content,
            conversationId: conversationId,
            type: type || 'text',
          }
        );
        logger.info(`✅ Push notification sent successfully to ${receiver.name}`);
      } else {
        logger.warn(`⚠️ Receiver not found in database: ${receiverId}`);
      }
    } catch (notifError) {
      logger.error('❌ Failed to send push notification:', notifError.message);
      logger.error('Error stack:', notifError.stack);
      // Don't fail the request if notification fails
    }

    logger.info(`Message sent: ${message._id} from ${req.user._id} to ${receiverId}`);

    res.status(201).json({
      success: true,
      data: message,
    });
  } catch (error) {
    logger.error('Error in sendMessage:', error);
    next(error);
  }
};

// @desc    Delete message
// @route   DELETE /api/chat/messages/:messageId
// @access  Private
exports.deleteMessage = async (req, res, next) => {
  try {
    logger.info(`🗑️ Delete message request: ${req.params.messageId} by user: ${req.user._id}`);

    const message = await Message.findById(req.params.messageId);

    if (!message) {
      logger.warn(`❌ Message not found: ${req.params.messageId}`);
      return res.status(404).json({
        success: false,
        message: 'Message not found',
      });
    }

    logger.info(`📝 Message found. Sender: ${message.sender}, Current user: ${req.user._id}`);

    // Check if user is sender
    if (message.sender.toString() !== req.user._id.toString()) {
      logger.warn(`❌ Unauthorized delete attempt by user: ${req.user._id}`);
      return res.status(403).json({
        success: false,
        message: 'Not authorized to delete this message',
      });
    }

    // Store conversation ID before deleting
    const conversationId = message.conversation;

    // Hard delete - remove from database permanently
    await Message.findByIdAndDelete(req.params.messageId);

    logger.info(`✅ Message permanently deleted: ${req.params.messageId}`);

    // Update conversation's last message if this was the last message
    const lastMessage = await Message.findOne({ conversation: conversationId })
      .sort({ createdAt: -1 })
      .select('_id content createdAt');

    if (lastMessage) {
      await Conversation.findByIdAndUpdate(conversationId, {
        lastMessage: lastMessage._id,
        lastMessageText: lastMessage.content,
        lastMessageTime: lastMessage.createdAt,
      });
      logger.info(`✅ Updated conversation with new last message`);
    } else {
      // No messages left, clear last message
      await Conversation.findByIdAndUpdate(conversationId, {
        lastMessage: null,
        lastMessageText: null,
        lastMessageTime: null,
      });
      logger.info(`✅ Cleared conversation last message (no messages left)`);
    }

    // Emit socket event
    const io = req.app.get('io');
    if (io) {
      io.to(`conversation_${conversationId}`).emit('message_deleted', {
        messageId: req.params.messageId,
        conversationId: conversationId,
      });
      logger.info(`📡 Socket event emitted for conversation: ${conversationId}`);
    }

    res.status(200).json({
      success: true,
      message: 'Message deleted permanently',
    });
  } catch (error) {
    logger.error('❌ Error in deleteMessage:', error);
    next(error);
  }
};

// @desc    Mark messages as read
// @route   PUT /api/chat/conversations/:conversationId/read
// @access  Private
exports.markAsRead = async (req, res, next) => {
  try {
    const { conversationId } = req.params;

    const conversation = await Conversation.findById(conversationId);
    if (!conversation) {
      return res.status(404).json({
        success: false,
        message: 'Conversation not found',
      });
    }

    // Mark all unread messages as read
    await Message.updateMany(
      {
        conversation: conversationId,
        receiver: req.user._id,
        isRead: false,
      },
      {
        $set: {
          isRead: true,
          readAt: new Date(),
        },
      }
    );

    // Reset unread count
    await conversation.resetUnreadCount(req.user._id);

    // Emit socket event
    const io = req.app.get('io');
    const otherParticipant = conversation.participants.find(
      p => p._id.toString() !== req.user._id.toString()
    );
    if (otherParticipant) {
      // Send to other participant's personal room
      io.to(`user_${otherParticipant}`).emit('messages_read', {
        conversationId,
        readBy: req.user._id,
      });

      // Also send to conversation room for real-time updates
      io.to(`conversation_${conversationId}`).emit('messages_read', {
        conversationId,
        readBy: req.user._id,
      });

      logger.info(`📖 Messages marked as read in conversation ${conversationId} by ${req.user._id}`);
    }

    res.status(200).json({
      success: true,
      message: 'Messages marked as read',
    });
  } catch (error) {
    logger.error('Error in markAsRead:', error);
    next(error);
  }
};

// @desc    Get unread count
// @route   GET /api/chat/unread-count
// @access  Private
exports.getUnreadCount = async (req, res, next) => {
  try {
    const count = await Message.countDocuments({
      receiver: req.user._id,
      isRead: false,
      isDeleted: false,
    });

    // Get unread count per conversation
    const conversations = await Conversation.find({
      participants: req.user._id,
    }).lean();

    const conversationCounts = conversations.map(conv => ({
      conversationId: conv._id,
      unreadCount: conv.unreadCount?.get?.(req.user._id.toString()) || 0,
    })).filter(c => c.unreadCount > 0);

    res.status(200).json({
      success: true,
      data: {
        totalUnread: count,
        conversations: conversationCounts,
      },
    });
  } catch (error) {
    logger.error('Error in getUnreadCount:', error);
    next(error);
  }
};

// @desc    Search messages
// @route   GET /api/chat/search
// @access  Private
exports.searchMessages = async (req, res, next) => {
  try {
    const { query, conversationId } = req.query;

    if (!query) {
      return res.status(400).json({
        success: false,
        message: 'Search query is required',
      });
    }

    const searchFilter = {
      content: { $regex: query, $options: 'i' },
      isDeleted: false,
      $or: [
        { sender: req.user._id },
        { receiver: req.user._id },
      ],
    };

    if (conversationId) {
      searchFilter.conversation = conversationId;
    }

    const messages = await Message.find(searchFilter)
      .populate('sender', 'name avatar')
      .populate('conversation')
      .sort('-createdAt')
      .limit(50)
      .lean();

    res.status(200).json({
      success: true,
      count: messages.length,
      data: messages,
    });
  } catch (error) {
    logger.error('Error in searchMessages:', error);
    next(error);
  }
};
