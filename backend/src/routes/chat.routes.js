const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chatController');
const { protect } = require('../middleware/auth.middleware');

// All routes are protected
router.use(protect);

// Unread count - must be before dynamic routes
router.get('/unread-count', chatController.getUnreadCount);

// Search - must be before dynamic routes
router.get('/search', chatController.searchMessages);

// Conversations
router.post('/conversations', chatController.getOrCreateConversation);
router.get('/conversations', chatController.getConversations);
router.get('/conversations/:conversationId', chatController.getConversation);
router.get('/conversations/:conversationId/messages', chatController.getMessages);
router.put('/conversations/:conversationId/read', chatController.markAsRead);

// Messages
router.post('/messages', chatController.sendMessage);
router.delete('/messages/:messageId', chatController.deleteMessage);

module.exports = router;
