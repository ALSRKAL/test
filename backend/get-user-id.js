require('dotenv').config();
const mongoose = require('mongoose');

async function getUserId() {
  try {
    // الاتصال بقاعدة البيانات
    const mongoUri = process.env.MONGODB_URI || process.env.MONGO_URI;
    if (!mongoUri) {
      throw new Error('MONGODB_URI is not defined in environment variables');
    }
    await mongoose.connect(mongoUri);
    console.log('✅ Connected to MongoDB\n');

    // الحصول على جميع المستخدمين
    const User = mongoose.model('User', new mongoose.Schema({}, { strict: false }));
    const users = await User.find({}).select('_id name email role').limit(10);

    console.log('📋 Users in database:\n');
    users.forEach((user, index) => {
      console.log(`${index + 1}. Name: ${user.name}`);
      console.log(`   Email: ${user.email}`);
      console.log(`   Role: ${user.role}`);
      console.log(`   ID: ${user._id}`);
      console.log('');
    });

    console.log('💡 Copy one of the IDs above and use it in test-chat-notification.js');
    console.log('   Replace USER_ID_HERE with the actual ID');

    await mongoose.connection.close();
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

getUserId();
