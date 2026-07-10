import { Request, Response, NextFunction } from 'express';

/**
 * API Key Gate Middleware
 * Validates x-api-key header against configured API_KEY env variable.
 * Skips validation for health check endpoint.
 */
export function apiKeyGate(req: Request, res: Response, next: NextFunction): void {
  // Skip health check endpoint for monitoring tools
  if (req.path === '/api/health') {
    return next();
  }

  const apiKey = req.headers['x-api-key'] as string | undefined;

  if (!apiKey) {
    res.status(403).json({ error: 'Missing x-api-key header' });
    return;
  }

  if (apiKey !== process.env.API_KEY) {
    res.status(403).json({ error: 'Invalid API key' });
    return;
  }

  next();
}
