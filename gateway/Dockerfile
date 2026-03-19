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
FROM node:20-alpine AS production

# Metadata labels
LABEL org.opencontainers.image.title="CryptoClaw Gateway"
LABEL org.opencontainers.image.description="AI-Powered Crypto Trading Assistant"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.vendor="CryptoClaw Team"
LABEL org.opencontainers.image.source="https://github.com/franklili3/CryptoClaw"

WORKDIR /app

# Create non-root user for security
RUN addgroup -S cryptoclaw && \
    adduser -S -G cryptoclaw -s /bin/sh cryptoclaw

# Copy built application from builder
COPY --from=builder --chown=cryptoclaw:cryptoclaw /app/node_modules ./node_modules
COPY --from=builder --chown=cryptoclaw:cryptoclaw /app/dist ./dist
COPY --from=builder --chown=cryptoclaw:cryptoclaw /app/package.json ./

# Create data directories
RUN mkdir -p /app/data /app/logs && \
    chown -R cryptoclaw:cryptoclaw /app/data /app/logs

# Switch to non-root user
USER cryptoclaw

# Environment variables
ENV NODE_ENV=production
ENV PORT=3000
ENV TZ=UTC

# Expose port
EXPOSE 3000

# Start application
CMD ["node", "dist/server.js"]
