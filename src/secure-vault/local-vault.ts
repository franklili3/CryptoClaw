/**
 * LocalVault - 本地加密存储实现
 *
 * 当 TEE 不可用时的降级方案
 * 使用 AES-256-GCM 加密存储 API 密钥
 *
 * 安全级别: 中等 (密钥存储在本地文件系统)
 * 适用场景: 开发环境、个人服务器
 */

import * as crypto from 'crypto';
import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';
import type {
  SecureVault,
  StoreCredentialParams,
  SignedRequestParams,
  SignedRequestResult,
  AttestationReport,
  EncryptedCredentials,
} from './types.js';

// 支持的交易所签名配置
const EXCHANGE_CONFIG: Record<string, {
  baseUrl: string;
  signHeader: string;
  hmacAlgorithm: 'sha256' | 'sha512';
}> = {
  binance: {
    baseUrl: 'https://api.binance.com',
    signHeader: 'X-MBX-APIKEY',
    hmacAlgorithm: 'sha256',
  },
  okx: {
    baseUrl: 'https://www.okx.com',
    signHeader: 'OK-ACCESS-KEY',
    hmacAlgorithm: 'sha256',
  },
  hyperliquid: {
    baseUrl: 'https://api.hyperliquid.xyz',
    signHeader: '',
    hmacAlgorithm: 'sha256',
  },
};

export class LocalVault implements SecureVault {
  private readonly dataDir: string;
  private readonly encryptionKey: Buffer;
  private algorithm: 'aes-256-gcm' = 'aes-256-gcm';

  constructor(encryptionKey?: string) {
    // 数据存储目录
    this.dataDir = process.env.CRYPTOCLAW_DATA_DIR || path.join(os.homedir(), '.cryptoclaw', 'vault');

    // 确保目录存在
    if (!fs.existsSync(this.dataDir)) {
      fs.mkdirSync(this.dataDir, { recursive: true });
    }

    // 加密密钥 (32 bytes for AES-256)
    if (encryptionKey) {
      this.encryptionKey = Buffer.from(encryptionKey.padEnd(32).slice(0, 32));
    } else {
      // 从环境变量或生成新密钥
      const keyPath = path.join(this.dataDir, '.master-key');
      if (fs.existsSync(keyPath)) {
        this.encryptionKey = fs.readFileSync(keyPath);
      } else {
        this.encryptionKey = crypto.randomBytes(32);
        fs.writeFileSync(keyPath, this.encryptionKey, { mode: 0o600 });
      }
    }
  }

  isAvailable(): boolean {
    return true; // LocalVault 始终可用
  }

  async getAttestation(): Promise<AttestationReport> {
    return {
      platform: 'none',
      timestamp: Date.now(),
      valid: true,
    };
  }

  /**
   * 加密数据
   */
  private encrypt(plaintext: string): EncryptedCredentials {
    const iv = crypto.randomBytes(12);
    const cipher = crypto.createCipheriv(this.algorithm, this.encryptionKey, iv, {
      authTagLength: 16,
    });

    let encrypted = cipher.update(plaintext, 'utf8');
    encrypted = Buffer.concat([encrypted, cipher.final()]);
    const authTag = cipher.getAuthTag();

    return {
      ciphertext: encrypted.toString('base64'),
      iv: iv.toString('base64'),
      authTag: authTag.toString('base64'),
      algorithm: 'AES-256-GCM',
      createdAt: Date.now(),
    };
  }

  /**
   * 解密数据
   */
  private decrypt(encrypted: EncryptedCredentials): string {
    const iv = Buffer.from(encrypted.iv, 'base64');
    const authTag = Buffer.from(encrypted.authTag!, 'base64');
    const ciphertext = Buffer.from(encrypted.ciphertext, 'base64');

    const decipher = crypto.createDecipheriv(this.algorithm, this.encryptionKey, iv, {
      authTagLength: 16,
    });
    decipher.setAuthTag(authTag);

    let decrypted = decipher.update(ciphertext);
    decrypted = Buffer.concat([decrypted, decipher.final()]);

    return decrypted.toString('utf8');
  }

  /**
   * 获取凭证文件路径
   */
  private getCredentialPath(provider: string): string {
    return path.join(this.dataDir, `${provider}.json`);
  }

  async storeCredential(params: StoreCredentialParams): Promise<void> {
    const data = {
      apiKey: params.apiKey,
      apiSecret: params.apiSecret,
      extra: params.extra,
    };

    const encrypted = this.encrypt(JSON.stringify(data));
    const filePath = this.getCredentialPath(params.provider);

    fs.writeFileSync(filePath, JSON.stringify(encrypted, null, 2), {
      mode: 0o600,
    });
  }

  async getCredential(provider: string): Promise<{ exists: boolean; maskedKey?: string }> {
    const filePath = this.getCredentialPath(provider);

    if (!fs.existsSync(filePath)) {
      return { exists: false };
    }

    const encrypted: EncryptedCredentials = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    const decrypted = JSON.parse(this.decrypt(encrypted));

    // 返回脱敏的 key
    const key = decrypted.apiKey as string;
    const maskedKey = key.length > 8
      ? `${key.slice(0, 4)}...${key.slice(-4)}`
      : '****';

    return { exists: true, maskedKey };
  }

  async deleteCredential(provider: string): Promise<void> {
    const filePath = this.getCredentialPath(provider);

    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
    }
  }

  /**
   * 获取解密后的凭证 (内部使用)
   */
  private async getDecryptedCredential(provider: string): Promise<{
    apiKey: string;
    apiSecret: string;
    extra?: Record<string, string>;
  } | null> {
    const filePath = this.getCredentialPath(provider);

    if (!fs.existsSync(filePath)) {
      return null;
    }

    const encrypted: EncryptedCredentials = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    return JSON.parse(this.decrypt(encrypted));
  }

  async signedRequest(params: SignedRequestParams): Promise<SignedRequestResult> {
    const config = EXCHANGE_CONFIG[params.provider];

    if (!config) {
      return {
        ok: false,
        error: `Unsupported provider: ${params.provider}`,
      };
    }

    const creds = await this.getDecryptedCredential(params.provider);

    if (!creds) {
      return {
        ok: false,
        error: `No credentials stored for ${params.provider}`,
      };
    }

    const startTime = Date.now();

    try {
      // 构建请求
      const url = new URL(config.baseUrl + params.path);

      // 添加 timestamp
      const timestamp = Date.now();
      const queryParams: Record<string, string> = {
        ...params.params,
        timestamp: timestamp.toString(),
      };

      // 构建查询字符串
      const queryString = Object.entries(queryParams)
        .map(([k, v]) => `${k}=${encodeURIComponent(v)}`)
        .join('&');

      // 生成签名
      const signature = crypto
        .createHmac(config.hmacAlgorithm, creds.apiSecret)
        .update(queryString)
        .digest('hex');

      // 添加签名到 URL
      url.search = `${queryString}&signature=${signature}`;

      // 发送请求
      const headers: Record<string, string> = {
        'Content-Type': 'application/json',
      };

      if (config.signHeader) {
        headers[config.signHeader] = creds.apiKey;
      }

      const response = await fetch(url.toString(), {
        method: params.method,
        headers,
        body: params.body ? JSON.stringify(params.body) : undefined,
      });

      const data = await response.json();

      return {
        ok: response.ok,
        data,
        statusCode: response.status,
        duration: Date.now() - startTime,
      };
    } catch (error) {
      return {
        ok: false,
        error: error instanceof Error ? error.message : 'Unknown error',
        duration: Date.now() - startTime,
      };
    }
  }

  async testConnection(provider: string): Promise<{ ok: boolean; error?: string }> {
    const config = EXCHANGE_CONFIG[provider];

    if (!config) {
      return { ok: false, error: `Unsupported provider: ${provider}` };
    }

    // 使用一个简单的 API 端点测试连接
    try {
      const result = await this.signedRequest({
        provider,
        method: 'GET',
        path: '/api/v3/account',
        signed: true,
      });

      return { ok: result.ok, error: result.error };
    } catch (error) {
      return {
        ok: false,
        error: error instanceof Error ? error.message : 'Connection test failed',
      };
    }
  }
}
