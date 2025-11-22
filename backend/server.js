const express = require('express');
const dotenv = require('dotenv');

// Load environment variables FIRST
dotenv.config();

const cors = require('cors');
const helmet = require('helmet');
const mongoSanitize = require('express-mongo-sanitize');
const xss = require('xss-clean');
const http = require('http');
const socketIO = require('socket.io');
const cron = require('node-cron');
const cleanupService = require('./src/services/cleanupService');

// Schedule daily cleanup task (runs at 3:00 AM)
cron.schedule('0 3 * * *', () => {
  cleanupService.cleanupOrphanedMedia();
});

// Import configurations
const connectDB = require('./src/config/database');
const logger = require('./src/utils/logger');
const errorHandler = require('./src/middleware/error.middleware');

// Import routes
const authRoutes = require('./src/routes/auth.routes');
const userRoutes = require('./src/routes/user.routes');
const photographerRoutes = require('./src/routes/photographer.routes');
const bookingRoutes = require('./src/routes/booking.routes');
const reviewRoutes = require('./src/routes/review.routes');
const chatRoutes = require('./src/routes/chat.routes');
const mediaRoutes = require('./src/routes/media.routes');
const subscriptionRoutes = require('./src/routes/subscription.routes');
const verificationRoutes = require('./src/routes/verification.routes');
const adminRoutes = require('./src/routes/admin.routes');
const notificationRoutes = require('./src/routes/notification.routes');

// Initialize express app
const app = express();

// Trust proxy for Cloudflare
app.set('trust proxy', true);

// Create HTTP server
const server = http.createServer(app);

// Initialize Socket.IO
const io = socketIO(server, {
  cors: {
    origin: process.env.FRONTEND_URL ? process.env.FRONTEND_URL.split(',') : ['http://localhost:3000', 'http://localhost:5173', 'http://localhost:5174'],
    methods: ['GET', 'POST'],
  },
});

// Make io accessible to routes
app.set('io', io);

// Connect to database
connectDB();

// Security middleware
app.use(helmet());
app.use(cors({
  origin: process.env.FRONTEND_URL ? process.env.FRONTEND_URL.split(',') : ['http://localhost:3000', 'http://localhost:5173', 'http://localhost:5174'],
  credentials: true,
}));
app.use(mongoSanitize());
app.use(xss());

// Body parser middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Logging middleware
app.use((req, res, next) => {
  logger.info(`${req.method} ${req.path}`);
  next();
});

// Health check routes
app.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Server is running',
    timestamp: new Date().toISOString(),
  });
});

app.get('/api/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'API is healthy',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV,
  });
});

// API routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/photographers', photographerRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/media', mediaRoutes);
app.use('/api/subscriptions', subscriptionRoutes);
app.use('/api/verification', verificationRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/notifications', notificationRoutes);

// Socket.IO connection handler
require('./src/socket/socketHandler')(io);
require('./src/utils/notificationEmitter').setIo(io);

// Error handling middleware (must be last)
app.use(errorHandler);

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found',
  });
});

// Start server
const PORT = process.env.PORT || 5000;
server.listen(PORT, () => {
  logger.info(`Server running in ${process.env.NODE_ENV} mode on port ${PORT}`);
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (err) => {
  logger.error(`Unhandled Rejection: ${err.message}`);
  server.close(() => process.exit(1));
});

// Handle uncaught exceptions
process.on('uncaughtException', (err) => {
  logger.error(`Uncaught Exception: ${err.message}`);
  process.exit(1);
});

module.exports = app;
