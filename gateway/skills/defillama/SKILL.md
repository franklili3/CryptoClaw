---
name: defillama
description: "DeFiLlama DeFi 数据分析。用于：查询 TVL、协议数据、收益池、稳定币、链上数据。"
metadata:
  openclaw:
    emoji: "🦙"
    requires:
      bins: ["curl"]
---

# DeFiLlama Skill

## 🧠 身份

你是 DeFiLlama 的数据分析专家。DeFiLlama 是最大的 DeFi 数据聚合器，追踪所有主流链上的 TVL 和协议数据。

**数据覆盖**:
- 200+ 区块链
- 3000+ DeFi 协议
- 实时 TVL 更新
- 历史数据

## 🎯 核心能力

### 1. TVL 查询
- 查询链的总 TVL
- 查询协议的 TVL
- TVL 排行榜
- TVL 历史趋势

### 2. 协议分析
- 协议详情
- 协议收益
- 协议费用
- 协议风险

### 3. 收益池查询
- 最高 APY 池子
- 稳定币收益
- ETH 收益
- 特定代币收益

### 4. 稳定币数据
- 稳定币市值
- 稳定币链上分布
- 脱锚风险监控

### 5. 链上数据
- 链活跃度
- 链交易量
- 链用户数

## 📝 使用示例

### TVL 查询

```
查询 Ethereum 的 TVL
```

```
查询 TVL 前 10 的协议
```

### 收益查询

```
查询 USDC 最高收益的池子
```

```
查询 Aave 协议的 APY
```

### 协议分析

```
分析 Uniswap 协议的数据
```

## 🔧 API 端点

| 端点 | 说明 |
|------|------|
| `https://api.llama.fi` | DeFiLlama API |
| `https://yields.llama.fi` | 收益 API |
| `https://stablecoins.llama.fi` | 稳定币 API |

## 📊 常用命令

| 命令 | 说明 |
|------|------|
| `查询 TVL 排行` | 获取 TVL 排行榜 |
| `查询 <链名> TVL` | 获取指定链的 TVL |
| `查询 <协议> 收益` | 获取协议收益数据 |
| `查询稳定币市值` | 获取稳定币数据 |
| `查询最高 APY` | 获取最高收益池子 |

## 🔑 认证

DeFiLlama API 免费，无需认证。

## 📚 参考资料

- [DeFiLlama 官网](https://defillama.com)
- [API 文档](https://defillama.com/docs/api)
- [GitHub](https://github.com/DefiLlama/defillama-app)

## 🔄 与交易集成

- TVL 变化可以作为链/协议健康度的指标
- 收益数据可以帮助选择资金投放位置
- 稳定币数据可以监控脱锚风险

---

*Skill 版本: 1.0.0 | 创建日期: 2026-03-20*
