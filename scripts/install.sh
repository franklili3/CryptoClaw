#!/bin/bash
# install.sh - CryptoClaw 一键安装脚本
# 支持 macOS 和 Linux

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 版本
VERSION="${VERSION:-latest}"
CLIENT_VERSION="${CLIENT_VERSION:-1.0.0}"

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║               🦀 CryptoClaw 安装程序                       ║"
echo "║                                                            ║"
echo "║         AI 驱动的加密货币量化交易助手                       ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# 检测操作系统
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux"* ]]; then
        if command -v lsb_release &> /dev/null; then
            DISTRO=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
        elif [ -f /etc/os-release ]; then
            DISTRO=$(grep -oP '(?<=^ID=).*' /etc/os-release | tr -d '"')
        else
            DISTRO="linux"
        fi
        echo "$DISTRO"
    else
        echo "unknown"
    fi
}

OS=$(detect_os)
echo -e "${BLUE}[信息]${NC} 检测到操作系统: $OS"

# 检查并安装 Docker
check_docker() {
    echo -e "\n${BLUE}[步骤 1/5]${NC} 检查 Docker..."
    
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version)
        echo -e "${GREEN}[✓]${NC} Docker 已安装: $DOCKER_VERSION"
        
        # 检查 Docker 是否运行
        if docker info &> /dev/null; then
            echo -e "${GREEN}[✓]${NC} Docker 正在运行"
            return 0
        else
            echo -e "${YELLOW}[!]${NC} Docker 未运行，正在启动..."
            if [[ "$OS" == "macos" ]]; then
                open -a Docker
            else
                sudo systemctl start docker
            fi
            sleep 10
            if docker info &> /dev/null; then
                echo -e "${GREEN}[✓]${NC} Docker 启动成功"
                return 0
            fi
        fi
    fi
    
    echo -e "${YELLOW}[!]${NC} 未检测到 Docker"
    
    # 询问是否安装
    read -p "是否自动安装 Docker? [Y/n] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        install_docker
        return $?
    else
        echo -e "${RED}[✗]${NC} Docker 是必需的，安装已取消"
        echo "请手动安装 Docker: https://docs.docker.com/get-docker/"
        exit 1
    fi
}

# 安装 Docker
install_docker() {
    echo -e "${BLUE}[信息]${NC} 正在安装 Docker..."
    
    if [[ "$OS" == "macos" ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install --cask docker
            echo -e "${GREEN}[✓]${NC} Docker Desktop 已安装"
            echo -e "${YELLOW}[!]${NC} 请启动 Docker Desktop 后重新运行此脚本"
            open -a Docker
            exit 0
        else
            echo -e "${RED}[✗]${NC} 请先安装 Homebrew: https://brew.sh"
            echo "或直接下载 Docker Desktop: https://www.docker.com/products/docker-desktop"
            exit 1
        fi
    elif [[ "$OS" == "linux" ]]; then
        # Linux - 使用官方脚本
        curl -fsSL https://get.docker.com | sh
        sudo usermod -aG docker $USER
        echo -e "${GREEN}[✓]${NC} Docker 已安装"
        echo -e "${YELLOW}[!]${NC} 请运行 'newgrp docker' 或重新登录以生效"
        
        # 启动 Docker
        sudo systemctl enable docker
        sudo systemctl start docker
    else
        echo -e "${RED}[✗]${NC} 不支持的操作系统"
        exit 1
    fi
}

# 拉取 Docker 镜像
pull_image() {
    echo -e "\n${BLUE}[步骤 2/5]${NC} 检查 CryptoClaw 镜像..."
    
    IMAGE="cryptoclaw/cryptoclaw:${VERSION}"
    
    # 先检查本地镜像是否存在
    if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${IMAGE}$"; then
        echo -e "${GREEN}[✓]${NC} 本地镜像已存在: $IMAGE"
        return 0
    fi
    
    echo -e "${BLUE}[信息]${NC} 正在拉取镜像: $IMAGE"
    echo -e "${YELLOW}[!]${NC} 镜像约 1GB，可能需要几分钟..."
    
    if docker pull $IMAGE; then
        echo -e "${GREEN}[✓]${NC} 镜像拉取成功"
    else
        echo -e "${RED}[✗]${NC} 镜像拉取失败"
        echo "请检查网络连接或手动运行: docker pull $IMAGE"
        exit 1
    fi
}

# 创建目录结构
create_directories() {
    echo -e "\n${BLUE}[步骤 3/5]${NC} 创建工作目录..."
    
    CRYPTCLAW_DIR="$HOME/.cryptoclaw"
    
    mkdir -p "$CRYPTCLAW_DIR"/{config,user_data,workspace,logs}
    
    # 创建默认配置
    if [ ! -f "$CRYPTCLAW_DIR/config/openclaw.yaml" ]; then
        cat > "$CRYPTCLAW_DIR/config/openclaw.yaml" << 'EOF'
gateway:
  auth:
    mode: token
    token: "cryptoclaw-default-token"
  bind:
    host: 0.0.0.0
    port: 19001
EOF
        echo -e "${GREEN}[✓]${NC} 创建默认配置文件"
    fi
    
    echo -e "${GREEN}[✓]${NC} 工作目录创建完成: $CRYPTCLAW_DIR"
}

# 下载桌面客户端
download_client() {
    echo -e "\n${BLUE}[步骤 4/5]${NC} 安装桌面客户端..."
    
    CLIENT_DIR="$HOME/.cryptoclaw/client"
    mkdir -p "$CLIENT_DIR"
    
    # 检查本地构建的客户端
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
    
    if [[ "$OS" == "macos" ]]; then
        LOCAL_CLIENT="$PROJECT_DIR/client/dist/CryptoClaw-1.0.0-arm64.dmg"
        CLIENT_FILE="$CLIENT_DIR/CryptoClaw.dmg"
    elif [[ "$OS" == "linux" ]]; then
        LOCAL_CLIENT="$PROJECT_DIR/client/dist/CryptoClaw-1.0.0.AppImage"
        CLIENT_FILE="$CLIENT_DIR/CryptoClaw.AppImage"
    fi
    
    # 优先使用本地构建的客户端
    if [ -f "$LOCAL_CLIENT" ]; then
        echo -e "${GREEN}[✓]${NC} 发现本地构建的客户端"
        cp "$LOCAL_CLIENT" "$CLIENT_FILE"
        echo -e "${GREEN}[✓]${NC} 客户端已复制到: $CLIENT_FILE"
        return 0
    fi
    
    # 本地没有则从 GitHub 下载
    if [[ "$OS" == "macos" ]]; then
        CLIENT_URL="https://github.com/franklili3/CryptoClaw/releases/download/v${CLIENT_VERSION}/CryptoClaw-${CLIENT_VERSION}.dmg"
    elif [[ "$OS" == "linux" ]]; then
        CLIENT_URL="https://github.com/franklili3/CryptoClaw/releases/download/v${CLIENT_VERSION}/CryptoClaw-${CLIENT_VERSION}.AppImage"
    fi
    
    echo -e "${BLUE}[信息]${NC} 下载地址: $CLIENT_URL"
    
    if command -v curl &> /dev/null; then
        curl -L -o "$CLIENT_FILE" "$CLIENT_URL"
    elif command -v wget &> /dev/null; then
        wget -O "$CLIENT_FILE" "$CLIENT_URL"
    else
        echo -e "${RED}[✗]${NC} 需要 curl 或 wget"
        exit 1
    fi
    
    # Linux 需要添加执行权限
    if [[ "$OS" == "linux" ]]; then
        chmod +x "$CLIENT_FILE"
    fi
    
    echo -e "${GREEN}[✓]${NC} 客户端下载完成: $CLIENT_FILE"
}

# 创建启动脚本
create_launcher() {
    echo -e "\n${BLUE}[步骤 5/5]${NC} 创建启动脚本..."
    
    LAUNCHER="$HOME/.cryptoclaw/cryptoclaw.sh"
    
    cat > "$LAUNCHER" << 'EOF'
#!/bin/bash
# CryptoClaw 启动脚本

# 启动 Docker 容器（如果未运行）
if ! docker ps | grep -q cryptoclaw-gateway; then
    docker run -d \
        --name cryptoclaw-gateway \
        -p 19001:19001 \
        -v ~/.cryptoclaw:/app/.openclaw \
        cryptoclaw/cryptoclaw:latest
    echo "Gateway 容器已启动"
fi

# 启动桌面客户端
if [[ "$OSTYPE" == "darwin"* ]]; then
    open ~/.cryptoclaw/client/CryptoClaw.dmg
else
    ~/.cryptoclaw/client/CryptoClaw.AppImage --no-sandbox
fi
EOF
    
    chmod +x "$LAUNCHER"
    
    # 创建桌面快捷方式 (Linux)
    if [[ "$OS" == "linux" ]]; then
        DESKTOP_FILE="$HOME/.local/share/applications/cryptoclaw.desktop"
        mkdir -p "$(dirname "$DESKTOP_FILE")"
        
        cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Name=CryptoClaw
Comment=AI 驱动的加密货币量化交易助手
Exec=$LAUNCHER
Icon=cryptoclaw
Terminal=false
Type=Application
Categories=Finance;
EOF
        
        echo -e "${GREEN}[✓]${NC} 创建桌面快捷方式"
    fi
    
    echo -e "${GREEN}[✓]${NC} 启动脚本创建完成"
}

# 显示完成信息
show_complete() {
    echo -e "\n${GREEN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║              ✅ CryptoClaw 安装完成！                      ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "\n${BLUE}启动方式：${NC}"
    echo "  1. 运行启动脚本: ~/.cryptoclaw/cryptoclaw.sh"
    if [[ "$OS" == "linux" ]]; then
        echo "  2. 或在应用菜单中找到 CryptoClaw"
    fi
    
    echo -e "\n${BLUE}首次使用：${NC}"
    echo "  1. 双击客户端图标启动"
    echo "  2. 按照欢迎向导配置 API Key"
    echo "  3. 连接 Gateway 开始使用"
    
    echo -e "\n${BLUE}目录结构：${NC}"
    echo "  ~/.cryptoclaw/"
    echo "  ├── config/          # 配置文件"
    echo "  ├── user_data/       # 用户数据"
    echo "  ├── workspace/       # 工作空间"
    echo "  ├── logs/            # 日志文件"
    echo "  └── client/          # 桌面客户端"
    
    echo -e "\n${BLUE}卸载方式：${NC}"
    echo "  rm -rf ~/.cryptoclaw"
    echo "  docker rm -f cryptoclaw-gateway"
    echo "  docker rmi cryptoclaw/cryptoclaw"
    
    echo -e "\n${BLUE}更多信息：${NC}"
    echo "  文档: https://github.com/franklili3/CryptoClaw#readme"
    echo "  问题: https://github.com/franklili3/CryptoClaw/issues"
    
    echo -e "\n${YELLOW}提示: 现在可以运行 ~/.cryptoclaw/cryptoclaw.sh 启动 CryptoClaw${NC}"
}

# 主流程
main() {
    check_docker
    pull_image
    create_directories
    download_client
    create_launcher
    show_complete
}

main "$@"
