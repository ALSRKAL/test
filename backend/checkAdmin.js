const mongoose = require('mongoose');
const dotenv = require('dotenv');
const User = require('./src/models/User');

dotenv.config();

const checkAdmin = async () => {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('Connected to MongoDB');

        const email = 'admin@hajzy.com';
        const user = await User.findOne({ email }).select('+password');

        if (!user) {
            console.log(`User ${email} not found.`);
        } else {
            console.log(`User ${email} found.`);
            console.log('Role:', user.role);
            console.log('Is Blocked:', user.isBlocked);
            // We can't see the password, but we can check if it matches a default
            const isMatch = await user.comparePassword('123456');
            console.log('Password matches "123456":', isMatch);

            const isMatch2 = await user.comparePassword('password123');
            console.log('Password matches "password123":', isMatch2);

            const isMatch3 = await user.comparePassword('admin123');
            console.log('Password matches "admin123":', isMatch3);
        }

        process.exit();
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
};

checkAdmin();
