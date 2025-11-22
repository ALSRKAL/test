const Joi = require('joi');

// Validate request body
const validate = (schema) => {
  return (req, res, next) => {
    const { error } = schema.validate(req.body, {
      abortEarly: false,
      stripUnknown: true,
    });

    if (error) {
      const errors = error.details.map((detail) => ({
        field: detail.path.join('.'),
        message: detail.message,
      }));

      return res.status(400).json({
        success: false,
        message: 'Validation error',
        errors,
      });
    }

    next();
  };
};

// Validation schemas
const schemas = {
  // Auth schemas
  register: Joi.object({
    name: Joi.string().min(2).max(50).required(),
    email: Joi.string().email().required(),
    phone: Joi.string()
      .min(8)
      .max(15)
      .required()
      .messages({
        'string.min': 'Phone number must be at least 8 digits',
        'string.max': 'Phone number must not exceed 15 digits',
      }),
    password: Joi.string().min(6).required(),
    role: Joi.string().valid('client', 'photographer').optional(),
  }),

  login: Joi.object({
    email: Joi.string().email().required(),
    password: Joi.string().required(),
  }),

  // Booking schema
  createBooking: Joi.object({
    photographer: Joi.string().required(),
    package: Joi.object({
      name: Joi.string().required(),
      price: Joi.number().required(),
      duration: Joi.string().required(),
      features: Joi.array().items(Joi.string()).optional(),
    }).optional().allow(null),
    date: Joi.date().greater('now').required(),
    timeSlot: Joi.string().required(),
    location: Joi.string().required(),
    notes: Joi.string().max(500).optional(),
  }),

  // Review schema
  createReview: Joi.object({
    photographer: Joi.string().required(),
    booking: Joi.string().required(),
    rating: Joi.number().min(1).max(5).required(),
    comment: Joi.string().min(5).max(500).required(),
  }),

  // Profile update schema
  updateProfile: Joi.object({
    name: Joi.string().min(2).max(50).optional(),
    phone: Joi.string().min(8).max(15).optional(),
    avatar: Joi.string().uri().optional(),
  }),
};

module.exports = { validate, schemas };
