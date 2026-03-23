# CryptoQClaw × TermiX-official/cryptoclaw 集成计划

> 基于 2026-03-20 分析，分阶段引入 TermiX 项目的优秀特性

## 📊 当前项目状态

| 组件 | 状态 | 说明 |
|------|------|------|
| Docker 部署 | ✅ 完成 | 多架构支持 (amd64/arm64) |
| Freqtrade Skill | ✅ 基础版 | 策略生成、回测、交易 |
| Telegram Bot | ✅ 配置完成 | 基本命令 |
| LLM 集成 | ✅ 多提供商 | OpenAI/Anthropic/DeepSeek/Custom |
| 计费系统 | 🔄 设计中 | 10% profit fee 模型 |

---

## 🎯 集成路线图

### Phase 1: Binance Skills Hub 集成 (1-2 周) 🔴 高优先级

**目标**: 直接获得 Binance 官方支持的 CEX/Web3 能力

#### 1.1 安装 Binance Skills Hub

```bash
# 在项目根目录执行
cd ~/clawd/CryptoQClaw
npx skills add https://github.com/binance/binance-skills-hub
```

#### 1.2 配置 Binance API

更新 `.env`:
```env
# Binance API (从 Binance 账户获取)
BINANCE_API_KEY=your_key
BINANCE_API_SECRET=your_secret

# 可选：代理设置（中国用户）
BINANCE_PROXY=http://127.0.0.1:7890
```

#### 1.3 可获得的 Skills

| Skill | 功能 | 价值 |
|-------|------|------|
| `binance-spot` | 现货交易 | 60+ API 端点 |
| `binance-market-rank` | 热门代币排行 | 趋势发现 |
| `binance-token-info` | 代币信息 | K线、元数据 |
| `binance-token-audit` | 安全审计 | 防蜜罐/Rug Pull |
| `binance-trading-signal` | 聪明钱信号 | BSC + Solana |
| `binance-address-info` | 钱包查询 | 持仓分析 |
| `binance-meme-rush` | Meme 代币追踪 | Pump.fun 等 |

#### 1.4 交付物

- [ ] `skills/binance/` 目录
- [ ] 环境变量配置文档
- [ ] Telegram 命令扩展
- [ ] 测试用例

---

### Phase 2: TEE 安全架构 (2-3 周) 🔴 高优先级

**目标**: 保护交易所 API 密钥，防止服务器入侵泄露

#### 2.1 架构设计

```
┌─────────────────────────────────────────────────────┐
│                  CryptoQClaw Gateway                  │
│                                                     │
│  ┌─────────────┐    gRPC     ┌─────────────────┐   │
│  │   Node.js   │ ◄─────────► │   TEE Enclave   │   │
│  │   主进程     │             │   (Rust/Go)     │   │
│  └─────────────┘             └─────────────────┘   │
│        │                            │              │
│        │                    ┌───────┴───────┐      │
│        │                    │  加密存储:     │      │
│        │                    │  - API Keys   │      │
│        │                    │  - Secrets    │      │
│        │                    │  - 私钥        │      │
│        │                    └───────────────┘      │
└─────────────────────────────────────────────────────┘
```

#### 2.2 实现步骤

1. **创建 `src/secure-vault/` 目录结构**

```
src/secure-vault/
├── index.ts           # 统一导出
├── types.ts           # 接口定义
├── local-vault.ts     # 本地降级方案
├── tee-vault.ts       # TEE 实现
└── enclave/           # 飞地服务
    ├── server.ts      # gRPC 服务
    └── Dockerfile     # 飞地镜像
```

2. **核心接口**

```typescript
// types.ts
export interface SecureVault {
  isAvailable(): boolean;
  storeCredential(provider: string, creds: EncryptedCreds): Promise<void>;
  signedRequest(params: SignedRequestParams): Promise<SignedRequestResult>;
  getAttestation(): Promise<AttestationReport>;
}
```

3. **支持的 TEE 平台**

| 平台 | 实现方式 | 部署环境 |
|------|----------|----------|
| Intel SGX | Gramine | 本地服务器 |
| AWS Nitro | EIF 镜像 | AWS EC2 |
| Phala dStack | CVM | Phala 网络 |
| 本地开发 | 无隔离 | 测试环境 |

#### 2.3 配置项

```yaml
# cryptoclaw.yaml
tee:
  enabled: true
  endpoint: http://localhost:3443
  transport: grpc  # vsock | unix | grpc
  mrenclave: ""    # 可选：预期代码哈希
```

#### 2.4 交付物

- [ ] `src/secure-vault/` 完整实现
- [ ] 本地开发模式（无 TEE）
- [ ] Intel SGX 支持
- [ ] 文档和部署指南

---

### Phase 3: 扩展 Skills 生态 (2-3 周) 🟡 中优先级

**目标**: 增加 DeFi、链上数据、DEX 交易能力

#### 3.1 新增 Skills

```
skills/
├── binance/           # Phase 1
├── freqtrade/         # 现有
├── billing/           # 现有
├── hyperliquid/       # 新增: 永续合约 DEX
├── defillama/         # 新增: TVL 分析
├── whale-watcher/     # 新增: 巨鲸监控
├── coingecko/         # 新增: 市场数据
├── dune/              # 新增: 链上分析
└── wallet-manager/    # 新增: 多链钱包
```

#### 3.2 每个 Skill 的标准结构

```
skills/<name>/
├── SKILL.md           # 必需: 元数据 + 指令
├── scripts/           # 可选: 脚本
│   └── main.sh
├── references/        # 可选: 参考资料
│   └── api-docs.md
└── tests/             # 可选: 测试
    └── skill.test.ts
```

#### 3.3 优先级排序

| Skill | 优先级 | 理由 |
|-------|--------|------|
| hyperliquid | 🔴 高 | 永续合约，Freqtrade 支持 |
| defillama | 🟡 中 | TVL 数据，策略参考 |
| coingecko | 🟡 中 | 价格数据，基础功能 |
| whale-watcher | 🟢 低 | 高级功能，锦上添花 |
| dune | 🟢 低 | 高级分析，小众需求 |

---

### Phase 4: zkVM 验证器 (3-4 周) 🟡 中优先级

**目标**: 为策略执行提供零知识证明

#### 4.1 应用场景

1. **策略审计证明**
   - 证明策略逻辑未被篡改
   - 验证回测结果真实性

2. **合规报告**
   - 零知识证明交易符合预设规则
   - 不暴露具体持仓信息

3. **ERC-8183 任务验证**
   - 作为 Evaluator 验证第三方任务
   - 收取验证费用

#### 4.2 架构

```
┌─────────────────────────────────────────────────┐
│                  zkVM Executor                   │
│                                                  │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐    │
│  │   SP1    │   │ RISC Zero│   │  Native  │    │
│  │(Succinct)│   │          │   │ (dev)    │    │
│  └────┬─────┘   └────┬─────┘   └────┬─────┘    │
│       │              │              │           │
│       └──────────────┴──────────────┘           │
│                      │                          │
│              ┌───────┴───────┐                  │
│              │  ZK Proof     │                  │
│              │  - 程序哈希    │                  │
│              │  - 输入哈希    │                  │
│              │  - 执行结果    │                  │
│              └───────────────┘                  │
└─────────────────────────────────────────────────┘
```

#### 4.3 验证程序示例

```rust
// strategies/verification/strategy_audit.rs
fn main() {
    let strategy_code = read_stdin();
    let backtest_results = read_env("BACKTEST_RESULTS");
    
    // 验证策略逻辑
    if !verify_strategy_logic(&strategy_code) {
        println!("FAIL: Invalid strategy logic");
        std::process::exit(1);
    }
    
    // 验证回测结果
    if !verify_backtest(&strategy_code, &backtest_results) {
        println!("FAIL: Backtest mismatch");
        std::process::exit(1);
    }
    
    println!("PASS: Strategy verified");
    std::process::exit(0);
}
```

#### 4.4 交付物

- [ ] `src/zkvm/` 实现框架
- [ ] SP1 后端集成
- [ ] RISC Zero 后端集成
- [ ] 策略验证程序模板
- [ ] 文档和示例

---

### Phase 5: ERC-8183 Agentic Commerce (4-6 周) 🟢 低优先级

**目标**: 实现链上任务托管，支持自动化策略付费

#### 5.1 智能合约集成

```solidity
// ACPCore 合约接口 (Base Mainnet)
interface IACPCore {
    function createJob(
        bytes32 jobId,
        address evaluator,
        uint256 deadline,
        string calldata description
    ) external;
    
    function fundJob(bytes32 jobId) external payable;
    
    function completeJob(bytes32 jobId, bytes calldata proof) external;
    
    function rejectJob(bytes32 jobId, string calldata reason) external;
}
```

#### 5.2 CryptoQClaw 作为 Evaluator

```
用户发布任务 → 锁定 USDC → 策略提供者提交 → CryptoQClaw 验证 → 自动结算
```

#### 5.3 验证模式

| 模式 | 适用场景 | 信任模型 |
|------|----------|----------|
| zkVM | 自动化验证 | 零信任 |
| TEE | LLM 评估 | 硬件信任 |
| Manual | 人工审核 | 操作员信任 |

---

## ✅ 已完成

| 任务 | 状态 | 日期 |
|------|------|------|
| Binance Skills Hub 安装 | ✅ 完成 | 2026-03-20 |
| TEE 安全模块基础框架 | ✅ 完成 | 2026-03-20 |
| Hyperliquid Skill | ✅ 完成 | 2026-03-20 |
| DeFiLlama Skill | ✅ 完成 | 2026-03-20 |
| Gateway 集成 | ✅ 完成 | 2026-03-20 |
| 集成计划文档 | ✅ 完成 | 2026-03-20 |

### 新增文件结构

```
CryptoQClaw/
├── src/secure-vault/           # TEE 安全模块
│   ├── types.ts                # 接口定义
│   ├── local-vault.ts          # 本地加密存储
│   └── index.ts                # 统一导出
├── gateway/
│   ├── src/
│   │   ├── server.ts           # 更新: Skills API + SecureVault API
│   │   ├── skills-loader.ts    # 新增: Skills 动态加载器
│   │   └── secure-vault/       # 复制: 安全模块
│   └── skills/
│       ├── hyperliquid/        # 新增
│       ├── defillama/          # 新增
│       ├── freqtrade/          # 现有
│       └── trading-signals/    # 现有
├── skills/
│   ├── hyperliquid/            # 新增: Hyperliquid DEX
│   ├── defillama/              # 新增: DeFi 数据分析
│   ├── [20+ Binance skills]    # Binance 官方 Skills (符号链接)
│   ├── freqtrade/              # 现有
│   └── billing/                # 现有
└── docs/
    └── integration-plan.md     # 本文档
```

### Gateway API 端点

| 端点 | 方法 | 说明 |
|------|------|------|
| `/health` | GET | 健康检查 |
| `/api/status` | GET | 服务状态 |
| `/api/skills` | GET | 获取所有 skills |
| `/api/skills/:name` | GET | 检查 skill 是否存在 |
| `/api/vault/credentials` | POST | 存储 API 凭证 |
| `/api/vault/credentials/:provider` | GET | 获取凭证状态 (脱敏) |
| `/api/vault/credentials/:provider` | DELETE | 删除凭证 |
| `/api/vault/test/:provider` | POST | 测试 API 连接 |
| `/api/vault/request` | POST | 执行签名请求 |
| `/api/vault/attestation` | GET | 获取 TEE 认证报告 |

## 📅 时间线

```
Week 1-2:  Phase 1 - Binance Skills Hub ✅
Week 3-5:  Phase 2 - TEE 安全架构 ✅ (基础框架)
Week 6-8:  Phase 3 - 扩展 Skills (hyperliquid ✅, defillama, coingecko)
Week 9-12: Phase 4 - zkVM 验证器
Week 13+:  Phase 5 - ERC-8183 Commerce
```

---

## 🛠️ 开发规范

### 代码风格

- TypeScript + ESLint
- 测试覆盖率 > 80%
- JSDoc 注释

### Skill 开发规范

```markdown
---
name: skill-name
description: "简短描述，用于触发条件"
metadata:
  openclaw:
    emoji: "📊"
    requires:
      bins: ["required-cli"]
---

# Skill Title

## 身份
你的角色定义...

## 能力
- 能力1
- 能力2

## 使用示例
...

## 注意事项
...
```

### 安全规范

1. 所有敏感操作需要用户确认
2. API 密钥加密存储
3. 命令执行白名单
4. 输入验证和消毒

---

## 📚 参考资源

- [TermiX-official/cryptoclaw](https://github.com/TermiX-official/cryptoclaw)
- [Binance Skills Hub](https://github.com/binance/binance-skills-hub)
- [SP1 zkVM](https://github.com/succinctlabs/sp1)
- [RISC Zero](https://github.com/risc0/risc0)
- [ERC-8183 Spec](https://eips.ethereum.org/EIPS/eip-8183)

---

*文档版本: 1.0.0 | 创建日期: 2026-03-20*
