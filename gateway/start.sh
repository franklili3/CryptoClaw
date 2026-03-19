#!/bin/sh
# CryptoClaw Gateway 启动脚本
# 启动 OpenClaw Gateway 服务

set -e

# 配置环境变量
export OPENCLAW_STATE_DIR=/app/.openclaw
export OPENCLAW_CONFIG_PATH=/app/config/openclaw.yaml

# 创建状态目录
mkdir -p ${OPENCLAW_STATE_DIR}

echo "Starting CryptoClaw Gateway..."
echo "OpenClaw config: ${OPENCLAW_CONFIG_PATH}"
echo "Workspace: ${OPENCLAW_WORKSPACE:-/app/workspace}"

# 检查配置文件是否存在
if [ -f "${OPENCLAW_CONFIG_PATH}" ]; then
    echo "Using config from: ${OPENCLAW_CONFIG_PATH}"
else
    echo "Warning: Config file not found at ${OPENCLAW_CONFIG_PATH}"
fi

# 启动 OpenClaw Gateway
# --dev: 开发模式（创建默认配置）
# --auth token: 使用 token 认证
# --port 19001: Gateway WebSocket 端口
# --force: 强制杀死占用端口的进程
# --allow-unconfigured: 允许在没有配置的情况下启动
# --bind lan: 绑定到所有网络接口
exec openclaw gateway run \
    --dev \
    --auth token \
    --port 19001 \
    --force \
    --allow-unconfigured \
    --bind lan
