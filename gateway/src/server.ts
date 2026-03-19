import express from 'express';
import cors from 'cors';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/health', async (req, res) => {
  let openclawVersion = 'not installed';
  
  try {
    const { stdout } = await execAsync('openclaw --version');
    openclawVersion = stdout.trim();
  } catch (e) {
    // OpenClaw not available
  }
  
  res.json({
    status: 'healthy',
    version: process.env.npm_package_version || '1.0.0',
    openclaw: openclawVersion,
    timestamp: new Date().toISOString()
  });
});

// API status
app.get('/api/status', (req, res) => {
  res.json({
    service: 'CryptoClaw Gateway',
    status: 'running',
    openclaw: {
      config: process.env.OPENCLAW_CONFIG,
      workspace: process.env.OPENCLAW_WORKSPACE
    }
  });
});

// OpenClaw version check
app.get('/api/openclaw/version', async (req, res) => {
  try {
    const { stdout } = await execAsync('openclaw --version');
    res.json({
      installed: true,
      version: stdout.trim()
    });
  } catch (e) {
    res.json({
      installed: false,
      error: 'OpenClaw not found'
    });
  }
});

// Start server
app.listen(PORT, () => {
  console.log(`CryptoClaw Gateway running on port ${PORT}`);
  console.log(`OpenClaw config: ${process.env.OPENCLAW_CONFIG || 'not set'}`);
});
