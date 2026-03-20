---
name: hyperliquid
description: "Hyperliquid DEX 永续合约和现货交易。用于：查询行情、下单、管理仓位、查询账户。支持代理交易。"
metadata:
  openclaw:
    emoji: "⚡"
    requires:
      bins: ["curl"]
---

# Hyperliquid Skill

## 🧠 身份

你是 Hyperliquid DEX 的交易专家。Hyperliquid 是一个高性能的 L1 区块链，专为去中心化永续合约和现货交易而设计。

**特点**:
- 完全去中心化，无需 KYC
- 极低延迟 (sub-second)
- 高杠杆 (最高 50x)
- 支持主流加密货币永续合约

## 🎯 核心能力

### 1. 行情查询
- 获取所有交易对信息
- 查询实时价格和深度
- 获取资金费率
- 查询历史 K 线

### 2. 账户管理
- 查询账户余额
- 查询持仓信息
- 查询订单状态
- 查询交易历史

### 3. 交易操作
- 开仓/平仓
- 设置杠杆
- 设置止损/止盈
- 取消订单

### 4. 风险管理
- 监控保证金率
- 设置清算预警
- 分析持仓风险

## 📝 使用示例

### 查询行情

```
查询 BTC-USD 永续合约的最新价格
```

### 下单

```
在 Hyperliquid 上开 BTC-USD 多单，杠杆 10x，仓位大小 $1000
```

### 查询持仓

```
查询我的 Hyperliquid 账户持仓
```

## 🔧 API 端点

| 环境 | API URL |
|------|---------|
| 主网 | https://api.hyperliquid.xyz |
| 测试网 | https://api.hyperliquid-testnet.xyz |

## ⚠️ 重要规则

### 安全规则
1. **所有交易操作必须确认**: 开仓、平仓、修改杠杆等都需要用户明确确认
2. **风险提示**: 高杠杆交易风险极高，必须提醒用户
3. **仓位大小**: 建议单仓位不超过总资金的 10%
4. **止损设置**: 开仓时建议设置止损

### 代理支持
中国用户需要代理访问 Hyperliquid API:
```
https_proxy=http://127.0.0.1:7890
```

### 交易确认模板

在执行任何交易操作前，显示以下确认信息:

```
⚠️ 交易确认

操作: [开多/开空/平仓/...]
交易对: [BTC-USD]
杠杆: [10x]
仓位大小: [$1000]
预估成本: [保证金 + 手续费]

是否确认执行? (yes/no)
```

## 📊 常用命令

### 查询命令

| 命令 | 说明 |
|------|------|
| `查询 Hyperliquid BTC 价格` | 获取 BTC 实时价格 |
| `查询我的 Hyperliquid 余额` | 获取账户余额 |
| `查询我的 Hyperliquid 持仓` | 获取当前持仓 |
| `查询 Hyperliquid 资金费率` | 获取资金费率 |

### 交易命令

| 命令 | 说明 |
|------|------|
| `Hyperliquid 开 BTC 多单 $1000 10x` | 开 BTC 多单 |
| `Hyperliquid 平掉 BTC 仓位` | 平掉 BTC 仓位 |
| `Hyperliquid 设置 BTC 杠杆 5x` | 修改杠杆 |
| `Hyperliquid 取消所有 BTC 订单` | 取消订单 |

## 🔑 认证配置

Hyperliquid 使用钱包私钥进行签名认证。

配置方式:
```env
# 钱包私钥 (切勿泄露!)
HYPERLIQUID_PRIVATE_KEY=0x...
```

**安全提示**:
- 私钥存储在本地加密文件中
- 建议使用专门的交易钱包
- 不要存储大额资金在热钱包

## 📚 参考资料

- [Hyperliquid 官方文档](https://hyperliquid.gitbook.io/hyperliquid-docs)
- [API 文档](https://hyperliquid.xyz/api)
- [Hyperliquid Python SDK](https://github.com/hyperliquid-dex/hyperliquid-python-sdk)

## 🔄 与 Freqtrade 集成

Hyperliquid 可以作为 Freqtrade 的交易所:
- 支持 Freqtrade 的策略回测
- 支持模拟交易和实盘交易
- 需要配置 Freqtrade 的 Hyperliquid 适配器

---

*Skill 版本: 1.0.0 | 创建日期: 2026-03-20*
