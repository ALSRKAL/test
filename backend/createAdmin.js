const mongoose = require('mongoose');
const dotenv = require('dotenv');
const User = require('./src/models/User');

dotenv.config();

const createAdmin = async () => {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('Connected to MongoDB');

        const email = 'superadmin@hajzy.com';
        const password = 'password123';

        // Check if exists
        let user = await User.findOne({ email });
        if (user) {
            console.log('User already exists, removing...');
            await User.deleteOne({ _id: user._id });
        }

        console.log('Creating new admin user...');
        user = await User.create({
            name: 'Super Admin',
            email,
            password,
            phone: '0500000000',
            role: 'superadmin',
            isBlocked: false
        });

        console.log(`Admin created successfully.`);
        console.log(`Email: ${email}`);
        console.log(`Password: ${password}`);

        process.exit();
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
};

createAdmin();
