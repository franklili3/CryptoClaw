#!/bin/bash
# CryptoClaw OpenClaw 配置向导脚本
# 版本: v1.0.0
# 用途: 引导用户完成 OpenClaw Gateway 配置

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

CONFIG_DIR="$HOME/.cryptoclaw/config"

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }

# 显示欢迎界面
show_welcome() {
    echo -e "${CYAN}"
    cat << 'EOF'
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│     🔧 CryptoClaw 配置向导                                  │
│                                                             │
│     本向导将帮助您完成以下配置：                            │
│     • Telegram Bot 设置                                     │
│     • LLM API 配置                                          │
│     • OpenClaw Gateway 配置                                 │
│                                                             │
└─────────────────────────────────────────────────────────────┘
EOF
    echo -e "${NC}"
}

# 检查现有配置
check_existing_config() {
    if [ -f "$CONFIG_DIR/.env" ]; then
        log_warning "检测到已有配置文件"
        echo ""
        read -p "是否重新配置？(y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "使用现有配置，退出向导"
            exit 0
        fi
        # 备份现有配置
        cp "$CONFIG_DIR/.env" "$CONFIG_DIR/.env.backup.$(date +%Y%m%d%H%M%S)"
        log_info "已备份现有配置"
    fi
}

# Step 1: 检查 Docker
check_docker() {
    echo -e "${CYAN}"
    echo "┌─────────────────────────────────────────────────────────────┐"
    echo "│  Step 1: 检查 Docker                                        │"
    echo "└─────────────────────────────────────────────────────────────┘"
    echo -e "${NC}"
    
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version)
        log_success "Docker 已安装: $DOCKER_VERSION"
        
        if docker info &> /dev/null; then
            log_success "Docker 正在运行"
        else
            log_error "Docker 未运行，请先启动 Docker Desktop"
            exit 1
        fi
    else
        log_error "Docker 未安装"
        echo ""
        echo "请先安装 Docker:"
        echo "  macOS:  brew install --cask docker"
        echo "  Linux:  curl -fsSL https://get.docker.com | sh"
        echo "  Windows: https://docs.docker.com/desktop/install/windows-install/"
        exit 1
    fi
    echo ""
}

# Step 2: 配置 Telegram Bot
configure_telegram() {
    echo -e "${CYAN}"
    echo "┌─────────────────────────────────────────────────────────────┐"
    echo "│  Step 2: 配置 Telegram Bot                                  │"
    echo "└─────────────────────────────────────────────────────────────┘"
    echo -e "${NC}"
    
    echo "请按照以下步骤创建 Telegram Bot："
    echo ""
    echo "  1️⃣  在 Telegram 中搜索 @BotFather"
    echo "  2️⃣  发送 /newbot 创建新 Bot"
    echo "  3️⃣  设置 Bot 名称（如：MyCryptoClawBot）"
    echo "  4️⃣  设置 Bot 用户名（必须以 bot 结尾）"
    echo "  5️⃣  复制获得的 Token（格式：123456789:ABCdef...）"
    echo ""
    
    # 验证 Token 格式
    while true; do
        read -p "请输入 Telegram Bot Token: " TELEGRAM_TOKEN
        
        if [[ $TELEGRAM_TOKEN =~ ^[0-9]+:[A-Za-z0-9_-]+$ ]]; then
            log_success "Token 格式正确"
            
            # 验证 Token 有效性
            log_info "验证 Token 有效性..."
            if curl -s "https://api.telegram.org/bot${TELEGRAM_TOKEN}/getMe" | grep -q '"ok":true'; then
                log_success "Token 验证成功"
                break
            else
                log_error "Token 无效，请检查后重试"
            fi
        else
            log_error "Token 格式不正确，应为：数字:字母数字组合"
        fi
    done
    echo ""
}

# Step 3: 配置 LLM
configure_llm() {
    echo -e "${CYAN}"
    echo "┌─────────────────────────────────────────────────────────────┐"
    echo "│  Step 3: 配置 LLM API                                       │"
    echo "└─────────────────────────────────────────────────────────────┘"
    echo -e "${NC}"
    
    echo "请选择 LLM 提供商："
    echo ""
    echo "  1) OpenAI (推荐) - GPT-4"
    echo "  2) Anthropic - Claude 3"
    echo "  3) DeepSeek"
    echo "  4) 本地模型（跳过配置）"
    echo ""
    
    while true; do
        read -p "请选择 (1-4): " llm_choice
        
        case $llm_choice in
            1)
                LLM_PROVIDER="openai"
                LLM_MODEL="gpt-4"
                echo ""
                read -p "请输入 OpenAI API Key (sk-...): " LLM_KEY
                if [[ $LLM_KEY =~ ^sk- ]]; then
                    log_success "API Key 格式正确"
                else
                    log_warning "API Key 格式可能不正确"
                fi
                break
                ;;
            2)
                LLM_PROVIDER="anthropic"
                LLM_MODEL="claude-3-opus-20240229"
                echo ""
                read -p "请输入 Anthropic API Key (sk-ant-...): " LLM_KEY
                if [[ $LLM_KEY =~ ^sk-ant- ]]; then
                    log_success "API Key 格式正确"
                else
                    log_warning "API Key 格式可能不正确"
                fi
                break
                ;;
            3)
                LLM_PROVIDER="deepseek"
                LLM_MODEL="deepseek-chat"
                echo ""
                read -p "请输入 DeepSeek API Key: " LLM_KEY
                break
                ;;
            4)
                LLM_PROVIDER="local"
                LLM_KEY=""
                LLM_MODEL=""
                log_warning "将使用本地模型，需要手动编辑配置文件"
                break
                ;;
            *)
                log_error "无效选择，请输入 1-4"
                ;;
        esac
    done
    echo ""
}

# Step 4: 配置 OpenClaw
configure_openclaw() {
    echo -e "${CYAN}"
    echo "┌─────────────────────────────────────────────────────────────┐"
    echo "│  Step 4: 配置 OpenClaw Gateway                              │"
    echo "└─────────────────────────────────────────────────────────────┘"
    echo -e "${NC}"
    
    echo "OpenClaw Gateway 配置选项："
    echo ""
    echo "  端口: 8080 (默认)"
    echo "  时区: Asia/Shanghai (默认)"
    echo ""
    read -p "使用默认配置？(y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        read -p "请输入端口号: " GATEWAY_PORT
        read -p "请输入时区 (如 Asia/Shanghai): " TIMEZONE
    else
        GATEWAY_PORT=8080
        TIMEZONE="Asia/Shanghai"
    fi
    
    log_success "OpenClaw 配置完成"
    echo ""
}

# Step 5: 写入配置文件
write_config() {
    echo -e "${CYAN}"
    echo "┌─────────────────────────────────────────────────────────────┐"
    echo "│  Step 5: 保存配置                                           │"
    echo "└─────────────────────────────────────────────────────────────┘"
    echo -e "${NC}"
    
    # 创建配置目录
    mkdir -p "$CONFIG_DIR"
    
    # 写入 .env 文件
    cat > "$CONFIG_DIR/.env" << EOF
# CryptoClaw 环境变量配置
# 生成时间: $(date)

# Telegram Bot Token
TELEGRAM_BOT_TOKEN=$TELEGRAM_TOKEN

# LLM 配置
LLM_PROVIDER=$LLM_PROVIDER
LLM_API_KEY=$LLM_KEY
LLM_MODEL=$LLM_MODEL
EOF
    
    # 写入 openclaw.yaml 文件
    cat > "$CONFIG_DIR/openclaw.yaml" << EOF
# OpenClaw Gateway 配置
# 生成时间: $(date)

gateway:
  name: cryptoclaw
  port: $GATEWAY_PORT

channels:
  telegram:
    enabled: true
    token: \${TELEGRAM_BOT_TOKEN}
  whatsapp:
    enabled: false
  feishu:
    enabled: false

llm:
  provider: \${LLM_PROVIDER}
  apiKey: \${LLM_API_KEY}
  model: \${LLM_MODEL}

freqtrade:
  configPath: /app/user_data/config.json
  userDataDir: /app/user_data
EOF
    
    # 设置文件权限
    chmod 600 "$CONFIG_DIR/.env"
    
    log_success "配置文件已保存"
    echo ""
    echo "配置文件位置:"
    echo "  📄 $CONFIG_DIR/.env"
    echo "  📄 $CONFIG_DIR/openclaw.yaml"
    echo ""
}

# Step 6: 完成并提示
show_completion() {
    echo -e "${GREEN}"
    echo "┌─────────────────────────────────────────────────────────────┐"
    echo "│                                                             │"
    echo "│     ✅ 配置完成！                                           │"
    echo "│                                                             │"
    echo "└─────────────────────────────────────────────────────────────┘"
    echo -e "${NC}"
    echo ""
    echo "🚀 下一步操作："
    echo ""
    echo "  1. 启动服务:"
    echo "     ~/.cryptoclaw/start.sh"
    echo ""
    echo "  2. 在 Telegram 中搜索您的 Bot，发送 /start"
    echo ""
    echo "  3. 查看日志:"
    echo "     docker logs cryptoclaw --tail 100"
    echo ""
    echo "📚 文档: https://cryptoclaw.pro/docs"
    echo "💬 支持: @CryptoClawBot"
    echo ""
}

# 主函数
main() {
    show_welcome
    check_existing_config
    check_docker
    configure_telegram
    configure_llm
    configure_openclaw
    write_config
    show_completion
}

# 运行
main "$@"
