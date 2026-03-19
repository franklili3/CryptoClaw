# CryptoClaw 管理员指南

> 构建和发布指南

本文档面向 CryptoClaw 项目维护者，包含构建、测试、发布的完整流程。

---

## 📋 目录

- [环境准备](#环境准备)
- [本地开发](#本地开发)
- [Docker 镜像构建](#docker-镜像构建)
- [多架构构建](#多架构构建)
- [桌面客户端构建](#桌面客户端构建)
- [发布流程](#发布流程)
- [版本管理](#版本管理)
- [CI/CD 说明](#cicd-说明)
- [故障排除](#故障排除)

---

## 环境准备

### 必需工具

| 工具 | 版本 | 用途 |
|------|------|------|
| Docker | 24.0+ | 容器构建 |
| Docker Buildx | 最新 | 多架构构建 |
| Git | 2.40+ | 版本控制 |
| Node.js | 20+ | 本地开发 |
| QEMU | 最新 | 跨平台模拟 |

### 桌面客户端构建工具

| 工具 | 版本 | 用途 |
|------|------|------|
| Electron | 28+ | 桌面应用框架 |
| electron-builder | 24+ | 打包工具 |
| macOS | 12+ | macOS 构建（需要 Xcode） |
| Windows | 10+ | Windows 构建 |
| Linux | Ubuntu 20.04+ | Linux 构建 |

### 安装 Buildx 和 QEMU

```bash
# 启用 Docker Buildx
docker buildx install

# 安装 QEMU（多架构支持）
docker run --privileged --rm tonistiigi/binfmt --install all

# 验证
docker buildx version
docker buildx inspect --bootstrap
```

### 配置 Docker Hub

```bash
# 登录 Docker Hub
docker login

# 或使用环境变量
export DOCKER_USERNAME=your_username
export DOCKER_PASSWORD=your_token
```

---

## 本地开发

### 克隆仓库

```bash
git clone https://github.com/franklili3/CryptoClaw.git
cd CryptoClaw
```

### 安装依赖

```bash
# Gateway 依赖
cd gateway
npm install

# 客户端依赖
cd ../client
npm install
```

### 启动开发环境

```bash
# 启动 Gateway（开发模式）
cd gateway
npm run dev

# 启动桌面客户端（开发模式）
cd client
npm start
```

---

## Docker 构建

### 快速构建

```bash
# 构建当前平台镜像
./scripts/build-docker.sh --local

# 查看构建结果
docker images | grep cryptoclaw
```

### 使用 Docker 命令

```bash
# 构建镜像
cd gateway
docker build -t cryptoclaw/cryptoclaw:dev .

# 运行容器
docker run -d \
  --name cryptoclaw-dev \
  -p 3000:3000 \
  -e NODE_ENV=development \
  cryptoclaw/cryptoclaw:dev

# 查看日志
docker logs -f cryptoclaw-dev
```

### 构建参数

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `VERSION` | 版本号 | git tag 或 dev |
| `GIT_SHA` | Git 提交 | 当前 commit |

```bash
docker build \
  --build-arg VERSION=1.0.0 \
  --build-arg GIT_SHA=abc123 \
  -t cryptoclaw/cryptoclaw:1.0.0 .
```

---

## 多架构构建

### 支持的架构

| 架构 | Docker 平台 | 用途 |
|------|-------------|------|
| x86_64 | linux/amd64 | Intel/AMD 处理器 |
| ARM64 | linux/arm64 | Apple Silicon, 树莓派, AWS Graviton |

### 使用构建脚本

```bash
# 查看帮助
./scripts/build-docker.sh --help

# 构建多架构（不推送）
./scripts/build-docker.sh --multi

# 构建并推送到 Docker Hub
./scripts/build-docker.sh --multi --push

# 仅构建 AMD64
./scripts/build-docker.sh --amd64 --local

# 仅构建 ARM64
./scripts/build-docker.sh --arm64 --local

# 指定版本
VERSION=1.0.0 ./scripts/build-docker.sh --multi --push
```

### 使用 Docker Buildx

```bash
# 创建 builder 实例
docker buildx create --name cryptoclaw-builder --use

# 构建多架构镜像
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t cryptoclaw/cryptoclaw:latest \
  -t cryptoclaw/cryptoclaw:1.0.0 \
  --push \
  ./gateway

# 构建并加载到本地（单架构）
docker buildx build \
  --platform linux/amd64 \
  -t cryptoclaw/cryptoclaw:dev \
  --load \
  ./gateway
```

### 使用 docker-bake.hcl

```bash
# 默认构建（多架构）
docker buildx bake

# 开发构建（单架构，快速）
docker buildx bake dev

# 生产构建并推送
docker buildx bake cryptoclaw-prod

# 发布版本
docker buildx bake release
```

---

## 桌面客户端构建

### 支持的平台

| 平台 | 架构 | 输出格式 |
|------|------|----------|
| macOS (Intel) | x64 | dmg, zip |
| macOS (Apple Silicon) | arm64 | dmg, zip |
| Windows | x64 | nsis (安装包), portable (便携版) |
| Linux | x64 | AppImage, deb, tar.gz |

### 本地开发测试

```bash
cd client

# 安装依赖
npm install

# 开发模式启动
npm start

# 热重载开发
npm run dev
```

### 构建客户端

#### macOS

```bash
cd client

# 构建当前架构
npm run build:mac

# 构建指定架构
npm run build:mac -- --x64    # Intel Mac
npm run build:mac -- --arm64  # Apple Silicon

# 构建通用二进制（Universal）
npm run build:mac -- --universal
```

**输出位置：** `client/dist/`

```
dist/
├── CryptoClaw-1.0.0.dmg           # Intel
├── CryptoClaw-1.0.0-arm64.dmg     # Apple Silicon
├── CryptoClaw-1.0.0-universal.dmg # 通用
└── ...
```

#### Windows

```bash
cd client

# 构建安装包
npm run build:win

# 构建便携版
npm run build:win -- --win portable

# 同时构建多个格式
npm run build:win -- --win nsis,portable
```

**输出位置：** `client/dist/`

```
dist/
├── CryptoClaw Setup 1.0.0.exe     # 安装包
├── CryptoClaw 1.0.0.exe           # 便携版
└── ...
```

#### Linux

```bash
cd client

# 构建所有格式
npm run build:linux

# 构建指定格式
npm run build:linux -- --linux AppImage
npm run build:linux -- --linux deb
npm run build:linux -- --linux tar.gz

# 构建多个格式
npm run build:linux -- --linux AppImage,deb
```

**输出位置：** `client/dist/`

```
dist/
├── CryptoClaw-1.0.0.AppImage      # AppImage (通用)
├── cryptoclaw_1.0.0_amd64.deb     # Debian/Ubuntu
├── cryptoclaw-1.0.0.tar.gz        # 压缩包
└── ...
```

### 构建所有平台

```bash
cd client

# 构建所有平台（需要在对应平台上运行）
npm run build

# 或使用 electron-builder 直接构建
npx electron-builder --mac --win --linux
```

### 代码签名

#### macOS 签名

需要 Apple Developer 证书：

```bash
# 设置环境变量
export CSC_LINK=/path/to/certificate.p12
export CSC_KEY_PASSWORD=your_password

# 构建时会自动签名
npm run build:mac
```

#### Windows 签名

需要代码签名证书：

```bash
# 设置环境变量
export CSC_LINK=/path/to/certificate.pfx
export CSC_KEY_PASSWORD=your_password

# 构建时会自动签名
npm run build:win
```

### 自动更新配置

客户端支持自动更新，配置在 `electron-builder.yml`：

```yaml
publish:
  provider: github
  owner: franklili3
  repo: CryptoClaw
  releaseType: release

autoUpdate:
  checkUpdateOnStart: true
  autoDownload: true
```

### 测试客户端

#### 功能测试清单

- [ ] 应用启动正常
- [ ] 窗口显示正确
- [ ] 菜单功能正常
- [ ] 系统托盘图标
- [ ] 自动更新检测
- [ ] 快捷键功能
- [ ] 文件拖放
- [ ] 通知功能
- [ ] 剪贴板操作

#### 手动测试命令

```bash
# macOS
open dist/CryptoClaw-1.0.0.dmg

# Windows (PowerShell)
Start-Process "dist\CryptoClaw Setup 1.0.0.exe"

# Linux
./dist/CryptoClaw-1.0.0.AppImage
```

#### 自动化测试

```bash
cd client

# 运行单元测试
npm test

# 运行 E2E 测试（如果配置了）
npm run e2e
```

### 发布客户端

#### 方式一：自动发布（推荐）

推送标签后，GitHub Actions 会自动构建并发布到 GitHub Releases。

#### 方式二：手动发布

```bash
cd client

# 构建并发布到 GitHub
npm run build:publish

# 或使用 electron-builder
npx electron-builder --publish always
```

#### 方式三：手动上传

1. 构建客户端：
   ```bash
   npm run build
   ```

2. 手动上传到 GitHub Releases：
   ```bash
   gh release upload v1.0.0 \
     dist/CryptoClaw-1.0.0.dmg \
     dist/CryptoClaw-1.0.0-arm64.dmg \
     dist/CryptoClaw Setup 1.0.0.exe \
     dist/CryptoClaw-1.0.0.AppImage
   ```

### 客户端构建配置

配置文件：`client/electron-builder.yml`

```yaml
appId: pro.cryptoclaw.client
productName: CryptoClaw

# macOS 配置
mac:
  category: public.app-category.finance
  target:
    - target: dmg
      arch: [x64, arm64]

# Windows 配置
win:
  target:
    - target: nsis
      arch: [x64]

# Linux 配置
linux:
  category: Office
  target:
    - target: AppImage
      arch: [x64]
    - target: deb
      arch: [x64]
```

### 常见问题

#### macOS 构建失败

```bash
# 检查 Xcode 命令行工具
xcode-select --install

# 清理缓存
rm -rf ~/Library/Caches/electron
rm -rf ~/Library/Caches/electron-builder
```

#### Windows 构建失败

```powershell
# 以管理员身份运行 PowerShell
# 安装 Windows Build Tools
npm install -g windows-build-tools
```

#### Linux 依赖问题

```bash
# Ubuntu/Debian
sudo apt-get install -y \
  libgtk-3-0 libnotify4 libnss3 libxss1 \
  libxtst6 xdg-utils libatspi2.0-0 libuuid1 \
  libsecret-1-0 libgbm1

# Fedora
sudo dnf install -y \
  gtk3 libnotify nss libXScrnSaver libXtst \
  xdg-utils at-spi2-atk libuuid libsecret
```

---

## 发布流程

### 1. 准备发布

```bash
# 确保在 main 分支
git checkout main
git pull origin main

# 更新版本号
# 编辑 package.json, gateway/package.json, client/package.json
# 更新 README 中的版本信息

# 更新 CHANGELOG
# 记录本次更新的内容
```

### 2. 创建标签

```bash
# 创建带注释的标签
git tag -a v1.0.0 -m "Release v1.0.0

Features:
- 多架构 Docker 镜像支持 (amd64/arm64)
- 一键安装脚本
- ...

Bug Fixes:
- ...
"

# 推送标签
git push origin v1.0.0
```

### 3. 自动构建（CI/CD）

推送标签后，GitHub Actions 会自动：

1. ✅ 构建多架构 Docker 镜像 (amd64 + arm64)
2. ✅ 推送到 Docker Hub
3. ✅ 创建 GitHub Release

查看进度：`https://github.com/franklili3/CryptoClaw/actions`

### 4. 手动发布（备用）

如果 CI/CD 失败，可手动执行：

```bash
# 设置版本
export VERSION=1.0.0

# 构建并推送
./scripts/build-docker.sh --multi --push

# 验证镜像
docker pull cryptoclaw/cryptoclaw:$VERSION
docker inspect cryptoclaw/cryptoclaw:$VERSION | grep Architecture
```

### 5. 创建 GitHub Release

```bash
# 使用 gh CLI
gh release create v1.0.0 \
  --title "CryptoClaw v1.0.0" \
  --notes "## 新功能
- 多架构支持

## 安装
\`\`\`bash
curl -fsSL https://raw.githubusercontent.com/franklili3/CryptoClaw/main/scripts/install.sh | bash
\`\`\`
"
```

---

## 版本管理

### 版本号规范

使用 [语义化版本](https://semver.org/lang/zh-CN/)：

```
MAJOR.MINOR.PATCH

MAJOR - 不兼容的 API 变更
MINOR - 向后兼容的新功能
PATCH - 向后兼容的问题修复
```

### 示例

| 版本 | 说明 |
|------|------|
| `1.0.0` | 首个稳定版 |
| `1.1.0` | 新增功能 |
| `1.1.1` | 修复 Bug |
| `2.0.0` | 重大更新 |

### 预发布版本

```bash
# Alpha 版本（内部测试）
git tag v1.1.0-alpha.1

# Beta 版本（公开测试）
git tag v1.1.0-beta.1

# Release Candidate
git tag v1.1.0-rc.1
```

---

## CI/CD 说明

### 工作流文件

| 文件 | 用途 |
|------|------|
| `.github/workflows/docker-build.yml` | Docker 镜像构建 |
| `.github/workflows/client-build.yml` | 桌面客户端构建 |

### Docker 镜像工作流

位置：`.github/workflows/docker-build.yml`

#### 触发条件

| 事件 | 行为 |
|------|------|
| Push to main | 构建并推送 `latest` 标签 |
| Push tag (v*) | 构建并推送版本标签 |
| Pull Request | 仅构建测试，不推送 |
| Manual | 可选择是否推送 |

#### 构建矩阵

```yaml
platforms:
  - linux/amd64
  - linux/arm64
```

#### 生成的标签

| 条件 | 标签 |
|------|------|
| main 分支 | `latest`, `sha-xxx` |
| v1.0.0 标签 | `1.0.0`, `1.0`, `1`, `latest` |
| PR | 无（仅测试） |

### 手动触发

```bash
# 使用 gh CLI 触发
gh workflow run docker-build.yml -f push_image=true

# 或在 GitHub 网页上点击 "Run workflow"
```

### 桌面客户端工作流

位置：`.github/workflows/client-build.yml`（需要创建）

#### 触发条件

| 事件 | 行为 |
|------|------|
| Push tag (v*) | 构建并发布客户端 |
| Push to main | 仅测试构建 |
| Manual | 手动触发构建 |

#### 构建矩阵

```yaml
strategy:
  matrix:
    include:
      - os: macos-latest
        platform: mac
      - os: windows-latest
        platform: win
      - os: ubuntu-latest
        platform: linux
```

#### 生成的产物

| 平台 | 产物 |
|------|------|
| macOS | `CryptoClaw-{version}.dmg`, `CryptoClaw-{version}-arm64.dmg` |
| Windows | `CryptoClaw Setup {version}.exe`, `CryptoClaw {version}.exe` |
| Linux | `CryptoClaw-{version}.AppImage`, `cryptoclaw_{version}_amd64.deb` |

#### 手动触发客户端构建

```bash
# 使用 gh CLI 触发
gh workflow run client-build.yml

# 或在 GitHub 网页上点击 "Run workflow"
```

---

## 故障排除

### 构建失败

```bash
# 查看构建日志
docker buildx build --progress=plain ./gateway

# 清理缓存
docker builder prune -a

# 重新创建 builder
docker buildx rm cryptoclaw-builder
docker buildx create --name cryptoclaw-builder --use
```

### 推送失败

```bash
# 检查登录状态
docker login

# 检查权限
# 确保 Docker Hub 账号有写入权限

# 检查网络
curl -I https://registry-1.docker.io/v2/
```

### 架构不匹配

```bash
# 检查本地架构
uname -m

# 检查镜像架构
docker inspect --format='{{.Architecture}}' cryptoclaw/cryptoclaw:latest

# 拉取特定架构
docker pull --platform linux/arm64 cryptoclaw/cryptoclaw:latest
```

### QEMU 问题

```bash
# 重新安装 QEMU
docker run --privileged --rm tonistiigi/binfmt --uninstall all
docker run --privileged --rm tonistiigi/binfmt --install all

# 验证
docker run --rm --platform linux/arm64 alpine uname -m
# 应该输出: aarch64
```

---

## 检查清单

### 发布前检查

**Docker 镜像：**
- [ ] 所有测试通过
- [ ] 版本号已更新 (gateway/package.json)
- [ ] CHANGELOG 已更新
- [ ] README 文档已更新
- [ ] Docker Hub 凭据有效
- [ ] 本地多架构构建成功

**桌面客户端：**
- [ ] 客户端版本号已更新 (client/package.json)
- [ ] 本地客户端测试通过
- [ ] 代码签名证书有效（macOS/Windows）
- [ ] electron-builder.yml 配置正确

### 发布后检查

**Docker 镜像：**
- [ ] Docker Hub 镜像可拉取
- [ ] amd64 和 arm64 镜像都可用
- [ ] 安装脚本可正常工作

**桌面客户端：**
- [ ] GitHub Release 已创建
- [ ] macOS dmg 文件可下载
- [ ] Windows exe 文件可下载
- [ ] Linux AppImage 可下载
- [ ] 自动更新功能正常

---

## 常用命令速查

### Docker 镜像

```bash
# 快速构建（本地测试）
./scripts/build-docker.sh --local

# 多架构构建并推送
./scripts/build-docker.sh --multi --push

# 查看 builder 状态
docker buildx inspect --bootstrap

# 查看镜像信息
docker inspect cryptoclaw/cryptoclaw:latest | jq '.[0].Architecture'

# 清理构建缓存
docker builder prune

# 登录 Docker Hub
docker login
```

### 桌面客户端

```bash
# 开发模式
cd client && npm start

# 构建 macOS
npm run build:mac

# 构建 Windows
npm run build:win

# 构建 Linux
npm run build:linux

# 构建所有平台
npm run build

# 构建并发布
npm run build:publish
```

### Git 和 CI/CD

```bash
# 创建并推送标签
git tag v1.0.0 && git push origin v1.0.0

# 查看 CI 状态
gh run list --limit 5

# 手动触发 Docker 构建
gh workflow run docker-build.yml

# 手动触发客户端构建
gh workflow run client-build.yml

# 创建 GitHub Release
gh release create v1.0.0 --title "v1.0.0" --notes "Release notes"

# 上传客户端到 Release
gh release upload v1.0.0 dist/*
```

---

*最后更新: 2026-03-19*
