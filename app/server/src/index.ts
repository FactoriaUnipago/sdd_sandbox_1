import express, { Request, Response } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';
import path from 'path';
import fs from 'fs';
import { globalRateLimiter } from './middleware/rateLimiter';
import { apiKeyGate } from './middleware/apiKeyGate';
import { prisma } from './lib/prisma';

// Load env variables
dotenv.config({ path: '../.env' });

const app = express();
const PORT = process.env.PORT || 3000;
const CORS_ORIGIN = process.env.CORS_ORIGIN || 'http://localhost:5173';

// ─── Middleware Chain (cors → helmet → rateLimit → json → apiKeyGate) ───
app.use(cors({ origin: CORS_ORIGIN }));
app.use(
  helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        scriptSrc: ["'self'", "'unsafe-inline'", "https://cdn.redoc.ly", "https://unpkg.com"],
        styleSrc: ["'self'", "'unsafe-inline'", "https://fonts.googleapis.com", "https://unpkg.com"],
        fontSrc: ["'self'", "https://fonts.gstatic.com"],
        imgSrc: ["'self'", "data:", "https://unpkg.com"],
        connectSrc: ["'self'"],
      },
    },
  })
);
app.use(globalRateLimiter);
app.use(express.json({ limit: '10kb' }));
app.use(apiKeyGate);

// ─── Routes ───

// Health Check — verifies DB connection
app.get('/api/health', async (_req: Request, res: Response) => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    res.json({
      status: 'ok',
      database: 'connected',
      uptime: process.uptime(),
      version: '1.0.0',
      timestamp: new Date().toISOString(),
    });
  } catch {
    res.status(503).json({
      status: 'error',
      database: 'disconnected',
      uptime: process.uptime(),
      version: '1.0.0',
      timestamp: new Date().toISOString(),
    });
  }
});

// API Documentation routes
const openApiSpecPath = path.join(__dirname, '../../../docs/api/openapi.yaml');

// Serve the raw specification file
app.get('/api/docs/spec', (req: Request, res: Response) => {
  try {
    if (fs.existsSync(openApiSpecPath)) {
      res.setHeader('Content-Type', 'text/yaml');
      res.sendFile(openApiSpecPath);
    } else {
      res.status(404).json({ error: 'OpenAPI specification file not found' });
    }
  } catch (error) {
    res.status(500).json({ error: 'Internal server error reading specification' });
  }
});

// Serve Swagger UI (interactive testing docs)
app.get('/api/docs', (req: Request, res: Response) => {
  const swaggerHtml = `
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>Task Manager API Docs</title>
        <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css" />
      </head>
      <body>
        <div id="swagger-ui"></div>
        <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js" crossorigin></script>
        <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-standalone-preset.js" crossorigin></script>
        <script>
          window.onload = () => {
            window.ui = SwaggerUIBundle({
              url: '/api/docs/spec',
              dom_id: '#swagger-ui',
              presets: [
                SwaggerUIBundle.presets.apis,
                SwaggerUIBundle.SwaggerUIStandalonePreset
              ],
              layout: "BaseLayout",
              deepLinking: true
            });
          };
        </script>
      </body>
    </html>
  `;
  res.send(swaggerHtml);
});

// Serve ReDoc (clean visual docs)
app.get('/api/redoc', (req: Request, res: Response) => {
  const redocHtml = `
    <!DOCTYPE html>
    <html>
      <head>
        <title>Task Manager API Docs (ReDoc)</title>
        <meta charset="utf-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <link href="https://fonts.googleapis.com/css?family=Montserrat:300,400,700|Roboto:300,400,700" rel="stylesheet">
        <style>
          body {
            margin: 0;
            padding: 0;
          }
        </style>
      </head>
      <body>
        <redoc spec-url='/api/docs/spec'></redoc>
        <script src="https://cdn.redoc.ly/redoc/latest/bundles/redoc.standalone.js"> </script>
      </body>
    </html>
  `;
  res.send(redocHtml);
});

// ─── Server ───
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
