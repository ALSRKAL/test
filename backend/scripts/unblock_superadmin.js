const mongoose = require('mongoose');
const dotenv = require('dotenv');
const path = require('path');

// Load env vars
dotenv.config({ path: path.join(__dirname, '../.env') });

const User = require('../src/models/User');

const unblockSuperadmin = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log('MongoDB Connected...');

        const email = 'superadmin@hajzy.com';
        const user = await User.findOne({ email });

        if (!user) {
            console.log('Superadmin user not found!');
            process.exit(1);
        }

        user.isBlocked = false;
        await user.save();

        console.log(`User ${email} has been unblocked successfully.`);
        process.exit(0);
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
};

unblockSuperadmin();
