const express = require('express');
const router = express.Router();
const bookingController = require('../controllers/bookingController');
const { protect } = require('../middleware/auth.middleware');
const { validate, schemas } = require('../middleware/validation.middleware');

// Check availability (public)
router.get('/availability/:photographerId', bookingController.checkAvailability);

// Get booked dates for photographer (public)
router.get('/booked-dates/:photographerId', bookingController.getBookedDates);

// All other routes are protected
router.use(protect);

router.post('/', validate(schemas.createBooking), bookingController.createBooking);
router.get('/', bookingController.getBookings);
router.get('/:id', bookingController.getBookingById);
router.put('/:id/status', bookingController.updateBookingStatus);
router.put('/:id/cancel', bookingController.cancelBooking);

module.exports = router;
