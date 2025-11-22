const User = require('../models/User');
const Photographer = require('../models/Photographer');
const Booking = require('../models/Booking');
const Review = require('../models/Review');
const Notification = require('../models/Notification');
const cloudinary = require('../config/cloudinary');
const logger = require('../utils/logger');

/**
 * Service to handle robust deletion of users and their associated data
 */
class CleanupService {
    /**
     * Delete a user and all associated data (Photographer profile, media, bookings, etc.)
     * @param {string} userId - The ID of the user to delete
     * @returns {Promise<Object>} - Result of the deletion
     */
    async deleteUserComplete(userId) {
        logger.info(`Starting complete deletion for user: ${userId}`);

        try {
            const user = await User.findById(userId);
            if (!user) {
                throw new Error('User not found');
            }

            // 1. Delete User Avatar from Cloudinary
            if (user.avatar) {
                await this.deleteImageFromCloudinary(user.avatar);
            }

            // 2. Check if user is a photographer and delete profile + media
            const photographer = await Photographer.findOne({ user: userId });
            if (photographer) {
                await this.deletePhotographerData(photographer);
            }

            // 3. Delete Bookings (Client & Photographer)
            // We delete bookings where this user is either client or photographer
            // Note: This is a destructive action. In some systems, you might want to keep bookings for records.
            // But per "wipe all data" request, we delete them.
            await Booking.deleteMany({
                $or: [{ client: userId }, { photographer: userId }] // If photographer field refers to User ID (it usually refers to Photographer ID, let's check model)
            });

            // Double check Booking model: 'photographer' ref is 'Photographer' model usually.
            // If we deleted the Photographer doc above, we should delete bookings referencing that Photographer ID.
            if (photographer) {
                await Booking.deleteMany({ photographer: photographer._id });
            }

            // 4. Delete Reviews
            await Review.deleteMany({ client: userId });
            if (photographer) {
                await Review.deleteMany({ photographer: photographer._id });
            }

            // 5. Delete Notifications
            await Notification.deleteMany({ recipient: userId });

            // 6. Delete User Record
            await User.findByIdAndDelete(userId);

            logger.info(`Successfully deleted user ${userId} and all associated data.`);
            return { success: true, message: 'User and all data deleted successfully' };

        } catch (error) {
            logger.error(`Error in deleteUserComplete for user ${userId}: ${error.message}`);
            throw error;
        }
    }

    /**
     * Delete photographer profile and all portfolio media
     * @param {Object} photographer - The photographer document
     */
    async deletePhotographerData(photographer) {
        logger.info(`Deleting photographer data for: ${photographer._id}`);

        // 1. Delete Portfolio Images
        if (photographer.portfolio && photographer.portfolio.images && photographer.portfolio.images.length > 0) {
            const imagePublicIds = photographer.portfolio.images
                .map(img => img.publicId)
                .filter(id => id); // Filter out undefined/null

            if (imagePublicIds.length > 0) {
                await this.deleteResourcesFromCloudinary(imagePublicIds, 'image');
            }
        }

        // 2. Delete Portfolio Video
        if (photographer.portfolio && photographer.portfolio.video && photographer.portfolio.video.publicId) {
            await this.deleteResourcesFromCloudinary([photographer.portfolio.video.publicId], 'video');
        }

        // 3. Delete Verification Documents (if stored in Cloudinary)
        if (photographer.verification && photographer.verification.documents) {
            const docs = [];
            if (photographer.verification.documents.idCard) {
                // Check if it's a cloudinary URL and extract public ID if needed, 
                // or if you store publicId separately. Assuming URL might need parsing if publicId not stored.
                // For now, if you don't store publicId for docs, we might skip or try to parse.
                // Let's assume for now we only strictly delete if we have public IDs or can parse.
                // If you implement doc upload same as images, you should store publicId.
                // If not, we'll leave this for now or try to parse.
                const publicId = this.extractPublicIdFromUrl(photographer.verification.documents.idCard);
                if (publicId) docs.push(publicId);
            }
            if (photographer.verification.documents.portfolioSamples && photographer.verification.documents.portfolioSamples.length > 0) {
                photographer.verification.documents.portfolioSamples.forEach(url => {
                    const pid = this.extractPublicIdFromUrl(url);
                    if (pid) docs.push(pid);
                });
            }

            if (docs.length > 0) {
                await this.deleteResourcesFromCloudinary(docs, 'image'); // Assuming docs are images
            }
        }

        // 4. Delete Photographer Document
        await Photographer.findByIdAndDelete(photographer._id);
    }

    /**
     * Helper to delete a single image from Cloudinary by URL or Public ID
     * @param {string} urlOrPublicId 
     */
    async deleteImageFromCloudinary(urlOrPublicId) {
        if (!urlOrPublicId) return;

        let publicId = urlOrPublicId;
        if (urlOrPublicId.startsWith('http')) {
            publicId = this.extractPublicIdFromUrl(urlOrPublicId);
        }

        if (publicId) {
            try {
                await cloudinary.uploader.destroy(publicId);
                logger.info(`Deleted from Cloudinary: ${publicId}`);
            } catch (error) {
                logger.error(`Failed to delete from Cloudinary (${publicId}): ${error.message}`);
            }
        }
    }

    /**
     * Helper to delete multiple resources
     * @param {Array<string>} publicIds 
     * @param {string} resourceType - 'image' or 'video'
     */
    async deleteResourcesFromCloudinary(publicIds, resourceType = 'image') {
        if (!publicIds || publicIds.length === 0) return;

        try {
            // Cloudinary api.delete_resources supports array of public_ids
            // Note: uploader.destroy is for single, api.delete_resources for multiple
            // But api.delete_resources requires Admin API usage which might be rate limited or different config.
            // Safer to loop uploader.destroy for now or use api if configured.
            // Let's use api.delete_resources if available, else loop.

            // Using Promise.all with uploader.destroy is robust for standard keys
            const deletePromises = publicIds.map(id =>
                cloudinary.uploader.destroy(id, { resource_type: resourceType })
            );

            await Promise.all(deletePromises);
            logger.info(`Deleted ${publicIds.length} ${resourceType}(s) from Cloudinary`);
        } catch (error) {
            logger.error(`Failed to batch delete from Cloudinary: ${error.message}`);
        }
    }

    /**
     * Extract public ID from Cloudinary URL
     * @param {string} url 
     */
    extractPublicIdFromUrl(url) {
        if (!url) return null;
        try {
            const urlParts = url.split('/');
            const uploadIndex = urlParts.indexOf('upload');
            if (uploadIndex !== -1 && uploadIndex < urlParts.length - 1) {
                let pathAfterUpload = urlParts.slice(uploadIndex + 1);
                if (pathAfterUpload[0] && pathAfterUpload[0].match(/^v\d+$/)) {
                    pathAfterUpload = pathAfterUpload.slice(1);
                }
                const fullPath = pathAfterUpload.join('/');
                return fullPath.substring(0, fullPath.lastIndexOf('.')) || fullPath;
            }
            return null;
        } catch (e) {
            return null;
        }
    }

    /**
     * Scan for and delete orphaned media files in Cloudinary
     */
    async cleanupOrphanedMedia() {
        logger.info('Starting scheduled cleanup of orphaned media...');

        try {
            // 1. Fetch all valid public IDs from MongoDB
            const validPublicIds = new Set();

            // Users (Avatars)
            const users = await User.find({ avatar: { $ne: null } }).select('avatar');
            users.forEach(user => {
                const publicId = this.extractPublicIdFromUrl(user.avatar);
                if (publicId) validPublicIds.add(publicId);
            });

            // Photographers (Portfolio Images & Videos)
            const photographers = await Photographer.find({}).select('portfolio');
            photographers.forEach(p => {
                if (p.portfolio) {
                    // Images
                    if (p.portfolio.images) {
                        p.portfolio.images.forEach(img => {
                            if (img.publicId) validPublicIds.add(img.publicId);
                        });
                    }
                    // Video
                    if (p.portfolio.video && p.portfolio.video.publicId) {
                        validPublicIds.add(p.portfolio.video.publicId);
                    }
                }
            });

            logger.info(`Found ${validPublicIds.size} valid media references in DB.`);

            // 2. Fetch all resources from Cloudinary
            let nextCursor = null;
            const orphanedPublicIds = [];

            // Helper to fetch resources
            const fetchResources = async (resourceType) => {
                do {
                    const result = await cloudinary.api.resources({
                        resource_type: resourceType,
                        type: 'upload',
                        max_results: 500,
                        next_cursor: nextCursor,
                        prefix: 'hajzy/' // Filter by prefix
                    });

                    result.resources.forEach(resource => {
                        if (!validPublicIds.has(resource.public_id)) {
                            orphanedPublicIds.push({ id: resource.public_id, type: resourceType });
                        }
                    });

                    nextCursor = result.next_cursor;
                } while (nextCursor);
            };

            // Fetch images
            nextCursor = null;
            await fetchResources('image');

            // Fetch videos
            nextCursor = null;
            await fetchResources('video');

            if (orphanedPublicIds.length === 0) {
                logger.info('No orphaned files found. Cleanup complete.');
                return;
            }

            logger.info(`Found ${orphanedPublicIds.length} orphaned files. Deleting...`);

            // 3. Delete orphaned files
            // Batch delete in chunks of 100
            const batchSize = 100;
            for (let i = 0; i < orphanedPublicIds.length; i += batchSize) {
                const batch = orphanedPublicIds.slice(i, i + batchSize);

                // Separate by type
                const imageIds = batch.filter(item => item.type === 'image').map(item => item.id);
                const videoIds = batch.filter(item => item.type === 'video').map(item => item.id);

                if (imageIds.length > 0) {
                    await cloudinary.api.delete_resources(imageIds, { resource_type: 'image' });
                }
                if (videoIds.length > 0) {
                    await cloudinary.api.delete_resources(videoIds, { resource_type: 'video' });
                }
            }

            logger.info(`Successfully deleted ${orphanedPublicIds.length} orphaned files.`);
        } catch (error) {
            logger.error(`Error during scheduled cleanup: ${error.message}`);
        }
    }
}

module.exports = new CleanupService();
