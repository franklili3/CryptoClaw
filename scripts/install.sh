#!/bin/bash
# CryptoClaw 一键安装脚本 (macOS/Linux)
# 版本: v1.0.0
# 用法: curl -fsSL cryptoclaw.pro/install.sh | bash

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 版本信息
VERSION="1.0.0"
DOCKER_IMAGE="cryptoclaw/cryptoclaw:latest"
CONFIG_DIR="$HOME/.cryptoclaw"

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 显示横幅
show_banner() {
    echo -e "${BLUE}"
    cat << 'EOF'
   _____                _ _          _____      _            
  / ____|              | | |        / ____|    | |           
 | |     ___  _ __  ___| | | ___   | |     __ _| | _____ _ __ 
 | |    / _ \| '_ \/ __| | |/ _ \  | |    / _` | |/ / _ \ '__|
 | |___| (_) | | | \__ \ | |  __/  | |___| (_| |   <  __/ |   
  \_____\___/|_| |_|___/_|_|\___|   \_____\__,_|_|\_\___|_|   
                                                              
  AI-Powered Crypto Trading Assistant
EOF
    echo -e "${NC}"
    echo -e "  Version: ${VERSION}"
    echo -e "  Docker Image: ${DOCKER_IMAGE}"
    echo ""
}

# 检测操作系统
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "linux"* ]]; then
        OS="linux"
    else
        log_error "Unsupported OS: $OSTYPE"
        exit 1
    fi
    log_info "Detected OS: $OS"
}

# 检查 Docker 是否安装
check_docker() {
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version)
        log_success "Docker installed: $DOCKER_VERSION"
        
        # 检查 Docker 是否运行
        if docker info &> /dev/null; then
            log_success "Docker is running"
        else
            log_error "Docker is not running. Please start Docker Desktop."
            exit 1
        fi
    else
        log_warning "Docker not found. Installing Docker..."
        install_docker
    fi
}

# 安装 Docker
install_docker() {
    if [[ "$OS" == "macos" ]]; then
        if command -v brew &> /dev/null; then
            log_info "Installing Docker via Homebrew..."
            brew install --cask docker
        else
            log_error "Homebrew not found. Please install Docker Desktop manually:"
            log_error "https://docs.docker.com/desktop/install/mac-install/"
            exit 1
        fi
    elif [[ "$OS" == "linux" ]]; then
        log_info "Installing Docker via official script..."
        curl -fsSL https://get.docker.com | sh
        sudo usermod -aG docker $USER
        log_warning "Docker installed. You may need to log out and back in for group changes to take effect."
    fi
}

# 创建目录结构
create_directories() {
    log_info "Creating directory structure..."
    
    # 按照设计文档规范创建目录结构
    # 参考: design.md - 2.2 Agent Workspace
    
    # Freqtrade 标准 user_data 目录
    mkdir -p "$CONFIG_DIR"/user_data/strategies/user_strategies
    mkdir -p "$CONFIG_DIR"/user_data/data/{binance,okx}
    mkdir -p "$CONFIG_DIR"/user_data/notebooks
    mkdir -p "$CONFIG_DIR"/user_data/plot
    mkdir -p "$CONFIG_DIR"/user_data/hyperopts
    mkdir -p "$CONFIG_DIR"/user_data/freqaimodels
    
    # OpenClaw Agent 工作区
    mkdir -p "$CONFIG_DIR"/workspace/skills/{freqtrade,billing,trading-signals}
    mkdir -p "$CONFIG_DIR"/workspace/memory
    
    # 配置和日志目录
    mkdir -p "$CONFIG_DIR"/config
    mkdir -p "$CONFIG_DIR"/logs
    
    # 创建策略目录 __init__.py
    touch "$CONFIG_DIR"/user_data/strategies/__init__.py
    
    log_success "Directory structure created at $CONFIG_DIR"
}

# 拉取 Docker 镜像
pull_image() {
    log_info "Pulling CryptoClaw Docker image..."
    docker pull $DOCKER_IMAGE
    log_success "Docker image pulled successfully"
}

# 创建配置文件模板
create_config_templates() {
    log_info "Creating configuration templates..."
    
    # 创建 .env 模板
    cat > "$CONFIG_DIR/config/.env.example" << 'EOF'
# CryptoClaw 环境变量配置
# 复制此文件为 .env 并填写实际值

# Telegram Bot Token (从 @BotFather 获取)
TELEGRAM_BOT_TOKEN=your_bot_token_here

# LLM API 配置
LLM_PROVIDER=openai
LLM_API_KEY=your_api_key_here
LLM_MODEL=gpt-4

# 交易所 API (可选，用于实盘交易)
# BINANCE_API_KEY=your_binance_api_key
# BINANCE_API_SECRET=your_binance_api_secret
EOF

    # 创建 OpenClaw 配置模板（参考 design.md 2.1）
    cat > "$CONFIG_DIR/config/openclaw.yaml.example" << 'EOF'
# OpenClaw Gateway 配置
# 参考: CryptoClaw 设计文档 2.1

# Agent 定义
agents:
  list:
    - id: cryptoclaw
      name: CryptoClaw
      workspace: ~/.cryptoclaw/workspace
      model: anthropic/claude-sonnet-4-5
      default: true

# 消息渠道绑定
bindings:
  - agentId: cryptoclaw
    match:
      channel: telegram
  - agentId: cryptoclaw
    match:
      channel: whatsapp

# 渠道配置
channels:
  telegram:
    accounts:
      default:
        botToken: ${TELEGRAM_BOT_TOKEN}
        dmPolicy: pairing
  whatsapp:
    enabled: false
    accounts:
      default:
        dmPolicy: allowlist
        allowFrom: []

# LLM 配置
llm:
  provider: ${LLM_PROVIDER}
  apiKey: ${LLM_API_KEY}
  model: ${LLM_MODEL}

# Freqtrade 配置
freqtrade:
  configPath: ~/.cryptoclaw/user_data/config.json
  userDataDir: ~/.cryptoclaw/user_data
EOF

    # 创建 docker-compose.yml
    cat > "$CONFIG_DIR/config/docker-compose.yml" << 'EOF'
version: '3.8'

services:
  cryptoclaw:
    image: cryptoclaw/cryptoclaw:latest
    container_name: cryptoclaw
    restart: unless-stopped
    
    volumes:
      - ~/.cryptoclaw/config/openclaw.yaml:/app/config/openclaw.yaml:ro
      - ~/.cryptoclaw/user_data:/app/user_data
      - ~/.cryptoclaw/workspace:/app/workspace
      - ~/.cryptoclaw/logs:/app/logs
    
    ports:
      - "8080:8080"
    
    env_file:
      - ~/.cryptoclaw/config/.env
    
    environment:
      - TZ=Asia/Shanghai
      - LOG_LEVEL=info
      - OPENCLAW_CONFIG=/app/config/openclaw.yaml
EOF

    log_success "Configuration templates created"
}

# 创建 Freqtrade 配置模板
create_freqtrade_config() {
    log_info "Creating Freqtrade configuration template..."
    
    # 创建 Freqtrade 配置模板（参考 technical-spec.md）
    cat > "$CONFIG_DIR/user_data/config.json.example" << 'EOF'
{
    "max_open_trades": 3,
    "stake_currency": "USDT",
    "stake_amount": "unlimited",
    "tradable_balance_ratio": 0.99,
    "fiat_display_currency": "USD",
    "dry_run": true,
    "dry_run_wallet": 1000,
    "cancel_open_orders_on_exit": false,
    "trading_mode": "spot",
    "margin_mode": "",
    "unfilledtimeout": {
        "entry": 10,
        "exit": 10,
        "exit_timeout_count": 0,
        "unit": "minutes"
    },
    "entry_pricing": {
        "price_side": "same",
        "use_order_book": true,
        "order_book_top": 1,
        "price_last_balance": 0.0,
        "check_depth_of_market": {
            "enabled": false,
            "bids_to_ask_delta": 1
        }
    },
    "exit_pricing":{
        "price_side": "same",
        "use_order_book": true,
        "order_book_top": 1
    },
    "exchange": {
        "name": "binance",
        "key": "${BINANCE_API_KEY}",
        "secret": "${BINANCE_API_SECRET}",
        "ccxt_sync_config": {},
        "ccxt_async_config": {},
        "pair_whitelist": [
            "BTC/USDT",
            "ETH/USDT"
        ],
        "pair_blacklist": [
            "BNB/.*"
        ]
    },
    "pairlists": [
        {
            "method": "StaticPairList"
        }
    ],
    "telegram": {
        "enabled": false,
        "token": "${TELEGRAM_BOT_TOKEN}",
        "chat_id": "${TELEGRAM_CHAT_ID}"
    },
    "api_server": {
        "enabled": true,
        "listen_ip_address": "0.0.0.0",
        "listen_port": 8081,
        "verbosity": "error"
    },
    "bot_name": "CryptoClaw",
    "initial_state": "running",
    "force_entry_enable": false,
    "internals": {
        "process_throttle_secs": 5
    }
}
EOF

    # 更新 docker-compose.yml 添加 Freqtrade API 端口
    cat > "$CONFIG_DIR/config/docker-compose.yml" << 'EOF'
version: '3.8'

services:
  cryptoclaw:
    image: cryptoclaw/cryptoclaw:latest
    container_name: cryptoclaw
    restart: unless-stopped
    
    volumes:
      - ~/.cryptoclaw/config/openclaw.yaml:/app/config/openclaw.yaml:ro
      - ~/.cryptoclaw/user_data:/app/user_data
      - ~/.cryptoclaw/workspace:/app/workspace
      - ~/.cryptoclaw/logs:/app/logs
      - ~/.cryptoclaw/cryptoclaw.db:/app/cryptoclaw.db
    
    ports:
      - "8080:8080"
      - "8081:8081"
    
    env_file:
      - ~/.cryptoclaw/config/.env
    
    environment:
      - TZ=Asia/Shanghai
      - LOG_LEVEL=info
      - OPENCLAW_CONFIG=/app/config/openclaw.yaml
EOF

    log_success "Freqtrade configuration created"
}

# 创建启动/停止脚本
create_scripts() {
    log_info "Creating utility scripts..."
    
    # 启动脚本
    cat > "$CONFIG_DIR/start.sh" << 'EOF'
#!/bin/bash
cd ~/.cryptoclaw
docker-compose -f config/docker-compose.yml up -d
echo "✅ CryptoClaw 已启动"
echo "📱 在 Telegram 中搜索您的 Bot 发送 /start 开始使用"
EOF
    chmod +x "$CONFIG_DIR/start.sh"
    
    # 停止脚本
    cat > "$CONFIG_DIR/stop.sh" << 'EOF'
#!/bin/bash
cd ~/.cryptoclaw
docker-compose -f config/docker-compose.yml down
echo "✅ CryptoClaw 已停止"
EOF
    chmod +x "$CONFIG_DIR/stop.sh"
    
    # 更新脚本
    cat > "$CONFIG_DIR/update.sh" << 'EOF'
#!/bin/bash
echo "🔄 检查更新..."

CURRENT=$(docker exec cryptoclaw cat /app/VERSION 2>/dev/null || echo "unknown")
LATEST=$(curl -s https://api.cryptoclaw.pro/updates/latest | jq -r '.version')

if [ "$CURRENT" != "$LATEST" ]; then
    echo "📦 发现新版本: $LATEST (当前: $CURRENT)"
    echo "正在更新..."
    
    docker pull cryptoclaw/cryptoclaw:latest
    docker-compose -f ~/.cryptoclaw/config/docker-compose.yml down
    docker-compose -f ~/.cryptoclaw/config/docker-compose.yml up -d
    
    echo "✅ 更新完成！"
else
    echo "✅ 已是最新版本: $CURRENT"
fi
EOF
    chmod +x "$CONFIG_DIR/update.sh"
    
    # 状态检查脚本
    cat > "$CONFIG_DIR/status.sh" << 'EOF'
#!/bin/bash
echo "📊 CryptoClaw 状态"
echo "=================="

if docker ps | grep -q cryptoclaw; then
    echo "✅ 服务运行中"
    docker exec cryptoclaw cat /app/VERSION 2>/dev/null && echo ""
    echo "运行时间:"
    docker ps --format "table {{.Status}}" -f name=cryptoclaw
else
    echo "❌ 服务未运行"
    echo "运行 ~/.cryptoclaw/start.sh 启动服务"
fi
EOF
    chmod +x "$CONFIG_DIR/status.sh"
    
    log_success "Utility scripts created"
}

# 运行配置向导
run_config_wizard() {
    log_info "启动配置向导..."
    
    # 检查是否已有配置
    if [ -f "$CONFIG_DIR/config/.env" ]; then
        log_warning "检测到已有配置文件"
        read -p "是否重新配置？(y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "使用现有配置"
            return 0
        fi
    fi
    
    # 复制模板
    cp "$CONFIG_DIR/config/.env.example" "$CONFIG_DIR/config/.env"
    cp "$CONFIG_DIR/config/openclaw.yaml.example" "$CONFIG_DIR/config/openclaw.yaml"
    cp "$CONFIG_DIR/user_data/config.json.example" "$CONFIG_DIR/user_data/config.json"
    
    echo ""
    echo -e "${YELLOW}🔧 CryptoClaw 配置向导${NC}"
    echo "========================"
    echo ""
    
    # 配置 Telegram Bot
    echo -e "${BLUE}📱 Telegram Bot 配置${NC}"
    echo "-------------------"
    echo "请按照以下步骤获取 Bot Token:"
    echo "1. 在 Telegram 中搜索 @BotFather"
    echo "2. 发送 /newbot 创建新 Bot"
    echo "3. 按提示设置 Bot 名称"
    echo "4. 复制获得的 Token（格式：123456789:ABCdef...）"
    echo ""
    read -p "请输入您的 Telegram Bot Token: " TELEGRAM_TOKEN
    
    # 配置 LLM
    echo ""
    echo -e "${BLUE}🤖 LLM API 配置${NC}"
    echo "--------------"
    echo "请选择 LLM 提供商:"
    echo "1) OpenAI (推荐)"
    echo "2) Anthropic Claude"
    echo "3) 本地模型（跳过）"
    read -p "请选择 (1-3): " llm_choice
    
    case $llm_choice in
        1)
            LLM_PROVIDER="openai"
            read -p "请输入 OpenAI API Key (sk-...): " LLM_KEY
            LLM_MODEL="gpt-4"
            ;;
        2)
            LLM_PROVIDER="anthropic"
            read -p "请输入 Anthropic API Key (sk-ant-...): " LLM_KEY
            LLM_MODEL="claude-3-opus-20240229"
            ;;
        3)
            LLM_PROVIDER="local"
            LLM_KEY=""
            LLM_MODEL=""
            log_warning "将使用本地模型，需要在配置文件中手动设置"
            ;;
        *)
            log_warning "无效选择，跳过 LLM 配置"
            LLM_PROVIDER=""
            LLM_KEY=""
            LLM_MODEL=""
            ;;
    esac
    
    # 更新 .env 文件
    if [ -n "$TELEGRAM_TOKEN" ]; then
        sed -i.bak "s/your_bot_token_here/$TELEGRAM_TOKEN/" "$CONFIG_DIR/config/.env"
    fi
    
    if [ -n "$LLM_KEY" ]; then
        sed -i.bak "s/your_api_key_here/$LLM_KEY/" "$CONFIG_DIR/config/.env"
        sed -i.bak "s/LLM_PROVIDER=openai/LLM_PROVIDER=$LLM_PROVIDER/" "$CONFIG_DIR/config/.env"
        if [ -n "$LLM_MODEL" ]; then
            sed -i.bak "s/LLM_MODEL=gpt-4/LLM_MODEL=$LLM_MODEL/" "$CONFIG_DIR/config/.env"
        fi
    fi
    
    # 设置文件权限
    chmod 600 "$CONFIG_DIR/config/.env"
    
    log_success "配置完成！"
    echo ""
    echo "配置文件位置:"
    echo "  - $CONFIG_DIR/config/.env (敏感信息)"
    echo "  - $CONFIG_DIR/config/openclaw.yaml (OpenClaw 配置)"
    echo "  - $CONFIG_DIR/user_data/config.json (Freqtrade 配置)"
    echo ""
}

# 显示完成信息
show_completion() {
    echo ""
    echo -e "${GREEN}✅ CryptoClaw 安装完成！${NC}"
    echo ""
    echo "📁 安装位置: $CONFIG_DIR"
    echo ""
    echo "🚀 快速开始:"
    echo "   1. 启动服务:    ~/.cryptoclaw/start.sh"
    echo "   2. 检查状态:    ~/.cryptoclaw/status.sh"
    echo "   3. 停止服务:    ~/.cryptoclaw/stop.sh"
    echo "   4. 更新版本:    ~/.cryptoclaw/update.sh"
    echo ""
    echo "📱 Telegram 使用:"
    echo "   - 搜索您创建的 Bot"
    echo "   - 发送 /start 开始使用"
    echo ""
    echo "📚 文档: https://cryptoclaw.pro/docs"
    echo "💬 支持: @CryptoClawBot"
    echo ""
}

# 主函数
main() {
    show_banner
    detect_os
    check_docker
    create_directories
    pull_image
    create_config_templates
    create_freqtrade_config
    create_scripts
    run_config_wizard
    show_completion
}

# 运行安装
main "$@"
