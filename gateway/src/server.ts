import express from 'express';
import cors from 'cors';

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    version: process.env.npm_package_version || '1.0.0',
    timestamp: new Date().toISOString()
  });
});

// API routes
app.get('/api/status', (req, res) => {
  res.json({
    service: 'CryptoClaw Gateway',
    status: 'running'
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`CryptoClaw Gateway running on port ${PORT}`);
});
