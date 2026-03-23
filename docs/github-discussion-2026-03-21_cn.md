# 开发日志：2026-03-21 - 安装体验优化与本地构建支持

## 概述 / Overview

今天的工作重点是**改善首次安装体验**，特别是针对开发者本地构建场景的优化。

Today's focus was on **improving the first-time installation experience**, especially for developers building locally.

---

## 完成的工作 / Completed Work

### 1. 安装脚本优化 / Installer Script Improvements

#### 问题 / Problem
原安装脚本假设用户从 GitHub Releases 下载预构建产物，没有考虑开发者本地构建的情况。

The original installer assumed users download pre-built artifacts from GitHub Releases, not considering developers building locally.

#### 解决方案 / Solution
修改 `scripts/install.sh`，增加本地构建检测：

Modified `scripts/install.sh` to detect local builds:

**Docker 镜像检测：**
```bash
# 先检查本地镜像是否存在
if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${IMAGE}$"; then
    echo -e "${GREEN}[✓]${NC} 本地镜像已存在: $IMAGE"
    return 0
fi
```

**客户端本地构建检测：**
```bash
# 优先使用本地构建的客户端
if [ -f "$LOCAL_CLIENT" ]; then
    echo -e "${GREEN}[✓]${NC} 发现本地构建的客户端"
    cp "$LOCAL_CLIENT" "$CLIENT_FILE"
    return 0
fi
```

#### 决策理由 / Rationale
1. **优先本地**：本地构建版本通常是最新的开发版本
2. **回退到远程**：本地不存在时才从 GitHub 下载
3. **零配置**：自动检测，无需用户指定路径

---

### 2. Docker 镜像源问题排查 / Docker Registry Mirror Troubleshooting

#### 问题 / Problem
在中国大陆使用阿里云 Docker 镜像源时遇到 TLS 握手失败：

TLS handshake failures when using Aliyun Docker registry mirror in mainland China:

```
ERROR: failed to solve: node:22-alpine: failed to resolve source metadata
```

#### 调试过程 / Debugging Process
1. 尝试多个镜像源（阿里云、DaoCloud、自定义）
2. 最终使用 `https://hub.rat.dev` 成功

#### 解决方案 / Solution
更新 `~/.docker/daemon.json`：
```json
{
  "dns": ["8.8.8.8", "114.114.114.114"],
  "registry-mirrors": ["https://hub.rat.dev"]
}
```

#### 经验教训 / Lessons Learned
- 镜像源稳定性是变化的，需要定期测试
- 考虑在文档中添加镜像源故障排查指南

---

### 3. macOS ARM64 客户端构建 / macOS ARM64 Client Build

#### 问题 / Problem
原 `dist/` 目录只有 Linux AppImage，缺少 macOS .dmg 文件。

Only Linux AppImage existed in `dist/`, missing macOS .dmg file.

#### 解决方案 / Solution
执行 Electron Builder 构建：
```bash
cd client && npm run build:mac
```

#### 构建产物 / Build Artifacts
- `CryptoQClaw-1.0.0-arm64.dmg` (92 MB) - Apple Silicon
- `CryptoQClaw-1.0.0-arm64-mac.zip` - 备用格式

---

### 4. 端到端安装测试 / End-to-End Installation Test

#### 测试环境 / Test Environment
- macOS 15 (Apple Silicon M2)
- Docker Desktop 29.2.0
- Node.js 24.13.0

#### 测试结果 / Test Results
| 步骤 | 状态 |
|------|------|
| Docker 镜像构建 | ✅ 成功 |
| macOS 客户端构建 | ✅ 成功 |
| 安装脚本执行 | ✅ 成功 |
| Gateway 容器启动 | ✅ 成功 |
| 客户端启动 | ✅ 成功 |

---

## 关键决策 / Key Decisions

### 决策 1：本地构建优先
**选择**：安装脚本优先使用本地构建产物
**理由**：
- 开发者通常在本地测试最新代码
- 避免 CI/CD 构建延迟
- 支持离线安装场景

### 决策 2：保留远程下载回退
**选择**：本地不存在时仍从 GitHub 下载
**理由**：
- 兼容非开发者用户
- 支持从 Releases 直接安装

### 决策 3：Docker 镜像源可配置
**选择**：使用 `daemon.json` 配置而非硬编码
**理由**：
- 不同地区用户有不同需求
- 便于故障排查和切换

---

## 遗留问题 / Open Issues

1. **Windows 支持**：需要创建 `.ps1` 安装脚本
2. **自动更新**：客户端缺少 `app-update.yml`
3. **国际化**：安装脚本仅支持英文输出

---

## 下一步 / Next Steps

1. 完善安装文档，添加镜像源故障排查指南
2. 测试 Linux 安装流程
3. 考虑添加 Windows 支持
4. 探索 GStack 工作流集成

---

## 相关链接 / Related Links

- [安装文档](../README.md#installation)
- [技术规格](./technical-spec.md)
- [设计文档](./design.md)

---

*本帖由 AI 辅助生成，基于今日开发会话记录整理。*
