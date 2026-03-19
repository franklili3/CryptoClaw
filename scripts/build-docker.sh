#!/bin/bash
# CryptoClaw 多架构 Docker 构建脚本
# 
# 用法:
#   ./build-docker.sh              # 构建当前平台
#   ./build-docker.sh --multi      # 构建多架构 (amd64 + arm64)
#   ./build-docker.sh --push       # 构建并推送到 Docker Hub
#   ./build-docker.sh --local      # 构建并加载到本地 Docker
#   ./build-docker.sh --china      # 使用国内镜像源

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 默认值
REGISTRY="cryptoclaw"
IMAGE_NAME="cryptoclaw"
VERSION="${VERSION:-$(git describe --tags --always --dirty 2>/dev/null || echo 'dev')}"
GIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')
PLATFORMS="linux/amd64"
PUSH=false
LOAD=false
USE_CHINA_MIRROR=false

# 镜像源配置
OFFICIAL_BASE="node:20-alpine"
CHINA_MIRRORS=(
    "docker.1ms.run/node:20-alpine"
    "docker.xuanyuan.me/node:20-alpine"
    "dockerhub.icu/node:20-alpine"
)

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${CYAN}[STEP]${NC} $1"; }

# 显示帮助
show_help() {
    echo "CryptoClaw 多架构 Docker 构建脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --multi        构建多架构镜像 (amd64 + arm64)"
    echo "  --push         构建并推送到 Docker Hub"
    echo "  --local        构建并加载到本地 Docker"
    echo "  --arm64        只构建 ARM64"
    echo "  --amd64        只构建 AMD64"
    echo "  --china        使用国内镜像源"
    echo "  --registry R   指定镜像仓库 (默认: cryptoclaw)"
    echo "  --version V    指定版本标签 (默认: git tag 或 'dev')"
    echo "  --help         显示此帮助信息"
    echo ""
    echo "镜像源选择:"
    echo "  自动检测: 脚本会自动检测网络环境，选择最优镜像源"
    echo "  --china:  强制使用国内镜像源 (适用于国内网络)"
    echo ""
    echo "示例:"
    echo "  $0 --local                     # 本地构建 (自动选择镜像源)"
    echo "  $0 --local --china             # 本地构建 (强制国内源)"
    echo "  $0 --multi --push              # 多架构构建并推送"
    echo "  VERSION=1.0.0 $0 --multi       # 指定版本"
    echo ""
}

# 检测是否在中国大陆
detect_china_region() {
    # 方法1：检查时区
    if [ -f /etc/timezone ] && grep -q "Asia/Shanghai\|China\|Beijing" /etc/timezone 2>/dev/null; then
        return 0
    fi
    
    # 方法2：检查语言环境
    if echo "$LANG" | grep -qi "zh_CN\|zh_CN.UTF-8" 2>/dev/null; then
        return 0
    fi
    
    # 方法3：尝试访问 Google（不可用则认为在中国）
    if ! curl -s --max-time 3 https://www.google.com > /dev/null 2>&1; then
        return 0
    fi
    
    return 1
}

# 获取基础镜像
get_base_image() {
    if [ "$USE_CHINA_MIRROR" = true ]; then
        log_info "使用国内镜像源"
        # 尝试国内镜像源
        for mirror in "${CHINA_MIRRORS[@]}"; do
            log_info "尝试镜像: $mirror"
            if curl -s --max-time 5 "https://${mirror%%/*}/v2/" > /dev/null 2>&1; then
                BASE_IMAGE="$mirror"
                log_success "选择镜像源: $BASE_IMAGE"
                return 0
            fi
        done
        # 如果都不可用，使用第一个
        BASE_IMAGE="${CHINA_MIRRORS[0]}"
        log_warning "无法测试镜像源连通性，使用默认: $BASE_IMAGE"
    else
        # 自动检测
        if detect_china_region; then
            log_info "检测到中国大陆网络环境"
            USE_CHINA_MIRROR=true
            get_base_image
            return
        else
            log_info "使用官方镜像源"
            BASE_IMAGE="$OFFICIAL_BASE"
        fi
    fi
}

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --multi)
            PLATFORMS="linux/amd64,linux/arm64"
            shift
            ;;
        --push)
            PUSH=true
            shift
            ;;
        --local)
            LOAD=true
            PLATFORMS="linux/amd64"
            shift
            ;;
        --arm64)
            PLATFORMS="linux/arm64"
            LOAD=true
            shift
            ;;
        --amd64)
            PLATFORMS="linux/amd64"
            LOAD=true
            shift
            ;;
        --china)
            USE_CHINA_MIRROR=true
            shift
            ;;
        --registry)
            REGISTRY="$2"
            shift 2
            ;;
        --version)
            VERSION="$2"
            shift 2
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            log_error "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
done

# 检查 buildx
check_buildx() {
    log_step "检查 Docker Buildx..."
    
    if ! docker buildx version &> /dev/null; then
        log_error "Docker Buildx 不可用"
        log_error "请升级 Docker 到支持 buildx 的版本"
        exit 1
    fi
    
    log_success "Docker Buildx 可用"
    
    # 检查 QEMU (多架构支持)
    if [[ "$PLATFORMS" == *"arm64"* ]] || [[ "$PLATFORMS" == *"amd64,linux/arm64"* ]]; then
        if ! docker run --rm --privileged multiarch/qemu-user-static --reset -p yes &> /dev/null; then
            log_warning "QEMU 设置可能需要手动配置"
        fi
    fi
}

# 创建 builder 实例
create_builder() {
    log_step "配置 Buildx Builder..."
    
    BUILDER_NAME="cryptoclaw-builder"
    
    # 检查 builder 是否存在
    if docker buildx inspect $BUILDER_NAME &> /dev/null; then
        log_info "使用现有 builder: $BUILDER_NAME"
    else
        log_info "创建新 builder: $BUILDER_NAME"
        docker buildx create --name $BUILDER_NAME --driver docker-container --use
        docker buildx inspect --bootstrap
    fi
}

# 构建镜像
build_image() {
    log_step "构建 Docker 镜像..."
    
    cd "$(dirname "$0")/.."
    
    # 检查 Dockerfile
    if [ ! -f "gateway/Dockerfile" ]; then
        log_error "找不到 gateway/Dockerfile"
        exit 1
    fi
    
    # 获取基础镜像
    get_base_image
    
    # 构建参数
    BUILD_ARGS="--build-arg VERSION=${VERSION} --build-arg GIT_SHA=${GIT_SHA} --build-arg BASE_IMAGE=${BASE_IMAGE}"
    
    # 标签
    TAGS="-t ${REGISTRY}/${IMAGE_NAME}:${VERSION}"
    if [ "$VERSION" != "dev" ] && [ "$VERSION" != "latest" ]; then
        TAGS="${TAGS} -t ${REGISTRY}/${IMAGE_NAME}:latest"
    fi
    
    # 输出类型
    if [ "$PUSH" = true ]; then
        OUTPUT="--output type=registry"
        log_info "构建后将推送到: ${REGISTRY}/${IMAGE_NAME}"
    elif [ "$LOAD" = true ]; then
        OUTPUT="--load"
        log_info "构建后将加载到本地 Docker"
    else
        OUTPUT="--output type=docker"
        log_info "仅构建，不推送"
    fi
    
    log_info "平台: ${PLATFORMS}"
    log_info "版本: ${VERSION}"
    log_info "Git SHA: ${GIT_SHA}"
    log_info "基础镜像: ${BASE_IMAGE}"
    
    # 执行构建
    docker buildx build \
        --platform ${PLATFORMS} \
        ${TAGS} \
        ${BUILD_ARGS} \
        ${OUTPUT} \
        --file gateway/Dockerfile \
        gateway/
    
    log_success "构建完成!"
}

# 验证镜像
verify_image() {
    if [ "$LOAD" = true ] || [ "$PUSH" = true ]; then
        log_step "验证镜像..."
        
        # 检查镜像架构
        IMAGE_ARCH=$(docker inspect --format='{{.Architecture}}' ${REGISTRY}/${IMAGE_NAME}:${VERSION} 2>/dev/null || echo "unknown")
        log_info "镜像架构: ${IMAGE_ARCH}"
        
        # 检查镜像大小
        IMAGE_SIZE=$(docker inspect --format='{{.Size}}' ${REGISTRY}/${IMAGE_NAME}:${VERSION} 2>/dev/null || echo "unknown")
        if [ "$IMAGE_SIZE" != "unknown" ]; then
            SIZE_MB=$((IMAGE_SIZE / 1024 / 1024))
            log_info "镜像大小: ${SIZE_MB} MB"
        fi
        
        log_success "验证完成"
    fi
}

# 显示使用说明
show_usage() {
    echo ""
    echo -e "${GREEN}构建完成！${NC}"
    echo ""
    echo "镜像: ${REGISTRY}/${IMAGE_NAME}:${VERSION}"
    echo ""
    
    if [ "$PUSH" = true ]; then
        echo "推送命令:"
        echo "  docker pull ${REGISTRY}/${IMAGE_NAME}:${VERSION}"
        echo ""
    fi
    
    echo "运行命令:"
    echo "  docker run -d -p 3000:3000 --name cryptoclaw ${REGISTRY}/${IMAGE_NAME}:${VERSION}"
    echo ""
    echo "使用 docker-compose:"
    echo "  cd ~/.cryptoclaw && docker-compose -f config/docker-compose.yml up -d"
    echo ""
}

# 主函数
main() {
    log_info "CryptoClaw 多架构构建脚本"
    log_info "========================"
    
    check_buildx
    create_builder
    build_image
    verify_image
    show_usage
}

main
