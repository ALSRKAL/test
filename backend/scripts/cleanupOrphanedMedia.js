const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });
const mongoose = require('mongoose');
const cloudinary = require('../src/config/cloudinary');
const User = require('../src/models/User');
const Photographer = require('../src/models/Photographer');
const logger = require('../src/utils/logger');

// Connect to Database
const connectDB = async () => {
    try {
        const uri = process.env.MONGODB_URI || process.env.MONGO_URI;
        if (!uri) {
            throw new Error('MONGODB_URI is not defined in environment variables');
        }
        const conn = await mongoose.connect(uri);
        console.log(`MongoDB Connected: ${conn.connection.host}`);
    } catch (error) {
        console.error(`Error: ${error.message}`);
        process.exit(1);
    }
};

/**
 * Extract public ID from Cloudinary URL
 */
const extractPublicIdFromUrl = (url) => {
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
};

const cleanupOrphanedMedia = async () => {
    await connectDB();

    try {
        console.log('Starting cleanup of orphaned media...');

        // 1. Fetch all valid public IDs from MongoDB
        const validPublicIds = new Set();

        // Users (Avatars)
        const users = await User.find({ avatar: { $ne: null } }).select('avatar');
        users.forEach(user => {
            const publicId = extractPublicIdFromUrl(user.avatar);
            if (publicId) validPublicIds.add(publicId);
        });
        console.log(`Found ${users.length} user avatars.`);

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
        console.log(`Found valid media references from ${photographers.length} photographers.`);
        console.log(`Total valid public IDs in DB: ${validPublicIds.size}`);

        // 2. Fetch all resources from Cloudinary
        // Note: Cloudinary Admin API has rate limits and pagination.
        // We'll fetch in batches.
        let nextCursor = null;
        const orphanedPublicIds = [];
        const foldersToCheck = ['hajzy/avatars', 'hajzy/images', 'hajzy/videos', 'portfolio']; // Add your folders here

        // Helper to fetch resources
        const fetchResources = async (resourceType) => {
            do {
                const result = await cloudinary.api.resources({
                    resource_type: resourceType,
                    type: 'upload',
                    max_results: 500,
                    next_cursor: nextCursor,
                    prefix: 'hajzy/' // Filter by prefix if all your app files are in a specific folder structure
                });

                result.resources.forEach(resource => {
                    if (!validPublicIds.has(resource.public_id)) {
                        orphanedPublicIds.push({ id: resource.public_id, type: resourceType });
                    }
                });

                nextCursor = result.next_cursor;
                console.log(`Fetched batch. Total orphaned candidates so far: ${orphanedPublicIds.length}`);
            } while (nextCursor);
        };

        console.log('Fetching images from Cloudinary...');
        nextCursor = null;
        await fetchResources('image');

        console.log('Fetching videos from Cloudinary...');
        nextCursor = null;
        await fetchResources('video');

        console.log(`Total orphaned files found: ${orphanedPublicIds.length}`);

        if (orphanedPublicIds.length === 0) {
            console.log('No orphaned files found. Cleanup complete.');
            process.exit(0);
        }

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
                console.log(`Deleted batch of ${imageIds.length} images.`);
            }
            if (videoIds.length > 0) {
                await cloudinary.api.delete_resources(videoIds, { resource_type: 'video' });
                console.log(`Deleted batch of ${videoIds.length} videos.`);
            }
        }

        console.log('Cleanup complete!');
        process.exit(0);
    } catch (error) {
        console.error('Error during cleanup:', error);
        process.exit(1);
    }
};

cleanupOrphanedMedia();
