/**
 * SecureVault - 统一安全存储接口
 *
 * 支持两种模式:
 * 1. TEE (可信执行环境) - 最高安全性，密钥在硬件隔离环境中
 * 2. Local - 本地 AES-256-GCM 加密存储
 *
 * 使用方法:
 * ```typescript
 * import { createVault } from './secure-vault';
 *
 * const vault = await createVault({ preferredType: 'tee' });
 *
 * // 存储凭证
 * await vault.storeCredential({
 *   provider: 'binance',
 *   apiKey: 'xxx',
 *   apiSecret: 'yyy',
 * });
 *
 * // 执行签名请求 (密钥不暴露给调用者)
 * const result = await vault.signedRequest({
 *   provider: 'binance',
 *   method: 'GET',
 *   path: '/api/v3/account',
 * });
 * ```
 */

import type { SecureVault, VaultFactoryConfig, VaultType } from './types.js';
import { LocalVault } from './local-vault.js';

export * from './types.js';
export { LocalVault } from './local-vault.js';

/**
 * 创建 SecureVault 实例
 *
 * 会自动选择最佳可用模式:
 * 1. 如果配置了 TEE 且可用 -> TeeVault
 * 2. 否则 -> LocalVault
 */
export async function createVault(config: VaultFactoryConfig): Promise<SecureVault> {
  // TODO: 实现自动选择逻辑
  // if (config.preferredType === 'tee') {
  //   const { TeeVault } = await import('./tee-vault.js');
  //   const teeVault = await TeeVault.probe(config.tee);
  //   if (teeVault) return teeVault;
  // }

  // 降级到本地存储
  return new LocalVault(config.localEncryptionKey);
}

/**
 * 探测可用的 Vault 类型
 */
export async function probeAvailableVaultTypes(): Promise<{
  tee: boolean;
  local: boolean;
}> {
  // TODO: 检查 TEE 可用性
  const teeAvailable = false;

  return {
    tee: teeAvailable,
    local: true, // LocalVault 始终可用
  };
}

/**
 * 获取默认 Vault 实例
 */
let defaultVault: SecureVault | null = null;

export function getDefaultVault(): SecureVault {
  if (!defaultVault) {
    defaultVault = new LocalVault();
  }
  return defaultVault;
}

export function setDefaultVault(vault: SecureVault): void {
  defaultVault = vault;
}
