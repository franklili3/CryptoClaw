<p align="center">
  <img src="assets/CryptoClaw_banner_200.jpg" alt="CryptoClaw Logo" width="200">
</p>

<h1 align="center">CryptoClaw 🦞</h1>

<p align="center">
  <b>你的 AI 量化交易团队，就在聊天里。</b>
</p>

<p align="center">
  简体中文 | <a href="README.md">English</a>
</p>

---

**CryptoClaw** 是一个 AI 驱动的加密货币量化交易助手，让你用自然语言编写交易策略，通过 Telegram 或 WhatsApp 对话完成所有操作。

## ✨ 特性

- 🗣️ **自然语言策略** - 不需要编程，描述你的策略即可
- 📱 **对话优先界面** - 一切通过 Telegram/WhatsApp 完成
- 📊 **一键回测** - AI 用通俗语言解释结果
- 💰 **有利润才付费** - 免费使用，盈利才收 10%
- 🔐 **本地优先隐私** - API Key 本地加密，永不上传
- 📈 **内置策略** - 包含 BTC/ETH 均值回归策略

## 📋 系统要求

| 要求 | 最低配置 | 推荐配置 |
|------|----------|----------|
| **操作系统** | macOS 11+, Ubuntu 20.04+, Windows 10+ | macOS 13+, Ubuntu 22.04+ |
| **内存** | 4 GB | 8 GB+ |
| **磁盘** | 10 GB | 20 GB+ |
| **Docker** | 20.10+ | 24.0+ |
| **架构** | x86_64 (AMD64), ARM64 | - |

### 支持的架构

CryptoClaw 支持多种 CPU 架构：

| 架构 | Docker 平台 | 兼容设备 |
|------|-------------|----------|
| x86_64 | linux/amd64 | Intel/AMD 电脑、服务器、云主机 |
| ARM64 | linux/arm64 | Apple Silicon (M1/M2/M3)、树莓派 4+、AWS Graviton |

## 🚀 安装指南

### 方式一：一键安装（推荐）

**macOS / Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/franklili3/CryptoClaw/main/scripts/install.sh | bash
```

**Windows (PowerShell 管理员):**
```powershell
irm https://raw.githubusercontent.com/franklili3/CryptoClaw/main/scripts/install.ps1 | iex
```

安装程序会自动：
1. ✅ 检测操作系统和 CPU 架构
2. ✅ 检测网络区域（中国大陆自动使用镜像加速）
3. ✅ 安装 Docker（如果未安装）
4. ✅ 拉取正确的多架构 Docker 镜像
5. ✅ 设置配置文件
6. ✅ 创建管理脚本

### 🇨🇳 国内镜像加速

安装脚本会自动检测网络环境：
- **中国大陆用户** → 使用 `hub.dockermirror.com` 镜像加速
- **海外用户** → 使用 Docker Hub 官方源

也可以手动指定镜像源：

```bash
# 国内用户手动拉取（如果自动检测失败）
docker pull hub.dockermirror.com/cryptoclaw/cryptoclaw:latest
docker tag hub.dockermirror.com/cryptoclaw/cryptoclaw:latest cryptoclaw/cryptoclaw:latest

# 或配置 Docker 镜像加速器
# 编辑 /etc/docker/daemon.json
{
  "registry-mirrors": [
    "https://hub.dockermirror.com"
  ]
}
```

### 方式二：手动安装

#### 步骤 1：安装 Docker

**macOS:**
```bash
# 使用 Homebrew
brew install --cask docker

# 或从官网下载 https://docs.docker.com/desktop/install/mac-install/
```

**Linux (Ubuntu/Debian):**
```bash
# 安装 Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# 注销并重新登录以生效
```

**Windows:**
下载并安装 [Docker Desktop](https://docs.docker.com/desktop/install/windows-install/)

#### 步骤 2：克隆仓库

```bash
git clone https://github.com/franklili3/CryptoClaw.git
cd CryptoClaw
```

#### 步骤 3：运行安装程序

```bash
chmod +x scripts/install.sh
./scripts/install.sh
```

安装程序会引导你完成：
- 平台检测（自动检测 x86_64 或 ARM64）
- 配置向导（Telegram Bot、LLM API）
- Docker 镜像拉取（正确架构）

### 方式三：Docker Compose

```bash
# 克隆仓库
git clone https://github.com/franklili3/CryptoClaw.git
cd CryptoClaw

# 复制并编辑配置
mkdir -p ~/.cryptoclaw/config
cp scripts/../templates/.env.example ~/.cryptoclaw/config/.env
# 编辑 .env 填入你的 API keys

# 启动服务
docker-compose -f ~/.cryptoclaw/config/docker-compose.yml up -d
```

## ⚙️ 配置

### 1. 创建 Telegram Bot

1. 打开 Telegram 搜索 **@BotFather**
2. 发送 `/newbot` 命令
3. 按提示设置 Bot 名称
4. 复制获得的 Token（格式：`123456789:ABCdef...`）

### 2. 获取 LLM API Key

任选其一：

| 提供商 | 获取 API Key | 推荐模型 |
|--------|-------------|----------|
| OpenAI | [platform.openai.com](https://platform.openai.com) | gpt-4 |
| Anthropic | [console.anthropic.com](https://console.anthropic.com) | claude-sonnet-4-5 |
| 本地模型 | 运行本地模型 | - |

### 3. 编辑配置文件

```bash
nano ~/.cryptoclaw/config/.env
```

```env
# 必填
TELEGRAM_BOT_TOKEN=123456789:ABCdef...

# LLM 配置
LLM_PROVIDER=openai
LLM_API_KEY=sk-...
LLM_MODEL=gpt-4

# 交易所 API（可选，用于实盘交易）
# BINANCE_API_KEY=your_key
# BINANCE_API_SECRET=your_secret
```

## 🎮 使用方法

### 启动服务

```bash
~/.cryptoclaw/start.sh
```

### 查看状态

```bash
~/.cryptoclaw/status.sh
```

### 停止服务

```bash
~/.cryptoclaw/stop.sh
```

### 更新版本

```bash
~/.cryptoclaw/update.sh
```

### Telegram 命令

| 命令 | 描述 |
|------|------|
| `/start` | 初始化 Bot |
| `/help` | 显示帮助 |
| `/backtest <策略>` | 运行回测 |
| `/trade <交易对>` | 开始模拟交易 |
| `/status` | 显示投资组合 |

## 🔧 高级配置

### 多架构构建

开发者构建自定义镜像：

```bash
# 构建当前平台
./scripts/build-docker.sh --local

# 多架构构建（需要 Docker Buildx）
./scripts/build-docker.sh --multi

# 构建并推送到仓库
./scripts/build-docker.sh --multi --push

# 仅构建 ARM64
./scripts/build-docker.sh --arm64 --local
```

### Docker 命令

```bash
# 拉取特定架构镜像
docker pull --platform linux/amd64 cryptoclaw/cryptoclaw:latest
docker pull --platform linux/arm64 cryptoclaw/cryptoclaw:latest

# 运行容器
docker run -d \
  --name cryptoclaw \
  -p 8080:8080 \
  -v ~/.cryptoclaw/config:/app/config \
  -v ~/.cryptoclaw/user_data:/app/user_data \
  cryptoclaw/cryptoclaw:latest
```

## 🐛 故障排除

### 架构不匹配

```bash
# 检查系统架构
uname -m
# x86_64 = AMD64
# aarch64 = ARM64

# 验证镜像架构
docker inspect --format='{{.Architecture}}' cryptoclaw/cryptoclaw:latest
```

### Docker 未运行

```bash
# macOS: 打开 Docker Desktop
open -a Docker

# Linux: 启动服务
sudo systemctl start docker
```

### 网络问题

```bash
# 测试连接
curl -s https://api.github.com | head -5

# 检查 Docker 网络
docker network ls
```

## 🏗️ 架构

```
┌─────────────────┐     ┌─────────────────┐
│  Telegram/      │     │  桌面客户端     │
│  WhatsApp 机器人│     │  (Electron)     │
│  (对话界面)     │     │  (API Keys)     │
└────────┬────────┘     └────────┬────────┘
         │                       │
         └───────────┬───────────┘
                     │
         ┌───────────┴───────────┐
         │      OpenClaw         │
         │   (AI 代理)           │
         └───────────┬───────────┘
                     │
         ┌───────────┴───────────┐
         │     Freqtrade         │
         │   (量化引擎)          │
         └───────────────────────┘
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

## 📋 路线图

- [x] 需求文档与架构设计
- [ ] MVP：回测 + 模拟交易
- [ ] 实盘交易集成
- [ ] 支付系统
- [ ] 更多策略

## ⚠️ 免责声明

这是工具，不是投资建议。加密货币交易风险巨大。历史收益不代表未来表现。请自行研究。

## 📄 许可证

MIT License

## 🤝 贡献

欢迎贡献代码！请随时提交 Pull Request。

## 📞 联系方式

- X (Twitter): [@cryptoclawai](https://x.com/cryptoclawai)
- GitHub: [franklili3/CryptoClaw](https://github.com/franklili3/CryptoClaw)

---

## 公开构建 🚀

在 X 上关注开发历程
