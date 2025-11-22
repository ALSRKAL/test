const mongoose = require('mongoose');
require('dotenv').config();

const Photographer = require('./src/models/Photographer');

async function testAPI() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB\n');

    // Test different queries
    console.log('1️⃣ Testing: Find ALL photographers (no filter)');
    const all = await Photographer.find({});
    console.log(`   Result: ${all.length} photographers found\n`);

    console.log('2️⃣ Testing: Find with verification.status = approved');
    const approved = await Photographer.find({ 'verification.status': 'approved' });
    console.log(`   Result: ${approved.length} photographers found\n`);

    console.log('3️⃣ Testing: Find with verification.isVerified = true');
    const verified = await Photographer.find({ 'verification.isVerified': true });
    console.log(`   Result: ${verified.length} photographers found\n`);

    if (all.length > 0) {
      console.log('📋 First photographer details:');
      const first = all[0];
      console.log(`   - ID: ${first._id}`);
      console.log(`   - Name: ${first.name || 'N/A'}`);
      console.log(`   - Verification Status: ${first.verification?.status || 'N/A'}`);
      console.log(`   - Verification isVerified: ${first.verification?.isVerified || false}`);
      console.log(`   - Location: ${first.location?.city || 'N/A'}`);
      console.log(`   - Specialties: ${first.specialties?.join(', ') || 'N/A'}`);
    }

    await mongoose.disconnect();
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

testAPI();
