const User = require('../models/User');
const bcrypt = require('bcryptjs');

// Get all admin users
exports.getAdmins = async (req, res) => {
    try {
        const admins = await User.find({
            role: { $in: ['admin', 'superadmin', 'employee'] }
        }).select('-password');

        res.status(200).json({
            success: true,
            data: admins
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Server Error'
        });
    }
};

// Get current admin profile
exports.getMe = async (req, res) => {
    try {
        const user = await User.findById(req.user._id).select('-password');
        res.status(200).json({
            success: true,
            data: user
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Server Error'
        });
    }
};

// Create new admin user
exports.createAdmin = async (req, res) => {
    try {
        const { name, email, password, phone, role, permissions } = req.body;

        // Check if user exists
        let user = await User.findOne({ email });
        if (user) {
            return res.status(400).json({
                success: false,
                message: 'User already exists'
            });
        }

        // Create user
        user = await User.create({
            name,
            email,
            password,
            phone,
            role: role || 'employee',
            permissions: permissions || []
        });

        res.status(201).json({
            success: true,
            data: user
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server Error'
        });
    }
};

// Update admin user
exports.updateAdmin = async (req, res) => {
    try {
        const { name, email, phone, role, permissions, password } = req.body;

        let user = await User.findById(req.params.id);

        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User not found'
            });
        }

        // Prevent modifying other superadmins if not self (optional logic, but good practice)
        // For now, allow superadmin to modify anyone

        const updateData = {
            name,
            email,
            phone,
            role,
            permissions
        };

        if (password) {
            const salt = await bcrypt.genSalt(10);
            updateData.password = await bcrypt.hash(password, salt);
        }

        user = await User.findByIdAndUpdate(req.params.id, updateData, {
            new: true,
            runValidators: true
        });

        res.status(200).json({
            success: true,
            data: user
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Server Error'
        });
    }
};

// Delete admin user
exports.deleteAdmin = async (req, res) => {
    try {
        const cleanupService = require('../services/cleanupService');
        const user = await User.findById(req.params.id);

        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User not found'
            });
        }

        // Prevent deleting self
        if (user._id.toString() === req.user._id.toString()) {
            return res.status(400).json({
                success: false,
                message: 'Cannot delete yourself'
            });
        }

        await cleanupService.deleteUserComplete(req.params.id);

        res.status(200).json({
            success: true,
            message: 'User deleted successfully'
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Server Error'
        });
    }
};
