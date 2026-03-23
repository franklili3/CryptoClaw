# GitHub Repository Description

## Short Description (350 characters max - for repo description field)

---

**English:**

CryptoQClaw - AI-powered crypto quant trading assistant. Write strategies in natural language, trade via Telegram/WhatsApp chat. Free to use, pay 10% only on profit. Local-first architecture, your API keys never leave your device. Built with OpenClaw + Freqtrade.

---

**中文版:**

CryptoQClaw - AI 驱动的加密货币量化交易助手。用自然语言写策略，通过 Telegram/WhatsApp 对话交易。免费使用，有利润才付 10%。本地优先架构，API Key 永不上传。基于 OpenClaw + Freqtrade 构建。

---

## About Section (for README header)

---

### English

# CryptoQClaw 🦞

> Your AI quant trading team, right in your chat.

**CryptoQClaw** is an AI-powered cryptocurrency quantitative trading assistant that lets you write trading strategies in natural language and execute everything through Telegram or WhatsApp conversations.

## ✨ Features

- 🗣️ **Natural Language Strategies** - No coding required, just describe your strategy
- 📱 **Chat-First Interface** - Everything via Telegram/WhatsApp
- 📊 **One-Click Backtesting** - AI explains results in plain language
- 💰 **Pay Only on Profit** - Free to use, 10% fee only when you profit
- 🔐 **Local-First Privacy** - API keys encrypted locally, never uploaded
- 📈 **Built-in Strategies** - BTC/ETH mean reversion strategies included

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/franklili3/cryptoclaw.git

# Install dependencies
cd cryptoclaw
npm install

# Start the application
npm start
```

## 🏗️ Architecture

```
┌─────────────────┐     ┌─────────────────┐
│  Telegram/      │     │  Desktop Client │
│  WhatsApp Bot   │     │  (Electron)     │
│  (Chat UI)      │     │  (API Keys)     │
└────────┬────────┘     └────────┬────────┘
         │                       │
         └───────────┬───────────┘
                     │
         ┌───────────┴───────────┐
         │      OpenClaw         │
         │   (AI Agent)          │
         └───────────┬───────────┘
                     │
         ┌───────────┴───────────┐
         │     Freqtrade         │
         │   (Quant Engine)      │
         └───────────────────────┘
```

## 💼 Business Model

- ✅ **Free to use** - No subscription, no upfront cost
- ✅ **Pay only on profit** - 10% of profits, high watermark mechanism
- ✅ **No profit, no fee** - Losses and recovery periods are not charged

## 🔒 Privacy & Security

- 🔐 API keys stored locally with AES-256 encryption
- 🔐 Trading data never leaves your device
- 🔐 No cloud storage of sensitive information

## 🛠️ Tech Stack

| Component | Technology |
|-----------|------------|
| AI Agent | OpenClaw |
| Quant Engine | Freqtrade |
| Desktop | Electron |
| Cloud | Supabase |
| Messaging | Telegram Bot API |

## 📋 Roadmap

- [x] Requirements & Architecture Design
- [ ] MVP: Backtesting + Paper Trading
- [ ] Live Trading Integration
- [ ] Payment System
- [ ] More Strategies

## ⚠️ Disclaimer

This is a tool, not financial advice. Cryptocurrency trading carries significant risk. Past performance does not guarantee future results. Always do your own research.

## 📄 License

MIT License

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📞 Contact

- X (Twitter): [@cryptoclaw88](https://x.com/cryptoclaw88)
- GitHub: [franklili3/cryptoclaw](https://github.com/franklili3/cryptoclaw)

---

# Build in Public 🚀

Follow the development journey on X: #BuildInPublic #CryptoQClaw

---

### 中文版

# CryptoQClaw 🦞

> 你的 AI 量化交易团队，就在聊天里。

**CryptoQClaw** 是一个 AI 驱动的加密货币量化交易助手，让你用自然语言编写交易策略，通过 Telegram 或 WhatsApp 对话完成所有操作。

## ✨ 特性

- 🗣️ **自然语言策略** - 不需要编程，描述你的策略即可
- 📱 **对话优先界面** - 一切通过 Telegram/WhatsApp 完成
- 📊 **一键回测** - AI 用通俗语言解释结果
- 💰 **有利润才付费** - 免费使用，盈利才收 10%
- 🔐 **本地优先隐私** - API Key 本地加密，永不上传
- 📈 **内置策略** - 包含 BTC/ETH 均值回归策略

## 🚀 快速开始

```bash
# 克隆仓库
git clone https://github.com/franklili3/cryptoclaw.git

# 安装依赖
cd cryptoclaw
npm install

# 启动应用
npm start
```

## 💼 商业模式

- ✅ **免费使用** - 无订阅费，无预付费用
- ✅ **有利润才付费** - 利润的 10%，高水位机制
- ✅ **无利润不收费** - 亏损和回本期间不收费

## 🔒 隐私与安全

- 🔐 API Key 本地 AES-256 加密存储
- 🔐 交易数据永不离开你的设备
- 🔐 敏感信息不上云

## 🛠️ 技术栈

| 组件 | 技术 |
|------|------|
| AI 代理 | OpenClaw |
| 量化引擎 | Freqtrade |
| 桌面客户端 | Electron |
| 云服务 | Supabase |
| 消息渠道 | Telegram Bot API |

## ⚠️ 免责声明

这是工具，不是投资建议。加密货币交易风险巨大。历史收益不代表未来表现。请自行研究。

## 📄 许可证

MIT License

---

# 公开构建 🚀

在 X 上关注开发历程：#BuildInPublic #CryptoQClaw
