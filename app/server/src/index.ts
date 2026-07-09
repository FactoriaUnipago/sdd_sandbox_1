import express, { Request, Response } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';

import path from 'path';
import fs from 'fs';

// Load env variables
dotenv.config({ path: '../.env' });

const app = express();
const PORT = process.env.PORT || 3000;
const CORS_ORIGIN = process.env.CORS_ORIGIN || 'http://localhost:5173';

// Middlewares
// Configure Helmet with CSP to allow ReDoc from CDN and Google Fonts
app.use(
  helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        scriptSrc: ["'self'", "'unsafe-inline'", "https://cdn.redoc.ly"],
        styleSrc: ["'self'", "'unsafe-inline'", "https://fonts.googleapis.com"],
        fontSrc: ["'self'", "https://fonts.gstatic.com"],
        imgSrc: ["'self'", "data:"],
      },
    },
  })
);
app.use(cors({ origin: CORS_ORIGIN }));
app.use(express.json({ limit: '10kb' }));

// API Documentation routes
const openApiSpecPath = path.join(__dirname, '../../../../docs/api/openapi.yaml');

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

app.get('/api/docs', (req: Request, res: Response) => {
  const redocHtml = `
    <!DOCTYPE html>
    <html>
      <head>
        <title>Task Manager API Docs</title>
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

// Basic route
app.get('/api/health', (req: Request, res: Response) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    version: '1.0.0'
  });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
