# CryptoClaw

> AI-Powered Crypto Trading Assistant - Chat-first, Local-first, Pay only on profit

[English](README.md) | [中文文档](docs/README_CN.md)

## 🚀 Quick Start

### One-Line Installation

**macOS / Linux:**
```bash
curl -fsSL cryptoclaw.pro/install.sh | bash
```

**Windows (PowerShell):**
```powershell
irm cryptoclaw.pro/install.ps1 | iex
```

### Manual Installation

1. **Prerequisites**
   - Docker Desktop installed and running
   - Telegram account

2. **Clone and Setup**
   ```bash
   git clone https://github.com/franklili3/CryptoClaw.git
   cd CryptoClaw
   ./scripts/install.sh
   ```

3. **Configure**
   ```bash
   ~/.cryptoclaw/start.sh
   ```

4. **Start Using**
   - Search for your bot on Telegram
   - Send `/start` to begin

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🤖 **Chat-First** | All trading operations via Telegram/WhatsApp |
| 🔐 **Local-First** | Your API keys stay on your device (AES-256 encrypted) |
| 💰 **Pay on Profit** | 10% fee only when you make profit |
| 📊 **Backtesting** | Test strategies with historical data |
| 📈 **Paper Trading** | Practice without real money |
| ⚡ **Live Trading** | Execute trades automatically |

## 📁 Project Structure

```
CryptoClaw/
├── docs/                    # Documentation
│   ├── requirement.md       # Product Requirements (CN)
│   ├── requirement_en.md    # Product Requirements (EN)
│   ├── design.md            # Design Document (CN)
│   ├── design_en.md         # Design Document (EN)
│   ├── technical-spec.md    # Technical Spec (CN)
│   └── technical-spec_en.md # Technical Spec (EN)
├── scripts/                 # Installation scripts
│   ├── install.sh           # macOS/Linux installer
│   ├── install.ps1          # Windows installer
│   └── init-config.sh       # Configuration wizard
├── skills/                  # OpenClaw Skills
│   ├── freqtrade/           # Trading skill
│   └── billing/             # Billing skill
├── tests/                   # Test scripts
└── installer/               # Desktop installer (coming soon)
```

## 🛠️ Tech Stack

| Component | Technology |
|-----------|------------|
| AI Agent | OpenClaw |
| Quant Engine | Freqtrade |
| Desktop Client | Electron |
| Cloud Services | Supabase (minimal) |

## 📚 Documentation

- [Product Requirements](docs/requirement_en.md)
- [Design Document](docs/design_en.md)
- [Technical Specification](docs/technical-spec_en.md)

## 🔗 Links

- 🌐 Website: [cryptoclaw.pro](https://cryptoclaw.pro)
- 📖 Docs: [docs.cryptoclaw.pro](https://docs.cryptoclaw.pro)
- 💬 Telegram: [@CryptoClawBot](https://t.me/CryptoClawBot)
- 🐦 Twitter: [@cryptoclaw88](https://twitter.com/cryptoclaw88)

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

*Built with ❤️ by the CryptoClaw Team*
