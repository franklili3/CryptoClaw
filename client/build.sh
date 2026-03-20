#!/bin/bash
# CryptoClaw Desktop Client 构建脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检查 Node.js
check_node() {
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version)
        log_success "Node.js installed: $NODE_VERSION"
    else
        log_error "Node.js not found. Please install Node.js 18+"
        exit 1
    fi
}

# 检查 npm
check_npm() {
    if command -v npm &> /dev/null; then
        NPM_VERSION=$(npm --version)
        log_success "npm installed: $NPM_VERSION"
    else
        log_error "npm not found"
        exit 1
    fi
}

# 安装依赖
install_deps() {
    log_info "Installing dependencies..."
    npm install
    log_success "Dependencies installed"
}

# 开发模式
run_dev() {
    log_info "Starting development mode..."
    npm start
}

# 构建 macOS
build_mac() {
    log_info "Building for macOS..."
    npm run build:mac
    log_success "macOS build complete!"
}

# 构建 Windows
build_win() {
    log_info "Building for Windows..."
    npm run build:win
    log_success "Windows build complete!"
}

# 构建 Linux
build_linux() {
    log_info "Building for Linux..."
    npm run build:linux
    log_success "Linux build complete!"
}

# 构建所有平台
build_all() {
    build_mac
    build_win
    build_linux
    log_success "All builds complete!"
}

# 显示帮助
show_help() {
    echo "CryptoClaw Desktop Client Build Script"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  check       Check build environment"
    echo "  install     Install dependencies"
    echo "  dev         Start development mode"
    echo "  build-mac   Build for macOS"
    echo "  build-win   Build for Windows"
    echo "  build-linux Build for Linux"
    echo "  build-all   Build for all platforms"
    echo "  help        Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 check"
    echo "  $0 install"
    echo "  $0 dev"
    echo "  $0 build-mac"
    echo "  $0 build-all"
}

# 主函数
main() {
    local command=$1
    
    cd "$(dirname "$0")"
    
    case "$command" in
        check)
            check_node
            check_npm
            ;;
        install)
            check_node
            check_npm
            install_deps
            ;;
        dev)
            run_dev
            ;;
        build-mac)
            build_mac
            ;;
        build-win)
            build_win
            ;;
        build-linux)
            build_linux
            ;;
        build-all)
            build_all
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            show_help
            exit 1
            ;;
    esac
}

main "$@"
