

let io;

const setIo = (ioInstance) => {
    io = ioInstance;
};

const getIo = () => {
    if (!io) {
        throw new Error('Socket.io not initialized!');
    }
    return io;
};

const emitNotification = (userId, notification) => {
    try {
        const ioInstance = getIo();
        ioInstance.to(`user_${userId}`).emit('new_notification', notification);

        // Also emit count update
        // We don't know the exact count here without querying, but we can tell frontend to increment
        ioInstance.to(`user_${userId}`).emit('notification_count_update', {
            increment: true,
            count: 1
        });
    } catch (error) {
        console.error('Error emitting notification:', error);
    }
};

module.exports = {
    setIo,
    getIo,
    emitNotification
};
