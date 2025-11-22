const mongoose = require('mongoose');
const dotenv = require('dotenv');
const User = require('./src/models/User');

dotenv.config();

const resetAdminPassword = async () => {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('Connected to MongoDB');

        const email = 'admin@hajzy.com';
        const user = await User.findOne({ email }).select('+password');

        if (!user) {
            console.log(`User ${email} not found.`);
        } else {
            console.log(`User ${email} found. Resetting password...`);
            user.password = '123456';
            await user.save();
            console.log('Password reset to "123456" successfully.');
        }

        process.exit();
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
};

resetAdminPassword();
