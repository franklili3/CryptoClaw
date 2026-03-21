import express from 'express';
import cors from 'cors';
import { exec } from 'child_process';
import { promisify } from 'util';
import { loadSkills, getSkillsList, hasSkill } from './skills-loader';
import { createVault, VaultFactoryConfig } from './secure-vault';

const execAsync = promisify(exec);

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// 初始化 SecureVault
let vaultConfig: VaultFactoryConfig = {
  preferredType: 'local', // 默认使用本地存储
};

// 如果配置了 TEE，优先使用
if (process.env.TEE_ENDPOINT) {
  vaultConfig = {
    preferredType: 'tee',
    tee: {
      endpoint: process.env.TEE_ENDPOINT,
      transport: (process.env.TEE_TRANSPORT as 'vsock' | 'unix' | 'grpc') || 'grpc',
      mrenclave: process.env.TEE_MRENCLAVE,
    },
  };
}

// ================== API 路由 ==================

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
    },
    vault: {
      type: vaultConfig.preferredType,
      teeEndpoint: process.env.TEE_ENDPOINT || null,
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

// ================== Skills API ==================

// 获取所有 skills
app.get('/api/skills', (req, res) => {
  try {
    const skills = getSkillsList();
    res.json({
      count: skills.length,
      skills
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to load skills' });
  }
});

// 检查 skill 是否存在
app.get('/api/skills/:name', (req, res) => {
  const { name } = req.params;
  if (hasSkill(name)) {
    res.json({ exists: true, name });
  } else {
    res.status(404).json({ exists: false, name });
  }
});

// ================== SecureVault API ==================

// 存储 API 凭证
app.post('/api/vault/credentials', async (req, res) => {
  try {
    const { provider, apiKey, apiSecret, extra } = req.body;

    if (!provider || !apiKey || !apiSecret) {
      return res.status(400).json({ error: 'Missing required fields: provider, apiKey, apiSecret' });
    }

    const vault = await createVault(vaultConfig);
    await vault.storeCredential({ provider, apiKey, apiSecret, extra });

    res.json({ success: true, provider, message: 'Credentials stored securely' });
  } catch (error) {
    console.error('Failed to store credentials:', error);
    res.status(500).json({ error: 'Failed to store credentials' });
  }
});

// 获取凭证状态 (脱敏)
app.get('/api/vault/credentials/:provider', async (req, res) => {
  try {
    const { provider } = req.params;
    const vault = await createVault(vaultConfig);
    const result = await vault.getCredential(provider);

    res.json(result);
  } catch (error) {
    console.error('Failed to get credential:', error);
    res.status(500).json({ error: 'Failed to get credential' });
  }
});

// 删除凭证
app.delete('/api/vault/credentials/:provider', async (req, res) => {
  try {
    const { provider } = req.params;
    const vault = await createVault(vaultConfig);
    await vault.deleteCredential(provider);

    res.json({ success: true, provider, message: 'Credentials deleted' });
  } catch (error) {
    console.error('Failed to delete credential:', error);
    res.status(500).json({ error: 'Failed to delete credential' });
  }
});

// 测试 API 连接
app.post('/api/vault/test/:provider', async (req, res) => {
  try {
    const { provider } = req.params;
    const vault = await createVault(vaultConfig);
    const result = await vault.testConnection(provider);

    res.json(result);
  } catch (error) {
    console.error('Failed to test connection:', error);
    res.status(500).json({ error: 'Failed to test connection' });
  }
});

// 执行签名请求
app.post('/api/vault/request', async (req, res) => {
  try {
    const { provider, method, path, params, body } = req.body;

    if (!provider || !method || !path) {
      return res.status(400).json({ error: 'Missing required fields: provider, method, path' });
    }

    const vault = await createVault(vaultConfig);
    const result = await vault.signedRequest({
      provider,
      method,
      path,
      params,
      body,
      signed: true,
    });

    res.json(result);
  } catch (error) {
    console.error('Failed to execute signed request:', error);
    res.status(500).json({ error: 'Failed to execute signed request' });
  }
});

// 获取 TEE 认证报告
app.get('/api/vault/attestation', async (req, res) => {
  try {
    const vault = await createVault(vaultConfig);
    const report = await vault.getAttestation();

    res.json(report);
  } catch (error) {
    console.error('Failed to get attestation:', error);
    res.status(500).json({ error: 'Failed to get attestation' });
  }
});

// ================== 启动服务器 ==================

app.listen(PORT, () => {
  console.log(`CryptoClaw Gateway running on port ${PORT}`);
  console.log(`OpenClaw config: ${process.env.OPENCLAW_CONFIG || 'not set'}`);
  console.log(`Vault type: ${vaultConfig.preferredType}`);

  // 加载 skills
  const skills = loadSkills();
  console.log(`Loaded ${skills.length} skills`);
});
