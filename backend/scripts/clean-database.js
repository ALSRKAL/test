const mongoose = require('mongoose');
const path = require('path');
const readline = require('readline');
const User = require('../src/models/User');
const Photographer = require('../src/models/Photographer');
const Booking = require('../src/models/Booking');
const Review = require('../src/models/Review');
const { Message, Conversation } = require('../src/models/Message');

// Load .env
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

// Connect to MongoDB
const connectDB = async () => {
  try {
    const mongoUri = process.env.MONGODB_URI || process.env.MONGO_URI;
    if (!mongoUri) {
      console.error('❌ MONGODB_URI not found in .env file');
      process.exit(1);
    }
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(mongoUri);
    console.log('✅ MongoDB connected\n');
  } catch (error) {
    console.error('❌ MongoDB connection error:', error);
    process.exit(1);
  }
};

// Ask for confirmation
const askConfirmation = () => {
  return new Promise((resolve) => {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });

    rl.question('⚠️  Are you sure you want to delete ALL test data? (yes/no): ', (answer) => {
      rl.close();
      resolve(answer.toLowerCase() === 'yes');
    });
  });
};

// Clean database
const cleanDatabase = async () => {
  try {
    console.log('🧹 Starting database cleanup...\n');

    // Count before deletion
    const counts = {
      users: await User.countDocuments({ email: { $regex: /@test\.com$/ } }),
      photographers: await Photographer.countDocuments(),
      bookings: await Booking.countDocuments(),
      reviews: await Review.countDocuments(),
      conversations: await Conversation.countDocuments(),
      messages: await Message.countDocuments()
    };

    console.log('📊 Current database status:');
    console.log(`   Users (test): ${counts.users}`);
    console.log(`   Photographers: ${counts.photographers}`);
    console.log(`   Bookings: ${counts.bookings}`);
    console.log(`   Reviews: ${counts.reviews}`);
    console.log(`   Conversations: ${counts.conversations}`);
    console.log(`   Messages: ${counts.messages}\n`);

    // Ask for confirmation
    const confirmed = await askConfirmation();
    
    if (!confirmed) {
      console.log('\n❌ Cleanup cancelled by user');
      return;
    }

    console.log('\n🗑️  Deleting data...\n');

    // Delete in correct order (respecting foreign keys)
    
    // 1. Delete messages
    const deletedMessages = await Message.deleteMany({});
    console.log(`✅ Deleted ${deletedMessages.deletedCount} messages`);

    // 2. Delete conversations
    const deletedConversations = await Conversation.deleteMany({});
    console.log(`✅ Deleted ${deletedConversations.deletedCount} conversations`);

    // 3. Delete reviews
    const deletedReviews = await Review.deleteMany({});
    console.log(`✅ Deleted ${deletedReviews.deletedCount} reviews`);

    // 4. Delete bookings
    const deletedBookings = await Booking.deleteMany({});
    console.log(`✅ Deleted ${deletedBookings.deletedCount} bookings`);

    // 5. Delete photographers
    const deletedPhotographers = await Photographer.deleteMany({});
    console.log(`✅ Deleted ${deletedPhotographers.deletedCount} photographers`);

    // 6. Delete test users (only those with @test.com email)
    const deletedUsers = await User.deleteMany({ 
      email: { $regex: /@test\.com$/ } 
    });
    console.log(`✅ Deleted ${deletedUsers.deletedCount} test users`);

    // Summary
    console.log('\n═══════════════════════════════════════');
    console.log('🎉 Database cleanup completed!');
    console.log('═══════════════════════════════════════');
    console.log(`🗑️  Total items deleted: ${
      deletedMessages.deletedCount +
      deletedConversations.deletedCount +
      deletedReviews.deletedCount +
      deletedBookings.deletedCount +
      deletedPhotographers.deletedCount +
      deletedUsers.deletedCount
    }`);
    console.log('═══════════════════════════════════════\n');

    // Verify cleanup
    const afterCounts = {
      users: await User.countDocuments({ email: { $regex: /@test\.com$/ } }),
      photographers: await Photographer.countDocuments(),
      bookings: await Booking.countDocuments(),
      reviews: await Review.countDocuments(),
      conversations: await Conversation.countDocuments(),
      messages: await Message.countDocuments()
    };

    console.log('📊 Database status after cleanup:');
    console.log(`   Users (test): ${afterCounts.users}`);
    console.log(`   Photographers: ${afterCounts.photographers}`);
    console.log(`   Bookings: ${afterCounts.bookings}`);
    console.log(`   Reviews: ${afterCounts.reviews}`);
    console.log(`   Conversations: ${afterCounts.conversations}`);
    console.log(`   Messages: ${afterCounts.messages}\n`);

  } catch (error) {
    console.error('❌ Error cleaning database:', error);
    throw error;
  }
};

// Run
const run = async () => {
  await connectDB();
  await cleanDatabase();
  await mongoose.connection.close();
  console.log('👋 Database connection closed');
  process.exit(0);
};

run();
