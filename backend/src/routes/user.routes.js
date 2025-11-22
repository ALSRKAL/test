const express = require('express');
const {
    getProfile,
    updateProfile,
    uploadAvatar: uploadAvatarController,
    deleteAvatar,
    getFavorites,
    addToFavorites,
    removeFromFavorites,
    deleteAccount,
    updateOneSignalPlayerId,
    updateNotificationSettings,
    getUserStatistics
} = require('../controllers/userController');

const router = express.Router({ mergeParams: true });

const { protect } = require('../middleware/auth.middleware');
const { uploadAvatar, handleMulterError } = require('../middleware/upload.middleware');

router.use(protect);

// Profile routes
router.get('/profile', getProfile);
router.put('/profile', updateProfile);

// Avatar routes
router.post('/avatar', uploadAvatar, handleMulterError, uploadAvatarController);
router.delete('/avatar', deleteAvatar);

// Favorites routes
router.get('/favorites', getFavorites);
router.post('/favorites/:photographerId', addToFavorites);
router.delete('/favorites/:photographerId', removeFromFavorites);

// Account management
router.delete('/account', deleteAccount);

// Notification settings
router.put('/onesignal-player-id', updateOneSignalPlayerId);
router.put('/notification-settings', updateNotificationSettings);

// Statistics
router.get('/statistics', getUserStatistics);

module.exports = router;
