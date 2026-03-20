# CryptoClaw 一键安装脚本 (Windows PowerShell)
# 版本: v1.0.0
# 用法: irm cryptoclaw.pro/install.ps1 | iex

param(
    [switch]$SkipDocker,
    [switch]$SkipWizard
)

$ErrorActionPreference = "Stop"

# 版本信息
$VERSION = "1.0.0"
$DOCKER_IMAGE = "cryptoclaw/cryptoclaw:latest"
$CONFIG_DIR = "$env:USERPROFILE\.cryptoclaw"

# 颜色函数
function Write-Info { param($msg) Write-Host "[INFO] " -ForegroundColor Blue -NoNewline; Write-Host $msg }
function Write-Success { param($msg) Write-Host "[SUCCESS] " -ForegroundColor Green -NoNewline; Write-Host $msg }
function Write-Warning { param($msg) Write-Host "[WARNING] " -ForegroundColor Yellow -NoNewline; Write-Host $msg }
function Write-Error { param($msg) Write-Host "[ERROR] " -ForegroundColor Red -NoNewline; Write-Host $msg }

# 显示横幅
function Show-Banner {
    Write-Host ""
    Write-Host "   _____                _ _          _____      _            " -ForegroundColor Cyan
    Write-Host "  / ____|              | | |        / ____|    | |           " -ForegroundColor Cyan
    Write-Host " | |     ___  _ __  ___| | | ___   | |     __ _| | _____ _ __" -ForegroundColor Cyan
    Write-Host " | |    / _ \| '_ \/ __| | |/ _ \  | |    / _` | |/ / _ \ '__|" -ForegroundColor Cyan
    Write-Host " | |___| (_) | | | \__ \ | |  __/  | |___| (_| |   <  __/ |   " -ForegroundColor Cyan
    Write-Host "  \_____\___/|_| |_|___/_|_|\___|   \_____\__,_|_|\_\___|_|   " -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  AI-Powered Crypto Trading Assistant" -ForegroundColor Cyan
    Write-Host "  Version: $VERSION"
    Write-Host "  Docker Image: $DOCKER_IMAGE"
    Write-Host ""
}

# 检查 Docker
function Check-Docker {
    if ($SkipDocker) {
        Write-Warning "Skipping Docker check"
        return
    }

    try {
        $dockerVersion = docker --version 2>$null
        Write-Success "Docker installed: $dockerVersion"
        
        # 检查 Docker 是否运行
        docker info 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Docker is running"
        } else {
            Write-Error "Docker is not running. Please start Docker Desktop."
            exit 1
        }
    } catch {
        Write-Error "Docker not found. Please install Docker Desktop:"
        Write-Error "https://docs.docker.com/desktop/install/windows-install/"
        exit 1
    }
}

# 创建目录结构
function Create-Directories {
    Write-Info "Creating directory structure..."
    
    $dirs = @(
        "$CONFIG_DIR\config",
        "$CONFIG_DIR\user_data\strategies",
        "$CONFIG_DIR\user_data\data",
        "$CONFIG_DIR\user_data\notebooks",
        "$CONFIG_DIR\user_data\plot",
        "$CONFIG_DIR\workspace",
        "$CONFIG_DIR\logs"
    )
    
    foreach ($dir in $dirs) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }
    
    Write-Success "Directory structure created at $CONFIG_DIR"
}

# 拉取 Docker 镜像
function Pull-Image {
    Write-Info "Pulling CryptoClaw Docker image..."
    docker pull $DOCKER_IMAGE
    Write-Success "Docker image pulled successfully"
}

# 创建配置文件模板
function Create-ConfigTemplates {
    Write-Info "Creating configuration templates..."
    
    # 创建 .env 模板
    $envContent = @"
# CryptoClaw 环境变量配置
# 复制此文件为 .env 并填写实际值

# Telegram Bot Token (从 @BotFather 获取)
TELEGRAM_BOT_TOKEN=your_bot_token_here

# LLM API 配置
LLM_PROVIDER=openai
LLM_API_KEY=your_api_key_here
LLM_MODEL=gpt-4

# 交易所 API (可选，用于实盘交易)
# BINANCE_API_KEY=your_binance_api_key
# BINANCE_API_SECRET=your_binance_api_secret
"@
    $envContent | Out-File -FilePath "$CONFIG_DIR\config\.env.example" -Encoding utf8
    
    # 创建 OpenClaw 配置模板
    $yamlContent = @"
# OpenClaw Gateway 配置

gateway:
  name: cryptoclaw
  port: 8080

channels:
  telegram:
    enabled: true
    token: `${TELEGRAM_BOT_TOKEN}
  whatsapp:
    enabled: false
  feishu:
    enabled: false

llm:
  provider: `${LLM_PROVIDER}
  apiKey: `${LLM_API_KEY}
  model: `${LLM_MODEL}

freqtrade:
  configPath: /app/user_data/config.json
  userDataDir: /app/user_data
"@
    $yamlContent | Out-File -FilePath "$CONFIG_DIR\config\openclaw.yaml.example" -Encoding utf8
    
    # 创建 docker-compose.yml
    $composeContent = @"
version: '3.8'

services:
  cryptoclaw:
    image: cryptoclaw/cryptoclaw:latest
    container_name: cryptoclaw
    restart: unless-stopped
    
    volumes:
      - C:\Users\`$env:USERNAME\.cryptoclaw\config\openclaw.yaml:/app/config/openclaw.yaml:ro
      - C:\Users\`$env:USERNAME\.cryptoclaw\user_data:/app/user_data
      - C:\Users\`$env:USERNAME\.cryptoclaw\workspace:/app/workspace
      - C:\Users\`$env:USERNAME\.cryptoclaw\logs:/app/logs
    
    ports:
      - "8080:8080"
    
    env_file:
      - C:\Users\`$env:USERNAME\.cryptoclaw\config\.env
    
    environment:
      - TZ=Asia/Shanghai
      - LOG_LEVEL=info
      - OPENCLAW_CONFIG=/app/config/openclaw.yaml
"@
    $composeContent | Out-File -FilePath "$CONFIG_DIR\config\docker-compose.yml" -Encoding utf8
    
    Write-Success "Configuration templates created"
}

# 创建启动/停止脚本
function Create-Scripts {
    Write-Info "Creating utility scripts..."
    
    # 启动脚本
    $startContent = @"
# CryptoClaw 启动脚本
cd `$env:USERPROFILE\.cryptoclaw
docker-compose -f config\docker-compose.yml up -d
Write-Host "✅ CryptoClaw 已启动" -ForegroundColor Green
Write-Host "📱 在 Telegram 中搜索您的 Bot 发送 /start 开始使用"
"@
    $startContent | Out-File -FilePath "$CONFIG_DIR\start.ps1" -Encoding utf8
    
    # 停止脚本
    $stopContent = @"
# CryptoClaw 停止脚本
cd `$env:USERPROFILE\.cryptoclaw
docker-compose -f config\docker-compose.yml down
Write-Host "✅ CryptoClaw 已停止" -ForegroundColor Green
"@
    $stopContent | Out-File -FilePath "$CONFIG_DIR\stop.ps1" -Encoding utf8
    
    # 状态检查脚本
    $statusContent = @"
# CryptoClaw 状态检查脚本
Write-Host "📊 CryptoClaw 状态" -ForegroundColor Cyan
Write-Host "=================="

`$running = docker ps --filter "name=cryptoclaw" --format "{{.Names}}" 2>`$null
if (`$running -eq "cryptoclaw") {
    Write-Host "✅ 服务运行中" -ForegroundColor Green
    docker exec cryptoclaw cat /app/VERSION 2>`$null
    Write-Host ""
    Write-Host "运行时间:"
    docker ps --format "table {{.Status}}" -f name=cryptoclaw
} else {
    Write-Host "❌ 服务未运行" -ForegroundColor Red
    Write-Host "运行 ~/.cryptoclaw/start.ps1 启动服务"
}
"@
    $statusContent | Out-File -FilePath "$CONFIG_DIR\status.ps1" -Encoding utf8
    
    Write-Success "Utility scripts created"
}

# 运行配置向导
function Run-ConfigWizard {
    if ($SkipWizard) {
        Write-Info "Skipping configuration wizard"
        return
    }
    
    Write-Info "Starting configuration wizard..."
    
    # 检查是否已有配置
    if (Test-Path "$CONFIG_DIR\config\.env") {
        Write-Warning "检测到已有配置文件"
        $reply = Read-Host "是否重新配置？(y/n)"
        if ($reply -ne "y") {
            Write-Info "使用现有配置"
            return
        }
    }
    
    # 复制模板
    Copy-Item "$CONFIG_DIR\config\.env.example" "$CONFIG_DIR\config\.env"
    Copy-Item "$CONFIG_DIR\config\openclaw.yaml.example" "$CONFIG_DIR\config\openclaw.yaml"
    
    Write-Host ""
    Write-Host "🔧 CryptoClaw 配置向导" -ForegroundColor Yellow
    Write-Host "========================"
    Write-Host ""
    
    # 配置 Telegram Bot
    Write-Host "📱 Telegram Bot 配置" -ForegroundColor Blue
    Write-Host "-------------------"
    Write-Host "请按照以下步骤获取 Bot Token:"
    Write-Host "1. 在 Telegram 中搜索 @BotFather"
    Write-Host "2. 发送 /newbot 创建新 Bot"
    Write-Host "3. 按提示设置 Bot 名称"
    Write-Host "4. 复制获得的 Token"
    Write-Host ""
    $telegramToken = Read-Host "请输入您的 Telegram Bot Token"
    
    # 配置 LLM
    Write-Host ""
    Write-Host "🤖 LLM API 配置" -ForegroundColor Blue
    Write-Host "--------------"
    Write-Host "请选择 LLM 提供商:"
    Write-Host "1) OpenAI (推荐)"
    Write-Host "2) Anthropic Claude"
    Write-Host "3) 本地模型（跳过）"
    $llmChoice = Read-Host "请选择 (1-3)"
    
    $llmProvider = ""
    $llmKey = ""
    $llmModel = ""
    
    switch ($llmChoice) {
        "1" {
            $llmProvider = "openai"
            $llmKey = Read-Host "请输入 OpenAI API Key (sk-...)"
            $llmModel = "gpt-4"
        }
        "2" {
            $llmProvider = "anthropic"
            $llmKey = Read-Host "请输入 Anthropic API Key (sk-ant-...)"
            $llmModel = "claude-3-opus-20240229"
        }
        "3" {
            $llmProvider = "local"
            Write-Warning "将使用本地模型，需要在配置文件中手动设置"
        }
        default {
            Write-Warning "无效选择，跳过 LLM 配置"
        }
    }
    
    # 更新 .env 文件
    $envContent = Get-Content "$CONFIG_DIR\config\.env" -Raw
    
    if ($telegramToken) {
        $envContent = $envContent -replace "your_bot_token_here", $telegramToken
    }
    
    if ($llmKey) {
        $envContent = $envContent -replace "your_api_key_here", $llmKey
        $envContent = $envContent -replace "LLM_PROVIDER=openai", "LLM_PROVIDER=$llmProvider"
        if ($llmModel) {
            $envContent = $envContent -replace "LLM_MODEL=gpt-4", "LLM_MODEL=$llmModel"
        }
    }
    
    $envContent | Out-File -FilePath "$CONFIG_DIR\config\.env" -Encoding utf8 -NoNewline
    
    Write-Success "配置完成！"
    Write-Host ""
    Write-Host "配置文件位置:"
    Write-Host "  - $CONFIG_DIR\config\.env (敏感信息)"
    Write-Host "  - $CONFIG_DIR\config\openclaw.yaml (OpenClaw 配置)"
    Write-Host ""
}

# 显示完成信息
function Show-Completion {
    Write-Host ""
    Write-Success "CryptoClaw 安装完成！"
    Write-Host ""
    Write-Host "📁 安装位置: $CONFIG_DIR"
    Write-Host ""
    Write-Host "🚀 快速开始:"
    Write-Host "   1. 启动服务:    ~/.cryptoclaw/start.ps1"
    Write-Host "   2. 检查状态:    ~/.cryptoclaw/status.ps1"
    Write-Host "   3. 停止服务:    ~/.cryptoclaw/stop.ps1"
    Write-Host ""
    Write-Host "📱 Telegram 使用:"
    Write-Host "   - 搜索您创建的 Bot"
    Write-Host "   - 发送 /start 开始使用"
    Write-Host ""
    Write-Host "📚 文档: https://cryptoclaw.pro/docs"
    Write-Host "💬 支持: @CryptoClawBot"
    Write-Host ""
}

# 主函数
function Main {
    Show-Banner
    Check-Docker
    Create-Directories
    Pull-Image
    Create-ConfigTemplates
    Create-Scripts
    Run-ConfigWizard
    Show-Completion
}

# 运行安装
Main
