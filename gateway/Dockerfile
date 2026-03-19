# CryptoClaw Gateway - Multi-Architecture Docker Image
# Supports: linux/amd64, linux/arm64
# 
# 本镜像包含 OpenClaw Agent 运行时环境
#
# 构建时可通过 --build-arg 选择镜像源:
#   --build-arg BASE_IMAGE=node:20-alpine                    # 官方源 (默认，海外用户)
#   --build-arg BASE_IMAGE=docker.1ms.run/node:20-alpine     # 国内镜像源

# ============================================
# Stage 1: Builder (multi-arch aware)
# ============================================
# Note: OpenClaw requires Node.js >= 22.12.0
ARG BASE_IMAGE=node:22-alpine
FROM --platform=$BUILDPLATFORM ${BASE_IMAGE} AS builder

# Build arguments for cross-compilation
ARG BUILDPLATFORM
ARG TARGETPLATFORM
ARG TARGETARCH

WORKDIR /app

# Copy package files first (better layer caching)
COPY package*.json ./

# Install all dependencies (including devDependencies for build)
RUN npm install

# Copy source code
COPY . .

# Build TypeScript/JavaScript
RUN npm run build

# Prune dev dependencies for production
RUN npm prune --production

# ============================================
# Stage 2: Production Image (multi-arch)
# ============================================
# Note: OpenClaw requires Node.js >= 22.12.0
ARG BASE_IMAGE=node:22-alpine
FROM ${BASE_IMAGE} AS production

# Metadata labels
LABEL org.opencontainers.image.title="CryptoClaw Gateway"
LABEL org.opencontainers.image.description="AI-Powered Crypto Trading Assistant with OpenClaw Agent"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.vendor="CryptoClaw Team"
LABEL org.opencontainers.image.source="https://github.com/franklili3/CryptoClaw"

WORKDIR /app

# Configure Alpine mirror for China (auto-detect via build arg)
ARG ALPINE_MIRROR=""
RUN if [ -n "$ALPINE_MIRROR" ]; then \
        sed -i "s|https://dl-cdn.alpinelinux.org|${ALPINE_MIRROR}|g" /etc/apk/repositories; \
        cat /etc/apk/repositories; \
    fi

# Configure DNS for China (use public DNS servers to avoid v2rayA DNS issues)
RUN echo "nameserver 223.5.5.5" > /etc/resolv.conf && \
    echo "nameserver 119.29.29.29" >> /etc/resolv.conf && \
    echo "nameserver 8.8.8.8" >> /etc/resolv.conf

# Install system dependencies for OpenClaw
# - curl: HTTP requests and health checks
# - ca-certificates: HTTPS support
# - tzdata: Timezone data
# - bash: Shell scripts
# - git: Version control (for skills)
# - sqlite: Database support
RUN apk add --no-cache \
    curl \
    ca-certificates \
    tzdata \
    bash \
    git \
    sqlite \
    && rm -rf /var/cache/apk/*

# Create non-root user for security
RUN addgroup -S cryptoclaw && \
    adduser -S -G cryptoclaw -s /bin/sh cryptoclaw

# Install OpenClaw globally
RUN npm install -g openclaw@latest

# Verify OpenClaw installation
RUN openclaw --version

# Copy built application from builder
COPY --from=builder --chown=cryptoclaw:cryptoclaw /app/node_modules ./node_modules
COPY --from=builder --chown=cryptoclaw:cryptoclaw /app/dist ./dist
COPY --from=builder --chown=cryptoclaw:cryptoclaw /app/package.json ./

# Create OpenClaw workspace directories
RUN mkdir -p /app/workspace/skills \
    /app/workspace/memory \
    /app/workspace/config \
    /app/data/users \
    /app/logs \
    && chown -R cryptoclaw:cryptoclaw /app/workspace /app/data /app/logs

# Create default OpenClaw configuration
RUN mkdir -p /app/config && \
    echo '# OpenClaw Configuration\n\
# See: https://docs.openclaw.ai\n\
\n\
agents:\n\
  list:\n\
    - id: cryptoclaw\n\
      name: CryptoClaw\n\
      workspace: /app/workspace\n\
      model: openai/gpt-4\n\
      default: true\n\
\n\
bindings:\n\
  - agentId: cryptoclaw\n\
    match:\n\
      channel: telegram\n\
\n\
channels:\n\
  telegram:\n\
    accounts:\n\
      default:\n\
        botToken: ${TELEGRAM_BOT_TOKEN}\n\
        dmPolicy: pairing\n\
\n\
llm:\n\
  provider: ${LLM_PROVIDER:-openai}\n\
  apiKey: ${LLM_API_KEY}\n\
  model: ${LLM_MODEL:-gpt-4}\n\
' > /app/config/openclaw.yaml && \
    chown cryptoclaw:cryptoclaw /app/config/openclaw.yaml

# Copy default skills
COPY --chown=cryptoclaw:cryptoclaw skills/ /app/workspace/skills/

# Switch to non-root user
USER cryptoclaw

# Environment variables
ENV NODE_ENV=production \
    PORT=3000 \
    TZ=UTC \
    OPENCLAW_CONFIG=/app/config/openclaw.yaml \
    OPENCLAW_WORKSPACE=/app/workspace

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Start application
CMD ["node", "dist/server.js"]
