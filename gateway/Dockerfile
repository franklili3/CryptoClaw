# CryptoClaw Gateway - Multi-Architecture Docker Image
# Supports: linux/amd64, linux/arm64

# ============================================
# Stage 1: Builder (multi-arch aware)
# ============================================
FROM --platform=$BUILDPLATFORM node:20-alpine AS builder

# Build arguments for cross-compilation
ARG BUILDPLATFORM
ARG TARGETPLATFORM
ARG TARGETARCH

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    git \
    curl

# Copy package files first (better layer caching)
COPY package*.json ./

# Install all dependencies (including devDependencies for build)
RUN npm ci

# Copy source code
COPY . .

# Build TypeScript/JavaScript
RUN npm run build 2>/dev/null || true

# Prune dev dependencies for production
RUN npm prune --production

# ============================================
# Stage 2: Production Image (multi-arch)
# ============================================
FROM node:20-alpine AS production

# Metadata labels
LABEL org.opencontainers.image.title="CryptoClaw Gateway"
LABEL org.opencontainers.image.description="AI-Powered Crypto Trading Assistant"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.vendor="CryptoClaw Team"
LABEL org.opencontainers.image.source="https://github.com/franklili3/CryptoClaw"

WORKDIR /app

# Install runtime dependencies
# Note: These packages are available for both amd64 and arm64
RUN apk add --no-cache \
    curl \
    ca-certificates \
    tzdata \
    sqlite \
    && rm -rf /var/cache/apk/*

# Create non-root user for security
RUN addgroup -g 1000 cryptoclaw && \
    adduser -u 1000 -G cryptoclaw -s /bin/sh -D cryptoclaw

# Copy built application from builder
COPY --from=builder --chown=cryptoclaw:cryptoclaw /app/node_modules ./node_modules
COPY --from=builder --chown=cryptoclaw:cryptoclaw /app/dist ./dist
COPY --from=builder --chown=cryptoclaw:cryptoclaw /app/package.json ./
COPY --from=builder --chown=cryptoclaw:cryptoclaw /app/src ./src

# Copy skills and config
COPY --chown=cryptoclaw:cryptoclaw skills/ ./skills/
COPY --chown=cryptoclaw:cryptoclaw config/ ./config/

# Create data directories
RUN mkdir -p /app/data/users /app/logs && \
    chown -R cryptoclaw:cryptoclaw /app/data /app/logs

# Switch to non-root user
USER cryptoclaw

# Environment variables
ENV NODE_ENV=production
ENV PORT=3000
ENV TZ=UTC

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Start application
CMD ["node", "dist/server.js"]

# ============================================
# Stage 3: Development Image (optional)
# ============================================
FROM node:20-alpine AS development

WORKDIR /app

RUN apk add --no-cache \
    curl \
    git \
    python3 \
    make \
    g++

COPY package*.json ./
RUN npm install

COPY . .

ENV NODE_ENV=development
ENV PORT=3000

EXPOSE 3000

CMD ["npm", "run", "dev"]
