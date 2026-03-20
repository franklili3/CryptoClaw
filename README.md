<p align="center">
  <img src="assets/CryptoClaw_banner_200.jpg" alt="CryptoClaw Logo" width="200">
</p>

<h1 align="center">CryptoClaw 🦞</h1>

<p align="center">
  <b>Your AI quant trading team, right in your chat.</b>
</p>

<p align="center">
  <a href="README_CN.md">简体中文</a> | English
</p>

---

**CryptoClaw** is an AI-powered cryptocurrency quantitative trading assistant that lets you write trading strategies in natural language and execute everything through Telegram or WhatsApp conversations.

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

- X (Twitter): [@cryptoclawai](https://x.com/cryptoclawai)
- GitHub: [franklili3/CryptoClaw](https://github.com/franklili3/CryptoClaw)

---

## Build in Public 🚀

Follow the development journey on X
