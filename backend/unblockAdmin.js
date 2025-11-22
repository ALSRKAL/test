const mongoose = require('mongoose');
const dotenv = require('dotenv');
const User = require('./src/models/User');

dotenv.config();

const unblockAdmin = async () => {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('Connected to MongoDB');

        const email = 'superadmin@hajzy.com';
        const user = await User.findOne({ email });

        if (!user) {
            console.log('User not found');
            process.exit(1);
        }

        user.isBlocked = false;
        await user.save();

        console.log(`User ${email} has been unblocked successfully.`);
        console.log('Current status:', {
            email: user.email,
            role: user.role,
            isBlocked: user.isBlocked
        });

        process.exit(0);
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
};

unblockAdmin();
