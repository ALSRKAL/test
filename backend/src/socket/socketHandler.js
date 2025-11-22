const logger = require('../utils/logger');
const { Message, Conversation } = require('../models/Message');

const onlineUsers = new Map();

module.exports = (io) => {
  io.on('connection', (socket) => {
    logger.info(`Socket connected: ${socket.id}`);

    socket.on('test_connection', (data) => {
      logger.info(`🧪 test_connection event received from client`);
      logger.info(`   Data: ${JSON.stringify(data)}`);
      logger.info(`   Socket ID: ${socket.id}`);
      
      // Send test response back
      socket.emit('test_response', {
        message: 'Connection test successful',
        serverTime: new Date().toISOString(),
        socketId: socket.id,
      });
      
      logger.info(`✅ Test response sent back to client`);
    });

    socket.on('user_connected', async (userId) => {
      try {
        logger.info(`📥 user_connected event received`);
        logger.info(`   User ID: ${userId}`);
        logger.info(`   Socket ID: ${socket.id}`);
        
        socket.userId = userId;
        socket.join(`user_${userId}`);
        onlineUsers.set(userId, socket.id);

        logger.info(`✅ User ${userId} joined room: user_${userId}`);
        logger.info(`   Online users count: ${onlineUsers.size}`);
        
        // Send a test event to verify the room connection
        io.to(`user_${userId}`).emit('connection_confirmed', {
          message: 'You are now connected to real-time updates',
          userId: userId,
          timestamp: new Date().toISOString(),
        });
        logger.info(`📤 Sent connection_confirmed event to user_${userId}`);

        // Load conversations in background (don't block connection)
        setImmediate(async () => {
          try {
            const conversations = await Conversation.find({
              participants: userId,
            }).lean().maxTimeMS(5000); // 5 second timeout

            conversations.forEach(conv => {
              const otherParticipant = conv.participants.find(
                p => p.toString() !== userId
              );
              if (otherParticipant) {
                io.to(`user_${otherParticipant}`).emit('user_online', {
                  userId,
                  conversationId: conv._id,
                });
              }
            });

            logger.info(`✅ User ${userId} online status sent to conversations`);
          } catch (convError) {
            logger.error(`⚠️ Error loading conversations for user ${userId}:`, convError.message);
            // Don't fail the connection if conversations fail to load
          }
        });

        logger.info(`✅ User ${userId} connected and joined room user_${userId}`);
      } catch (error) {
        logger.error('❌ Error in user_connected:', error);
      }
    });

    socket.on('join_conversation', (conversationId) => {
      socket.join(`conversation_${conversationId}`);
      logger.info(`Socket ${socket.id} joined conversation ${conversationId}`);
    });

    socket.on('leave_conversation', (conversationId) => {
      socket.leave(`conversation_${conversationId}`);
      logger.info(`Socket ${socket.id} left conversation ${conversationId}`);
    });

    socket.on('send_message', async (data) => {
      try {
        const { conversationId, receiverId, content, type, senderId } = data;

        if (!conversationId || !receiverId || !content || !senderId) {
          socket.emit('message_error', { error: 'Missing required fields' });
          return;
        }

        const message = await Message.create({
          conversation: conversationId,
          sender: senderId,
          receiver: receiverId,
          content: content.trim(),
          type: type || 'text',
        });

        await message.populate('sender', 'name avatar role');

        await Conversation.findByIdAndUpdate(conversationId, {
          lastMessage: message._id,
          lastMessageText: content.substring(0, 100),
          lastMessageTime: message.createdAt,
        });

        const conversation = await Conversation.findById(conversationId);
        if (conversation) {
          await conversation.incrementUnreadCount(receiverId);
        }

        // Send to receiver's personal room
        io.to(`user_${receiverId}`).emit('new_message', {
          ...message.toObject(),
          conversationId,
        });

        // IMPORTANT: Broadcast to conversation room (excluding sender)
        // This ensures the receiver sees the message immediately
        // while avoiding duplicate for the sender (who already has optimistic update)
        socket.broadcast.to(`conversation_${conversationId}`).emit('new_message', {
          ...message.toObject(),
          conversationId,
        });

        socket.emit('message_sent_success', { messageId: message._id });

        logger.info(`Message sent via socket to conversation ${conversationId}: ${message._id}`);
      } catch (error) {
        logger.error('Error in send_message:', error);
        socket.emit('message_error', { error: error.message });
      }
    });

    socket.on('typing_start', (data) => {
      const { conversationId, userId, userName } = data;
      socket.to(`conversation_${conversationId}`).emit('user_typing', {
        userId,
        userName,
        conversationId,
      });
    });

    socket.on('typing_stop', (data) => {
      const { conversationId, userId } = data;
      socket.to(`conversation_${conversationId}`).emit('user_stop_typing', {
        userId,
        conversationId,
      });
    });

    socket.on('mark_as_read', async (data) => {
      try {
        const { conversationId, userId } = data;

        await Message.updateMany(
          {
            conversation: conversationId,
            receiver: userId,
            isRead: false,
          },
          {
            $set: {
              isRead: true,
              readAt: new Date(),
            },
          }
        );

        const conversation = await Conversation.findById(conversationId);
        if (conversation) {
          await conversation.resetUnreadCount(userId);

          const otherParticipant = conversation.participants.find(
            p => p.toString() !== userId
          );
          if (otherParticipant) {
            io.to(`user_${otherParticipant}`).emit('messages_read', {
              conversationId,
              readBy: userId,
            });
          }
        }

        socket.emit('mark_as_read_success', { conversationId });
      } catch (error) {
        logger.error('Error in mark_as_read:', error);
        socket.emit('mark_as_read_error', { error: error.message });
      }
    });

    socket.on('delete_message', async (data) => {
      try {
        const { messageId, userId } = data;

        const message = await Message.findById(messageId);
        if (!message) {
          socket.emit('delete_message_error', { error: 'Message not found' });
          return;
        }

        if (message.sender.toString() !== userId) {
          socket.emit('delete_message_error', { error: 'Not authorized' });
          return;
        }

        message.isDeleted = true;
        message.deletedAt = new Date();
        await message.save();

        io.to(`conversation_${message.conversation}`).emit('message_deleted', {
          messageId: message._id,
          conversationId: message.conversation,
        });

        socket.emit('delete_message_success', { messageId });
      } catch (error) {
        logger.error('Error in delete_message:', error);
        socket.emit('delete_message_error', { error: error.message });
      }
    });

    socket.on('check_online_status', (userId) => {
      const isOnline = onlineUsers.has(userId);
      socket.emit('online_status_response', { userId, isOnline });
    });

    // Booking events
    socket.on('join_bookings_room', (userId) => {
      socket.join(`bookings_${userId}`);
      logger.info(`Socket ${socket.id} joined bookings room for user ${userId}`);
    });

    socket.on('leave_bookings_room', (userId) => {
      socket.leave(`bookings_${userId}`);
      logger.info(`Socket ${socket.id} left bookings room for user ${userId}`);
    });

    socket.on('disconnect', async () => {
      try {
        if (socket.userId) {
          onlineUsers.delete(socket.userId);

          const conversations = await Conversation.find({
            participants: socket.userId,
          }).lean();

          conversations.forEach(conv => {
            const otherParticipant = conv.participants.find(
              p => p.toString() !== socket.userId
            );
            if (otherParticipant) {
              io.to(`user_${otherParticipant}`).emit('user_offline', {
                userId: socket.userId,
                conversationId: conv._id,
              });
            }
          });

          logger.info(`User ${socket.userId} disconnected`);
        }
        logger.info(`Socket disconnected: ${socket.id}`);
      } catch (error) {
        logger.error('Error in disconnect:', error);
      }
    });

    socket.on('error', (error) => {
      logger.error(`Socket error: ${error}`);
    });
  });

  return {
    getOnlineUsers: () => Array.from(onlineUsers.keys()),
    isUserOnline: (userId) => onlineUsers.has(userId),
  };
};
