/**
 * SecureVault Types - 安全库接口定义
 *
 * 参考: TermiX-official/cryptoclaw/src/secure-vault/types.ts
 */

/**
 * 加密的凭证数据
 */
export interface EncryptedCredentials {
  /** 加密后的数据 (Base64) */
  ciphertext: string;
  /** 初始化向量 (Base64) */
  iv: string;
  /** 认证标签 (AES-GCM, Base64) */
  authTag?: string;
  /** 加密算法 */
  algorithm: 'AES-256-GCM' | 'AES-128-GCM';
  /** 创建时间 */
  createdAt: number;
  /** 过期时间 (可选) */
  expiresAt?: number;
}

/**
 * 存储凭证参数
 */
export interface StoreCredentialParams {
  /** 提供商标识 (e.g., 'binance', 'okx', 'hyperliquid') */
  provider: string;
  /** API Key */
  apiKey: string;
  /** API Secret */
  apiSecret: string;
  /** 附加数据 (可选，如 passphrase) */
  extra?: Record<string, string>;
}

/**
 * 签名请求参数
 */
export interface SignedRequestParams {
  /** 提供商标识 */
  provider: string;
  /** HTTP 方法 */
  method: 'GET' | 'POST' | 'PUT' | 'DELETE';
  /** API 路径 (e.g., '/api/v3/account') */
  path: string;
  /** 查询参数 */
  params?: Record<string, string | number | boolean>;
  /** 请求体 (POST/PUT) */
  body?: Record<string, unknown>;
  /** 是否需要签名 */
  signed?: boolean;
}

/**
 * 签名请求结果
 */
export interface SignedRequestResult {
  /** 是否成功 */
  ok: boolean;
  /** 响应数据 */
  data?: unknown;
  /** 错误信息 */
  error?: string;
  /** HTTP 状态码 */
  statusCode?: number;
  /** 请求耗时 (ms) */
  duration?: number;
}

/**
 * TEE 认证报告
 */
export interface AttestationReport {
  /** TEE 平台 */
  platform: 'intel-sgx' | 'aws-nitro' | 'phala-dstack' | 'marlin-oyster' | 'none';
  /** 代码哈希 (MRENCLAVE) */
  mrenclave?: string;
  /** 认证数据 */
  attestation?: string;
  /** 认证时间 */
  timestamp: number;
  /** 是否有效 */
  valid: boolean;
}

/**
 * TEE 配置 (从配置文件读取)
 */
export interface TeeConfig {
  /** TEE 端点 */
  endpoint?: string;
  /** 传输协议 */
  transport?: 'vsock' | 'unix' | 'grpc';
  /** 预期的 MRENCLAVE (可选) */
  mrenclave?: string;
  /** 连接超时 (ms) */
  timeoutMs?: number;
}

/**
 * SecureVault 接口
 */
export interface SecureVault {
  /**
   * 检查安全库是否可用
   */
  isAvailable(): boolean;

  /**
   * 获取 TEE 认证报告
   */
  getAttestation(): Promise<AttestationReport>;

  /**
   * 存储凭证
   */
  storeCredential(params: StoreCredentialParams): Promise<void>;

  /**
   * 获取凭证 (返回脱敏版本)
   */
  getCredential(provider: string): Promise<{ exists: boolean; maskedKey?: string }>;

  /**
   * 删除凭证
   */
  deleteCredential(provider: string): Promise<void>;

  /**
   * 执行签名请求
   */
  signedRequest(params: SignedRequestParams): Promise<SignedRequestResult>;

  /**
   * 测试连接
   */
  testConnection(provider: string): Promise<{ ok: boolean; error?: string }>;
}

/**
 * Vault 类型
 */
export type VaultType = 'tee' | 'local';

/**
 * Vault 工厂配置
 */
export interface VaultFactoryConfig {
  /** 首选类型 */
  preferredType: VaultType;
  /** TEE 配置 (当 preferredType='tee' 时使用) */
  tee?: TeeConfig;
  /** 本地加密密钥 (当 preferredType='local' 时使用) */
  localEncryptionKey?: string;
}
