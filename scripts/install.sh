#!/bin/bash
# CryptoClaw 一键安装脚本 (macOS/Linux)
# 版本: v1.0.0
# 用法: curl -fsSL cryptoclaw.pro/install.sh | bash
#
# 支持架构:
#   - x86_64 (AMD64)
#   - aarch64 / arm64 (ARM64, Apple Silicon, Raspberry Pi 4+)

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 版本信息
VERSION="1.0.0"
DOCKER_IMAGE="cryptoclaw/cryptoclaw"
CONFIG_DIR="$HOME/.cryptoclaw"

# 架构和平台信息 (将在 detect_platform 中设置)
ARCH=""
PLATFORM=""
DOCKER_PLATFORM=""

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${CYAN}[STEP]${NC} $1"; }

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

# ============================================
# 平台检测 (多架构支持)
# ============================================
detect_platform() {
    log_step "检测系统平台和架构..."
    
    # 检测操作系统
    case "$OSTYPE" in
        darwin*)
            OS="macos"
            ;;
        linux*)
            OS="linux"
            ;;
        *)
            log_error "不支持的操作系统: $OSTYPE"
            log_error "CryptoClaw 仅支持 macOS 和 Linux"
            exit 1
            ;;
    esac
    
    # 检测 CPU 架构
    ARCH=$(uname -m)
    
    # 标准化架构名称
    case "$ARCH" in
        x86_64|amd64)
            ARCH="x86_64"
            PLATFORM="amd64"
            DOCKER_PLATFORM="linux/amd64"
            ;;
        aarch64|arm64)
            ARCH="aarch64"
            PLATFORM="arm64"
            DOCKER_PLATFORM="linux/arm64"
            ;;
        armv7l|armhf)
            log_error "ARM 32位架构暂不支持"
            log_error "请使用 x86_64 或 aarch64 (ARM64) 系统"
            exit 1
            ;;
        *)
            log_error "未知的 CPU 架构: $ARCH"
            log_error "支持的架构: x86_64 (AMD64), aarch64 (ARM64)"
            exit 1
            ;;
    esac
    
    log_success "系统: ${OS}"
    log_success "架构: ${ARCH} (${PLATFORM})"
    log_success "Docker 平台: ${DOCKER_PLATFORM}"
    
    # 显示系统信息
    if [[ "$OS" == "macos" ]]; then
        log_info "检测到 macOS $(sw_vers -productVersion 2>/dev/null || echo 'unknown')"
        if [[ "$ARCH" == "aarch64" ]]; then
            log_info "Apple Silicon (M1/M2/M3) 芯片检测到 ✓"
        fi
    elif [[ "$OS" == "linux" ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            log_info "检测到 ${PRETTY_NAME:-$ID}"
        fi
    fi
}

# ============================================
# 检查 Docker
# ============================================
check_docker() {
    log_step "检查 Docker..."
    
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        log_success "Docker 版本: $DOCKER_VERSION"
        
        # 检查 Docker 是否运行
        if docker info &> /dev/null; then
            log_success "Docker 服务运行中"
            
            # 检查 buildx 支持 (多架构构建)
            if docker buildx version &> /dev/null; then
                log_success "Docker Buildx 可用 (多架构支持)"
            else
                log_warning "Docker Buildx 不可用，多架构构建可能受限"
            fi
        else
            log_error "Docker 服务未运行"
            log_info "请启动 Docker Desktop 或 Docker daemon"
            exit 1
        fi
    else
        log_warning "Docker 未安装"
        install_docker
    fi
}

# 安装 Docker
install_docker() {
    log_step "安装 Docker..."
    
    if [[ "$OS" == "macos" ]]; then
        if command -v brew &> /dev/null; then
            log_info "正在通过 Homebrew 安装 Docker Desktop..."
            brew install --cask docker
            
            log_warning "Docker Desktop 已安装，请启动应用后重新运行此脚本"
            open -a Docker 2>/dev/null || true
            exit 0
        else
            log_error "未找到 Homebrew"
            log_error "请手动安装 Docker Desktop:"
            log_error "https://docs.docker.com/desktop/install/mac-install/"
            exit 1
        fi
    elif [[ "$OS" == "linux" ]]; then
        log_info "正在通过官方脚本安装 Docker..."
        curl -fsSL https://get.docker.com | sh
        
        # 添加用户到 docker 组
        if ! groups | grep -q docker; then
            sudo usermod -aG docker $USER
            log_warning "已将用户添加到 docker 组"
            log_warning "请注销并重新登录以生效，或运行: newgrp docker"
        fi
        
        # 启动 Docker 服务
        sudo systemctl enable docker
        sudo systemctl start docker
        
        log_success "Docker 安装完成"
    fi
}

# ============================================
# 检查 SQLite
# ============================================
check_sqlite() {
    log_step "检查 SQLite..."
    
    # 检查 Python3
    if ! command -v python3 &> /dev/null; then
        log_error "Python3 未安装"
        log_error "请安装 Python 3.8 或更高版本"
        exit 1
    fi
    
    # 获取 SQLite 版本
    SQLITE_VERSION=$(python3 -c "import sqlite3; print(sqlite3.sqlite_version)" 2>/dev/null)
    
    if [[ -z "$SQLITE_VERSION" ]]; then
        log_error "无法检测 SQLite 版本"
        exit 1
    fi
    
    log_success "SQLite 版本: $SQLITE_VERSION (via Python3)"
    
    # 检查最低版本要求 (3.35.0+)
    MIN_VERSION="3.35.0"
    if python3 -c "import sqlite3; exit(0 if tuple(map(int, sqlite3.sqlite_version.split('.'))) >= tuple(map(int, '$MIN_VERSION'.split('.'))) else 1)" 2>/dev/null; then
        log_success "SQLite 版本符合要求 (>= $MIN_VERSION)"
    else
        log_warning "SQLite 版本较低，部分功能可能受限"
        log_warning "建议升级到 SQLite >= $MIN_VERSION"
    fi
}

# ============================================
# 创建目录结构
# ============================================
create_directories() {
    log_step "创建目录结构..."
    
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
    
    log_success "目录结构已创建: $CONFIG_DIR"
}

# ============================================
# 检测是否在中国大陆（选择镜像源）
# ============================================
detect_china_region() {
    log_step "检测网络区域..."
    
    # 方法1：检查时区
    if [ -f /etc/timezone ] && grep -q "Asia/Shanghai\|China\|Beijing" /etc/timezone 2>/dev/null; then
        IS_CHINA=true
        log_info "检测到中国时区"
        return
    fi
    
    # 方法2：检查语言环境
    if echo "$LANG" | grep -qi "zh_CN\|zh_CN.UTF-8" 2>/dev/null; then
        IS_CHINA=true
        log_info "检测到中文语言环境"
        return
    fi
    
    # 方法3：尝试访问 Google（不可用则认为在中国）
    if ! curl -s --max-time 3 https://www.google.com > /dev/null 2>&1; then
        IS_CHINA=true
        log_info "检测到可能在中国大陆"
        return
    fi
    
    IS_CHINA=false
    log_info "检测到海外网络环境"
}

# ============================================
# 拉取 Docker 镜像 (多架构 + 国内镜像加速)
# ============================================
pull_image() {
    log_step "准备 CryptoClaw Docker 镜像..."
    
    log_info "目标平台: ${DOCKER_PLATFORM}"
    log_info "镜像: ${DOCKER_IMAGE}:latest"
    
    # ============================================
    # 测试阶段：使用本地镜像构建
    # TODO: 发布后取消注释以下代码块
    # ============================================
    log_warning "测试阶段：使用本地构建镜像"
    
    # 检查本地是否已有镜像
    if docker image inspect "${DOCKER_IMAGE}:latest" &>/dev/null; then
        log_success "检测到本地镜像已存在"
        IMAGE_ARCH=$(docker inspect --format='{{.Architecture}}' "${DOCKER_IMAGE}:latest" 2>/dev/null || echo "unknown")
        log_info "镜像架构: ${IMAGE_ARCH}"
        return 0
    fi
    
    # 本地没有镜像，提示用户构建
    log_warning "本地未找到镜像，请先构建："
    log_info "  cd /path/to/CryptoClaw"
    log_info "  ./scripts/build-docker.sh --local"
    log_info ""
    log_info "或手动构建："
    log_info "  docker build -t cryptoclaw/cryptoclaw:latest ./gateway"
    
    # 询问是否现在构建
    read -p "是否现在构建镜像？(y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        build_local_image
    else
        log_error "请先构建镜像后再继续安装"
        exit 1
    fi
    
    return 0
    
    # ============================================
    # 以下代码在发布后启用（取消注释）
    # ============================================
    
    # # 检测是否在中国大陆
    # detect_china_region
    # 
    # # 设置镜像源
    # if [ "$IS_CHINA" = true ]; then
    #     log_info "使用国内镜像加速..."
    #     REGISTRY_MIRROR="hub.dockermirror.com"
    #     IMAGE_URL="${REGISTRY_MIRROR}/${DOCKER_IMAGE}:latest"
    #     log_info "镜像源: ${REGISTRY_MIRROR}"
    # else
    #     REGISTRY_MIRROR="docker.io"
    #     IMAGE_URL="${DOCKER_IMAGE}:latest"
    #     log_info "镜像源: Docker Hub 官方"
    # fi
    # 
    # # 尝试拉取镜像
    # local pull_success=false
    # 
    # # 首次尝试
    # if docker pull --platform "$DOCKER_PLATFORM" "$IMAGE_URL"; then
    #     pull_success=true
    #     # 如果使用镜像源，需要重新标记标签
    #     if [ "$IS_CHINA" = true ]; then
    #         docker tag "$IMAGE_URL" "${DOCKER_IMAGE}:latest"
    #         log_success "镜像已标记为: ${DOCKER_IMAGE}:latest"
    #     fi
    # fi
    # 
    # # 如果首次失败，尝试备用方案
    # if [ "$pull_success" = false ]; then
    #     log_warning "主镜像源拉取失败，尝试备用方案..."
    #     
    #     # 备用方案1：尝试 Docker Hub 官方
    #     if [ "$IS_CHINA" = true ]; then
    #         log_info "尝试 Docker Hub 官方源..."
    #         if docker pull --platform "$DOCKER_PLATFORM" "${DOCKER_IMAGE}:latest"; then
    #             pull_success=true
    #         fi
    #     fi
    #     
    #     # 备用方案2：尝试阿里云镜像（如果有配置）
    #     if [ "$pull_success" = false ] && [ -n "$ALIYUN_REGISTRY" ]; then
    #         log_info "尝试阿里云镜像..."
    #         if docker pull --platform "$DOCKER_PLATFORM" "${ALIYUN_REGISTRY}/${DOCKER_IMAGE}:latest"; then
    #             docker tag "${ALIYUN_REGISTRY}/${DOCKER_IMAGE}:latest" "${DOCKER_IMAGE}:latest"
    #             pull_success=true
    #         fi
    #     fi
    # fi
    # 
    # # 检查结果
    # if [ "$pull_success" = true ]; then
    #     log_success "Docker 镜像拉取成功"
    #     
    #     # 验证镜像架构
    #     IMAGE_ARCH=$(docker inspect --format='{{.Architecture}}' "${DOCKER_IMAGE}:latest" 2>/dev/null || echo "unknown")
    #     log_info "镜像架构: ${IMAGE_ARCH}"
    #     
    #     # 检查架构匹配
    #     if [[ "$IMAGE_ARCH" == "amd64" && "$PLATFORM" == "amd64" ]] || \
    #        [[ "$IMAGE_ARCH" == "arm64" && "$PLATFORM" == "arm64" ]] || \
    #        [[ "$IMAGE_ARCH" == "x86_64" && "$PLATFORM" == "amd64" ]]; then
    #         log_success "架构匹配验证通过"
    #     elif [[ "$IMAGE_ARCH" != "unknown" ]]; then
    #         log_warning "镜像架构 (${IMAGE_ARCH}) 与系统架构 (${PLATFORM}) 可能不匹配"
    #         log_warning "如果遇到问题，请检查镜像是否支持您的平台"
    #     fi
    # else
    #     log_error "Docker 镜像拉取失败"
    #     log_error ""
    #     log_error "请尝试以下解决方案："
    #     log_error "1. 检查网络连接"
    #     log_error "2. 配置 Docker 代理: https://docs.docker.com/config/daemon/systemd/#httphttps-proxy"
    #     log_error "3. 手动拉取: docker pull ${DOCKER_IMAGE}:latest"
    #     log_error "4. 使用镜像加速: docker pull hub.dockermirror.com/${DOCKER_IMAGE}:latest"
    #     exit 1
    # fi
}

# ============================================
# 本地构建镜像
# ============================================
build_local_image() {
    log_step "构建本地 Docker 镜像..."
    
    # 查找 CryptoClaw 源码目录
    local source_dir=""
    
    # 尝试常见路径
    for dir in \
        "$HOME/CryptoClaw" \
        "$HOME/clawd/CryptoClaw" \
        "$(dirname "$0")/.." \
        "$(pwd)" \
        "/opt/CryptoClaw"
    do
        if [ -f "$dir/gateway/Dockerfile" ] || [ -f "$dir/Dockerfile" ]; then
            source_dir="$dir"
            break
        fi
    done
    
    if [ -z "$source_dir" ]; then
        log_error "未找到 CryptoClaw 源码目录"
        log_error "请手动构建镜像："
        log_error "  cd /path/to/CryptoClaw"
        log_error "  ./scripts/build-docker.sh --local"
        exit 1
    fi
    
    log_info "找到源码目录: $source_dir"
    
    # 构建
    cd "$source_dir"
    
    if [ -f "gateway/Dockerfile" ]; then
        docker build \
            --platform "$DOCKER_PLATFORM" \
            -t "${DOCKER_IMAGE}:latest" \
            -f gateway/Dockerfile \
            ./gateway
    elif [ -f "Dockerfile" ]; then
        docker build \
            --platform "$DOCKER_PLATFORM" \
            -t "${DOCKER_IMAGE}:latest" \
            .
    else
        log_error "找不到 Dockerfile"
        exit 1
    fi
    
    log_success "本地镜像构建完成"
}
        if [[ "$IMAGE_ARCH" == "amd64" && "$PLATFORM" == "amd64" ]] || \
           [[ "$IMAGE_ARCH" == "arm64" && "$PLATFORM" == "arm64" ]] || \
           [[ "$IMAGE_ARCH" == "x86_64" && "$PLATFORM" == "amd64" ]]; then
            log_success "架构匹配验证通过"
        elif [[ "$IMAGE_ARCH" != "unknown" ]]; then
            log_warning "镜像架构 (${IMAGE_ARCH}) 与系统架构 (${PLATFORM}) 可能不匹配"
            log_warning "如果遇到问题，请检查镜像是否支持您的平台"
        fi
    else
        log_error "Docker 镜像拉取失败"
        log_error ""
        log_error "请尝试以下解决方案："
        log_error "1. 检查网络连接"
        log_error "2. 配置 Docker 代理: https://docs.docker.com/config/daemon/systemd/#httphttps-proxy"
        log_error "3. 手动拉取: docker pull ${DOCKER_IMAGE}:latest"
        log_error "4. 使用镜像加速: docker pull hub.dockermirror.com/${DOCKER_IMAGE}:latest"
        exit 1
    fi
}

# ============================================
# 创建配置文件模板
# ============================================
create_config_templates() {
    log_step "创建配置文件模板..."
    
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

    # 创建 OpenClaw 配置模板
    cat > "$CONFIG_DIR/config/openclaw.yaml.example" << 'EOF'
# OpenClaw Gateway 配置

agents:
  list:
    - id: cryptoclaw
      name: CryptoClaw
      workspace: ~/.cryptoclaw/workspace
      model: anthropic/claude-sonnet-4-5
      default: true

bindings:
  - agentId: cryptoclaw
    match:
      channel: telegram
  - agentId: cryptoclaw
    match:
      channel: whatsapp

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

llm:
  provider: ${LLM_PROVIDER}
  apiKey: ${LLM_API_KEY}
  model: ${LLM_MODEL}

freqtrade:
  configPath: ~/.cryptoclaw/user_data/config.json
  userDataDir: ~/.cryptoclaw/user_data
EOF

    # 创建 docker-compose.yml (包含架构信息)
    cat > "$CONFIG_DIR/config/docker-compose.yml" << EOF
# CryptoClaw Docker Compose 配置
# 自动检测架构: ${ARCH} (${PLATFORM})

version: '3.8'

services:
  cryptoclaw:
    image: ${DOCKER_IMAGE}:latest
    platform: ${DOCKER_PLATFORM}
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

    log_success "配置文件模板已创建"
}

# ============================================
# 创建 Freqtrade 配置模板
# ============================================
create_freqtrade_config() {
    log_step "创建 Freqtrade 配置模板..."
    
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

    log_success "Freqtrade 配置已创建"
}

# ============================================
# 创建启动/停止脚本
# ============================================
create_scripts() {
    log_step "创建管理脚本..."
    
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
    
    # 更新脚本 (多架构感知 + 国内镜像加速)
    cat > "$CONFIG_DIR/update.sh" << 'EOF'
#!/bin/bash
# CryptoClaw 更新脚本
# 自动检测架构和区域，选择最优镜像源

# 检测当前架构
ARCH=$(uname -m)
case "$ARCH" in
    x86_64|amd64)  PLATFORM="linux/amd64" ;;
    aarch64|arm64) PLATFORM="linux/arm64" ;;
    *)             echo "❌ 不支持的架构: $ARCH"; exit 1 ;;
esac

echo "🔄 检查更新..."
echo "   当前架构: ${ARCH} (${PLATFORM})"

# 获取当前版本
CURRENT=$(docker exec cryptoclaw cat /app/VERSION 2>/dev/null || echo "unknown")

# 检查最新版本
LATEST=$(curl -s --max-time 10 https://api.github.com/repos/franklili3/CryptoClaw/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/' 2>/dev/null || echo "unknown")

if [ "$CURRENT" != "$LATEST" ] && [ "$LATEST" != "unknown" ]; then
    echo "📦 发现新版本: $LATEST (当前: $CURRENT)"
    echo ""
    echo "⚠️  测试阶段：请手动更新本地镜像"
    echo ""
    echo "更新步骤："
    echo "  1. cd /path/to/CryptoClaw"
    echo "  2. git pull"
    echo "  3. ./scripts/build-docker.sh --local"
    echo "  4. cd ~/.cryptoclaw"
    echo "  5. ./stop.sh && ./start.sh"
    echo ""
    
    # ============================================
    # 以下代码在发布后启用（取消注释）
    # ============================================
    # # 检测是否在中国大陆
    # IS_CHINA=false
    # if [ -f /etc/timezone ] && grep -q "Asia/Shanghai\|China\|Beijing" /etc/timezone 2>/dev/null; then
    #     IS_CHINA=true
    # elif echo "$LANG" | grep -qi "zh_CN" 2>/dev/null; then
    #     IS_CHINA=true
    # elif ! curl -s --max-time 3 https://www.google.com > /dev/null 2>&1; then
    #     IS_CHINA=true
    # fi
    # 
    # echo "   正在更新..."
    # 
    # # 选择镜像源
    # if [ "$IS_CHINA" = true ]; then
    #     echo "   使用国内镜像加速..."
    #     docker pull --platform $PLATFORM hub.dockermirror.com/cryptoclaw/cryptoclaw:latest
    #     docker tag hub.dockermirror.com/cryptoclaw/cryptoclaw:latest cryptoclaw/cryptoclaw:latest
    # else
    #     docker pull --platform $PLATFORM cryptoclaw/cryptoclaw:latest
    # fi
    # 
    # # 重启容器
    # cd ~/.cryptoclaw
    # docker-compose -f config/docker-compose.yml down
    # docker-compose -f config/docker-compose.yml up -d
    # 
    # echo "✅ 更新完成！"
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

# 显示架构信息
ARCH=$(uname -m)
echo "系统架构: ${ARCH}"

if docker ps | grep -q cryptoclaw; then
    echo "✅ 服务运行中"
    docker exec cryptoclaw cat /app/VERSION 2>/dev/null && echo ""
    echo "容器信息:"
    docker ps --format "  镜像: {{.Image}}\n  状态: {{.Status}}" -f name=cryptoclaw
    echo ""
    echo "镜像架构:"
    docker inspect --format='  {{.Architecture}}' cryptoclaw/cryptoclaw:latest 2>/dev/null || echo "  未知"
else
    echo "❌ 服务未运行"
    echo "运行 ~/.cryptoclaw/start.sh 启动服务"
fi
EOF
    chmod +x "$CONFIG_DIR/status.sh"
    
    log_success "管理脚本已创建"
}

# ============================================
# 运行配置向导
# ============================================
run_config_wizard() {
    log_step "启动配置向导..."
    
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
    
    # 清理备份文件
    rm -f "$CONFIG_DIR/config/.env.bak"
    
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

# ============================================
# 显示完成信息
# ============================================
show_completion() {
    echo ""
    echo -e "${GREEN}✅ CryptoClaw 安装完成！${NC}"
    echo ""
    echo -e "${CYAN}系统信息:${NC}"
    echo "  操作系统: ${OS}"
    echo "  CPU 架构: ${ARCH} (${PLATFORM})"
    echo "  Docker 平台: ${DOCKER_PLATFORM}"
    echo ""
    echo -e "${CYAN}安装位置:${NC} $CONFIG_DIR"
    echo ""
    echo -e "${CYAN}快速开始:${NC}"
    echo "   1. 启动服务:    ~/.cryptoclaw/start.sh"
    echo "   2. 检查状态:    ~/.cryptoclaw/status.sh"
    echo "   3. 停止服务:    ~/.cryptoclaw/stop.sh"
    echo "   4. 更新版本:    ~/.cryptoclaw/update.sh"
    echo ""
    echo -e "${CYAN}Telegram 使用:${NC}"
    echo "   - 搜索您创建的 Bot"
    echo "   - 发送 /start 开始使用"
    echo ""
    echo -e "${CYAN}支持的架构:${NC}"
    echo "   ✓ x86_64 (AMD64) - Intel/AMD 处理器"
    echo "   ✓ aarch64 (ARM64) - Apple Silicon, Raspberry Pi 4+"
    echo ""
    echo "📚 文档: https://cryptoclaw.pro/docs"
    echo "💬 支持: @CryptoClawBot"
    echo ""
}

# ============================================
# 主函数
# ============================================
main() {
    show_banner
    
    # 1. 检测平台和架构
    detect_platform
    
    # 2. 检查 Docker
    check_docker
    
    # 3. 检查 SQLite
    check_sqlite
    
    # 4. 创建目录
    create_directories
    
    # 5. 拉取镜像 (多架构感知)
    pull_image
    
    # 6. 创建配置
    create_config_templates
    create_freqtrade_config
    create_scripts
    
    # 7. 配置向导
    run_config_wizard
    
    # 8. 完成
    show_completion
}

# 运行安装
main "$@"
