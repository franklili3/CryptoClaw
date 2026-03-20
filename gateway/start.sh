#!/bin/sh
# CryptoClaw Gateway 启动脚本
# 启动 OpenClaw Gateway 服务

# 配置环境变量
export OPENCLAW_STATE_DIR=/app/.openclaw

echo "========================================"
echo "Starting CryptoClaw Gateway..."
echo "========================================"
echo "Workspace: /app/workspace"
echo "State dir: ${OPENCLAW_STATE_DIR}"
echo ""

# 创建状态目录
mkdir -p ${OPENCLAW_STATE_DIR} 2>/dev/null || true

# 检查 openclaw 是否安装
if command -v openclaw >/dev/null 2>&1; then
    echo "OpenClaw found at: $(which openclaw)"
    echo "OpenClaw version: $(openclaw --version 2>&1)"
else
    echo "Error: OpenClaw not installed"
    exit 1
fi

# 配置 LLM 环境变量 (用于智谱 GLM)
if [ -n "${LLM_API_KEY}" ]; then
    echo "Configuring LLM: ${LLM_PROVIDER:-openai}/${LLM_MODEL:-gpt-4}"
    export ANTHROPIC_AUTH_TOKEN="${LLM_API_KEY}"
    if [ -n "${LLM_BASE_URL}" ]; then
        export ANTHROPIC_BASE_URL="${LLM_BASE_URL}"
    fi
fi

echo ""
echo "========================================"
echo "Starting OpenClaw Gateway..."
echo "========================================"

# 启动 OpenClaw Gateway
# --dev: 开发模式，自动创建默认配置
# --auth token: 使用 token 认证
# --port 19001: Gateway 端口
# --force: 强制杀死占用端口的进程
# --allow-unconfigured: 允许在没有完整配置的情况下启动
# --bind loopback: 绑定到本地回环地址（避免 control UI origin 问题）
exec openclaw gateway run \
    --dev \
    --auth token \
    --port 19001 \
    --force \
    --allow-unconfigured \
    --bind loopback
