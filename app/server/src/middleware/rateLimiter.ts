import rateLimit from 'express-rate-limit';

/**
 * Global rate limiter: 100 requests per 15 minutes
 * Applied globally to all API routes.
 */
export const globalRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    error: 'Too many requests, please try again later.',
  },
});

/**
 * Login rate limiter: 5 attempts per 15 minutes
 * More restrictive for authentication endpoints.
 */
export const loginRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    error: 'Too many login attempts, please try again later.',
  },
});
