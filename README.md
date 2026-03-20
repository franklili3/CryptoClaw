# CryptoClaw

> AI-Powered Crypto Trading Assistant - Chat-first, Local-first, Pay only on profit

[English](README.md) | [中文文档](README_CN.md)

## 📋 Requirements

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| **OS** | macOS 11+, Ubuntu 20.04+, Windows 10+ | macOS 13+, Ubuntu 22.04+ |
| **RAM** | 4 GB | 8 GB+ |
| **Disk** | 10 GB | 20 GB+ |
| **Docker** | 20.10+ | 24.0+ |
| **Architecture** | x86_64 (AMD64), ARM64 | - |

### Supported Architectures

CryptoClaw supports multiple CPU architectures:

| Architecture | Docker Platform | Compatible Devices |
|--------------|-----------------|-------------------|
| x86_64 | linux/amd64 | Intel/AMD PCs, Servers, Cloud VMs |
| ARM64 | linux/arm64 | Apple Silicon (M1/M2/M3), Raspberry Pi 4+, AWS Graviton |

## 🚀 Installation

### Method 1: One-Line Install (Recommended)

**macOS / Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/franklili3/CryptoClaw/main/scripts/install.sh | bash
```

**Windows (PowerShell Administrator):**
```powershell
irm https://raw.githubusercontent.com/franklili3/CryptoClaw/main/scripts/install.ps1 | iex
```

The installer will:
1. ✅ Detect your OS and CPU architecture automatically
2. ✅ Install Docker if not present
3. ✅ Pull the correct multi-architecture Docker image
4. ✅ Set up configuration files
5. ✅ Create management scripts

### Method 2: Manual Installation

#### Step 1: Install Docker

**macOS:**
```bash
# Using Homebrew
brew install --cask docker

# Or download from https://docs.docker.com/desktop/install/mac-install/
```

**Linux (Ubuntu/Debian):**
```bash
# Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Log out and back in for group changes
```

**Windows:**
Download and install [Docker Desktop](https://docs.docker.com/desktop/install/windows-install/)

#### Step 2: Clone Repository

```bash
git clone https://github.com/franklili3/CryptoClaw.git
cd CryptoClaw
```

#### Step 3: Run Installer

```bash
chmod +x scripts/install.sh
./scripts/install.sh
```

The installer will guide you through:
- Platform detection (auto-detects x86_64 or ARM64)
- Configuration wizard (Telegram Bot, LLM API)
- Docker image pull (correct architecture)

### Method 3: Docker Compose

```bash
# Clone repository
git clone https://github.com/franklili3/CryptoClaw.git
cd CryptoClaw

# Copy and edit configuration
cp ~/.cryptoclaw/config/.env.example ~/.cryptoclaw/config/.env
# Edit .env with your API keys

# Start services
docker-compose -f ~/.cryptoclaw/config/docker-compose.yml up -d
```

## ⚙️ Configuration

### 1. Create Telegram Bot

1. Open Telegram and search for **@BotFather**
2. Send `/newbot` command
3. Follow prompts to name your bot
4. Copy the token (format: `123456789:ABCdef...`)

### 2. Get LLM API Key

Choose one:

| Provider | Get API Key | Recommended Model |
|----------|-------------|-------------------|
| OpenAI | [platform.openai.com](https://platform.openai.com) | gpt-4 |
| Anthropic | [console.anthropic.com](https://console.anthropic.com) | claude-sonnet-4-5 |
| Local | Run local model | - |

### 3. Edit Configuration

```bash
nano ~/.cryptoclaw/config/.env
```

```env
# Required
TELEGRAM_BOT_TOKEN=123456789:ABCdef...

# LLM Configuration
LLM_PROVIDER=openai
LLM_API_KEY=sk-...
LLM_MODEL=gpt-4

# Exchange APIs (optional, for live trading)
# BINANCE_API_KEY=your_key
# BINANCE_API_SECRET=your_secret
```

## 🎮 Usage

### Start Service

```bash
~/.cryptoclaw/start.sh
```

### Check Status

```bash
~/.cryptoclaw/status.sh
```

### Stop Service

```bash
~/.cryptoclaw/stop.sh
```

### Update

```bash
~/.cryptoclaw/update.sh
```

### Telegram Commands

| Command | Description |
|---------|-------------|
| `/start` | Initialize bot |
| `/help` | Show help |
| `/backtest <strategy>` | Run backtest |
| `/trade <pair>` | Start paper trading |
| `/status` | Show portfolio |

## 🔧 Advanced

### Multi-Architecture Build

For developers building custom images:

```bash
# Build for current platform
./scripts/build-docker.sh --local

# Build multi-architecture (requires Docker Buildx)
./scripts/build-docker.sh --multi

# Build and push to registry
./scripts/build-docker.sh --multi --push

# Build for ARM64 only
./scripts/build-docker.sh --arm64 --local
```

### Docker Commands

```bash
# Pull specific architecture
docker pull --platform linux/amd64 cryptoclaw/cryptoclaw:latest
docker pull --platform linux/arm64 cryptoclaw/cryptoclaw:latest

# Run container
docker run -d \
  --name cryptoclaw \
  -p 8080:8080 \
  -v ~/.cryptoclaw/config:/app/config \
  -v ~/.cryptoclaw/user_data:/app/user_data \
  cryptoclaw/cryptoclaw:latest
```

## 🐛 Troubleshooting

### Architecture Mismatch

```bash
# Check your system architecture
uname -m
# x86_64 = AMD64
# aarch64 = ARM64

# Verify image architecture
docker inspect --format='{{.Architecture}}' cryptoclaw/cryptoclaw:latest
```

### Docker Not Running

```bash
# macOS: Open Docker Desktop
open -a Docker

# Linux: Start service
sudo systemctl start docker
```

### Network Issues

```bash
# Test connectivity
curl -s https://api.github.com | head -5

# Check Docker network
docker network ls
```

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


- 🐦 X: [@cryptoclawai](https://x.com/cryptoclawai)

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

*Built with ❤️ by the CryptoClaw Team*
