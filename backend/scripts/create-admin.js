const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });
const mongoose = require('mongoose');
const User = require('../src/models/User');

const createAdmin = async () => {
  try {
    // Connect to database
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Check if admin exists
    const existingAdmin = await User.findOne({ email: 'admin@hajzy.com' });
    
    if (existingAdmin) {
      console.log('⚠️  Admin already exists');
      console.log('Email:', existingAdmin.email);
      console.log('Role:', existingAdmin.role);
      
      // Update to make sure it's admin
      if (existingAdmin.role !== 'admin') {
        existingAdmin.role = 'admin';
        await existingAdmin.save();
        console.log('✅ Updated user to admin role');
      }
    } else {
      // Create new admin
      const admin = await User.create({
        name: 'Admin',
        email: 'admin@hajzy.com',
        phone: '0500000000',
        password: 'Admin@Hajzy2025!',
        role: 'admin',
      });

      console.log('✅ Admin created successfully!');
      console.log('Email:', admin.email);
      console.log('Password: Admin@Hajzy2025!');
    }

    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
};

createAdmin();
