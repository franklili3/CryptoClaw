# CryptoClaw - Design Document

> AI Quantitative Trading System based on OpenClaw + Freqtrade

[中文版](design.md) | [Product Requirements](requirement.md) | [Technical Spec](technical-spec.md)

---

## 1. System Architecture Overview

### 1.1 Overall Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              CryptoClaw System                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                     User Interaction Layer (Channels)                │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────────┐  │   │
│  │  │  Telegram   │  │  WhatsApp   │  │     Desktop Client (Electron)│  │   │
│  │  │  (Chat)     │  │  (Chat)     │  │     (Sensitive Info Mgmt)    │  │   │
│  │  └──────┬──────┘  └──────┬──────┘  └─────────────┬───────────────┘  │   │
│  │         │                │                       │                   │   │
│  └─────────┼────────────────┼───────────────────────┼───────────────────┘   │
│            │                │                       │                       │
│            └────────────────┼───────────────────────┘                       │
│                             │                                               │
│                             ▼                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      OpenClaw Gateway (Daemon)                       │   │
│  │  ┌─────────────────────────────────────────────────────────────────┐│   │
│  │  │                      Agent Runtime (Agent)                       ││   │
│  │  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  ││   │
│  │  │  │   SOUL.md   │  │  AGENTS.md  │  │     USER.md / TOOLS.md  │  ││   │
│  │  │  │  (Persona)  │  │  (Behavior) │  │   (User Config/Tools)   │  ││   │
│  │  │  └─────────────┘  └─────────────┘  └─────────────────────────┘  ││   │
│  │  │                                                                  ││   │
│  │  │  ┌─────────────────────────────────────────────────────────────┐││   │
│  │  │  │                     Skills Layer                            │││   │
│  │  │  │  ┌────────────┐ ┌────────────┐ ┌────────────────────────┐   │││   │
│  │  │  │  │ freqtrade  │ │  billing   │ │     trading-signals    │   │││   │
│  │  │  │  │(Quant)     │ │ (Billing)  │ │   (Trading Signals)    │   │││   │
│  │  │  │  └────────────┘ └────────────┘ └────────────────────────┘   │││   │
│  │  │  └─────────────────────────────────────────────────────────────┘││   │
│  │  │                                                                  ││   │
│  │  │  ┌─────────────────────────────────────────────────────────────┐││   │
│  │  │  │                     Tools Layer                             │││   │
│  │  │  │  exec │ read │ write │ edit │ browser │ canvas │ nodes │   │││   │
│  │  │  └─────────────────────────────────────────────────────────────┘││   │
│  │  └─────────────────────────────────────────────────────────────────┘│   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                             │                                               │
│                             ▼                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                     Local Storage Layer                              │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────────┐  │   │
│  │  │   SQLite    │  │  Encrypted  │  │      Freqtrade Data         │  │   │
│  │  │  (Trades)   │  │  Keys (AES) │  │    (Strategies/Backtest)    │  │   │
│  │  └─────────────┘  └─────────────┘  └─────────────────────────────┘  │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 1.2 OpenClaw Architecture Mapping

OpenClaw's core architecture is **Soul → Agent → Skill → Tool → Script**:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        OpenClaw Five-Layer Architecture                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Layer 1: SOUL                                                              │
│  ├─ SOUL.md - Defines Agent's persona, boundaries, tone                    │
│  ├─ "Who am I? Why do I exist?"                                            │
│  └─ CryptoClaw: "I am your AI quantitative trading assistant"              │
│                                                                             │
│  Layer 2: AGENT                                                             │
│  ├─ AGENTS.md - Runtime behavior rules, memory, rules                      │
│  ├─ Workspace - Single working directory                                   │
│  ├─ Sessions - ~/.openclaw/agents/<agentId>/sessions                       │
│  └─ Startup file injection: SOUL.md, AGENTS.md, USER.md, TOOLS.md, MEMORY.md│
│                                                                             │
│  Layer 3: SKILL                                                             │
│  ├─ Independent functional modules defined via SKILL.md                    │
│  ├─ Load locations:                                                         │
│  │   ├─ Bundled: /usr/lib/node_modules/openclaw/skills/                    │
│  │   ├─ Managed: ~/.openclaw/skills/                                        │
│  │   └─ Workspace: <workspace>/skills/                                      │
│  └─ CryptoClaw Skills:                                                      │
│      ├─ freqtrade - Freqtrade integration                                  │
│      ├─ billing - Billing system                                           │
│      └─ trading-signals - Trading signals                                  │
│                                                                             │
│  Layer 4: TOOL                                                              │
│  ├─ Built-in Tools (always available):                                     │
│  │   ├─ read - Read files                                                  │
│  │   ├─ write - Write files                                                │
│  │   ├─ edit - Edit files                                                  │
│  │   ├─ exec - Execute commands                                            │
│  │   └─ process - Process management                                       │
│  ├─ Extended Tools:                                                         │
│  │   ├─ browser - Browser control                                          │
│  │   ├─ canvas - UI rendering                                              │
│  │   ├─ nodes - Device control                                             │
│  │   └─ cron - Scheduled tasks                                             │
│  └─ Tool Policy: agents.list[].tools.allow / deny                          │
│                                                                             │
│  Layer 5: SCRIPT                                                            │
│  ├─ External commands executed via exec tool                                │
│  ├─ Freqtrade CLI: freqtrade backtesting, trade, etc.                      │
│  ├─ Python Scripts: Strategy generation, data analysis                      │
│  └─ Shell Scripts: System operations                                        │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Core Component Design

### 2.1 OpenClaw Gateway

**Responsibilities:**
- Maintain message channel connections (Telegram/WhatsApp)
- Expose WebSocket API for client connections
- Route messages to correct Agent
- Manage sessions and state

**Configuration Example:**

```json5
{
  // Agent definition
  agents: {
    list: [
      {
        id: "cryptoclaw",
        name: "CryptoClaw",
        workspace: "~/.cryptoclaw/workspace",
        model: "anthropic/claude-sonnet-4-5",
        default: true,
      },
    ],
  },

  // Message channel bindings
  bindings: [
    { agentId: "cryptoclaw", match: { channel: "telegram" } },
    { agentId: "cryptoclaw", match: { channel: "whatsapp" } },
  ],

  // Channel configuration
  channels: {
    telegram: {
      accounts: {
        default: {
          botToken: "TELEGRAM_BOT_TOKEN",
          dmPolicy: "pairing",
        },
      },
    },
    whatsapp: {
      accounts: {
        default: {
          dmPolicy: "allowlist",
          allowFrom: ["+15551234567"],
        },
      },
    },
  },
}
```

### 2.2 Agent Workspace

**Directory Structure (Based on Freqtrade user_data standard):**

```
~/.cryptoclaw/                    # CryptoClaw root directory
├── user_data/                    # Freqtrade standard user_data directory
│   ├── config.json               # Freqtrade main config file
│   ├── config-private.json       # Exchange API keys (encrypted, not uploaded)
│   │
│   ├── strategies/               # Freqtrade strategies directory
│   │   ├── __init__.py
│   │   ├── sample_strategy.py    # Sample strategy
│   │   └── user_strategies/      # User custom strategies
│   │       ├── rsi_strategy.py
│   │       └── macd_strategy.py
│   │
│   ├── data/                     # Freqtrade historical data directory
│   │   ├── binance/              # By exchange
│   │   │   ├── BTC_USDT-1h.feather
│   │   │   └── ETH_USDT-1h.feather
│   │   └── okx/
│   │       └── ...
│   │
│   ├── notebooks/                # Jupyter notebooks (optional)
│   │   └── strategy_analysis.ipynb
│   │
│   ├── plot/                     # Backtest plot output directory
│   │   └── profit_chart.html
│   │
│   ├── hyperopts/                # Hyperopt results directory
│   │   └── rsi_strategy_20260317.json
│   │
│   └── freqaimodels/             # FreqAI models directory (optional)
│       └── ...
│
├── tradesv3.sqlite               # Freqtrade trades database (live)
├── tradesv3.dryrun.sqlite        # Freqtrade trades database (paper)
│
├── cryptoclaw.db                 # CryptoClaw local database
│                                 # - User info, watermarks, bills, etc.
│
├── workspace/                    # OpenClaw Agent workspace
│   ├── AGENTS.md                 # Runtime behavior rules
│   ├── SOUL.md                   # Persona definition
│   ├── USER.md                   # User configuration
│   ├── TOOLS.md                  # Tool documentation
│   ├── MEMORY.md                 # Long-term memory
│   ├── memory/                   # Daily memory
│   │   └── 2026-03-17.md
│   └── skills/                   # OpenClaw custom skills
│       ├── freqtrade/
│       │   └── SKILL.md
│       ├── billing/
│       │   └── SKILL.md
│       └── trading-signals/
│           └── SKILL.md
│
└── logs/                         # Logs directory
    ├── freqtrade.log             # Freqtrade logs
    └── cryptoclaw.log            # CryptoClaw logs
```

**Directory Explanation:**

| Directory/File | Description |
|----------|------|
| `user_data/` | Freqtrade standard user data directory, compatible with Freqtrade CLI |
| `user_data/config.json` | Freqtrade main config, includes strategy params, pairs, etc. |
| `user_data/config-private.json` | Exchange API keys, add to .gitignore |
| `user_data/strategies/` | Strategy files directory, AI-generated strategies stored here |
| `user_data/data/` | Historical data directory, organized by exchange and timeframe |
| `tradesv3.sqlite` | Freqtrade live trading database |
| `tradesv3.dryrun.sqlite` | Freqtrade paper trading database |
| `cryptoclaw.db` | CryptoClaw business database (watermarks, bills, payments) |
| `workspace/` | OpenClaw Agent runtime directory |

### 2.3 Skills Design

#### 2.3.1 freqtrade Skill

**Responsibilities:**
- Interact with Freqtrade CLI
- Generate strategy code
- Execute backtesting
- Start/stop trading

**SKILL.md Structure:**

```markdown
---
name: freqtrade
description: "Freqtrade quantitative trading integration. Use for: strategy generation, backtesting, paper trading, live trading."
metadata:
  openclaw:
    emoji: "📊"
    requires:
      bins: ["freqtrade"]
---

# Freqtrade Skill

## Features

### Strategy Generation
- Convert natural language descriptions to Freqtrade strategy code
- Support common indicators: RSI, MACD, Bollinger, EMA, etc.

### Backtesting
- Execute historical data backtesting
- Return metrics like profit curve, max drawdown, etc.

### Trading
- Paper Trading (Dry-Run)
- Live Trading

## Commands

\`\`\`bash
# Download historical data
freqtrade download-data --pairs BTC/USDT --timeframe 1h

# Execute backtesting
freqtrade backtesting --strategy RSI --timerange 20240101-20241231

# Start paper trading
freqtrade trade --strategy RSI --dry-run

# Start live trading
freqtrade trade --strategy RSI
\`\`\`
```

#### 2.3.2 billing Skill

**Responsibilities:**
- Calculate high-water mark
- Generate monthly bills
- Upload bill confirmations
- Generate payment QR codes

#### 2.3.3 trading-signals Skill

**Responsibilities:**
- Download daily trading signals (from Supabase)
- Push signal notifications to users

---

## 3. Data Flow Design

### 3.1 User Conversation Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         User Conversation Flow                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  User: "Help me write an RSI strategy, buy when RSI < 30, sell when RSI > 70"│
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ 1. Telegram/WhatsApp receives message                                │   │
│  └────────────────────────────┬────────────────────────────────────────┘   │
│                               │                                             │
│                               ▼                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ 2. OpenClaw Gateway routes to cryptoclaw Agent                      │   │
│  └────────────────────────────┬────────────────────────────────────────┘   │
│                               │                                             │
│                               ▼                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ 3. Agent Runtime processes                                           │   │
│  │    ├─ Read SOUL.md/AGENTS.md/USER.md                                 │   │
│  │    ├─ Understand user intent: Generate RSI strategy                  │   │
│  │    └─ Decide to call freqtrade skill                                 │   │
│  └────────────────────────────┬────────────────────────────────────────┘   │
│                               │                                             │
│                               ▼                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ 4. freqtrade Skill executes                                          │   │
│  │    ├─ Generate strategy code (Python)                                │   │
│  │    ├─ Save to workspace/strategies/user_strategies/rsi_strategy.py   │   │
│  │    └─ Return strategy info to Agent                                  │   │
│  └────────────────────────────┬────────────────────────────────────────┘   │
│                               │                                             │
│                               ▼                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ 5. Agent generates response                                          │   │
│  │    "RSI strategy generated! File: rsi_strategy.py                    │   │
│  │     Buy condition: RSI < 30                                          │   │
│  │     Sell condition: RSI > 70                                         │   │
│  │     Want to run a backtest first?"                                   │   │
│  └────────────────────────────┬────────────────────────────────────────┘   │
│                               │                                             │
│                               ▼                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ 6. Telegram/WhatsApp sends response to user                          │   │
│  └────────────────────────────┬────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Backtesting Flow

```
User: "Backtest with BTC data from the last year"

1. Agent calls freqtrade skill
2. Skill executes:
   a. freqtrade download-data --pairs BTC/USDT --timeframe 1h --days 365
   b. freqtrade backtesting --strategy RSI --timerange 20240101-20241231
3. Parse backtesting results
4. Agent generates natural language explanation:
   "Backtesting complete!
    📊 Total Return: +45.2%
    📉 Max Drawdown: -12.3%
    📈 Win Rate: 62%
    💰 Trade Count: 156
    
    Want to start paper trading?"
```

### 3.3 Live Trading Flow

```
User: "Start live trading"

1. Check if billing rules accepted
   - If not, display rules, request user confirmation
   - After confirmation, upload to server for archival

2. Check if exchange API configured
   - If not, guide user to configure in desktop client

3. Start live trading
   - freqtrade trade --strategy RSI

4. Continuously push trade notifications to user
   - "Buy BTC/USDT @ $45,000"
   - "Sell BTC/USDT @ $46,500 (+3.3%)"
```

---

## 4. Security Design

### 4.1 Sensitive Information Management

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                  Sensitive Information Management Architecture               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                   Desktop Client (Electron)                          │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │                  Local Encrypted Storage                      │   │   │
│  │  │  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐ │   │   │
│  │  │  │  LLM API Key   │  │ Exchange API   │  │  Supabase Key  │ │   │   │
│  │  │  │  (AES-256)     │  │  Key (AES-256) │  │  (AES-256)     │ │   │   │
│  │  │  └────────────────┘  └────────────────┘  └────────────────┘ │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  Principles:                                                                │
│  ✅ All sensitive information stored locally in desktop client             │
│  ✅ Encrypted with AES-256-GCM                                              │
│  ✅ Keys derived from user master password (PBKDF2)                        │
│  ❌ Sensitive information never uploaded to cloud                           │
│  ❌ Web/Mobile clients store no sensitive information                      │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 4.2 Key Hierarchy

```
Level 0: Master Key
├─ Derived from user password (PBKDF2, 100,000 iterations)
├─ Not stored, re-derived from password each time
└─ Used to encrypt Level 1 keys

Level 1: Data Encryption Key (DEK)
├─ Unique per user
├─ Stored encrypted by Master Key
└─ Used to encrypt actual data

Level 1.5: Supabase Key (Service Key)
├─ Issued by server upon user registration
├─ Used for:
│   ├─ Downloading daily trading signals
│   ├─ Uploading billing rule acceptance records
│   └─ Uploading bill confirmation data
├─ Stored locally on client (encrypted)
├─ Server disables this key when overdue
└─ Server enables this key after payment

Level 2: Communication Keys
├─ HMAC Key: Request signing
├─ Session Key: JWT signing
└─ Periodically rotated
```

---

## 5. Deployment Architecture

### 5.1 Single-Machine Deployment (Recommended)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      Single-Machine Deployment Architecture                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      User Machine (Linux/macOS)                      │   │
│  │                                                                      │   │
│  │  ┌───────────────────────────────────────────────────────────────┐  │   │
│  │  │                    OpenClaw Gateway (Daemon)                   │  │   │
│  │  │                                                                │  │   │
│  │  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐   │  │   │
│  │  │  │  Telegram   │  │  WhatsApp   │  │  Agent Runtime      │   │  │   │
│  │  │  │  Bot API    │  │  (Baileys)  │  │  (OpenClaw + LLM)   │   │  │   │
│  │  │  └─────────────┘  └─────────────┘  └─────────────────────┘   │  │   │
│  │  │                                                                │  │   │
│  │  │  ┌─────────────────────────────────────────────────────────┐  │  │   │
│  │  │  │                   Freqtrade Engine                       │  │  │   │
│  │  │  │  - Strategy execution                                    │  │  │   │
│  │  │  │  - Data download                                         │  │  │   │
│  │  │  │  - Backtesting calculation                               │  │  │   │
│  │  │  │  - Trade execution                                       │  │  │   │
│  │  │  └─────────────────────────────────────────────────────────┘  │  │   │
│  │  └───────────────────────────────────────────────────────────────┘  │   │
│  │                                                                      │   │
│  │  ┌───────────────────────────────────────────────────────────────┐  │   │
│  │  │                     Desktop Client (Electron)                  │  │   │
│  │  │  - API Key management                                         │  │   │
│  │  │  - Local settings                                             │  │   │
│  │  │  - Software updates                                           │  │   │
│  │  └───────────────────────────────────────────────────────────────┘  │   │
│  │                                                                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  Cloud (Minimal):                                                           │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  Supabase                                                           │   │
│  │  - User registration                                                │   │
│  │  - Supabase Key management                                          │   │
│  │  - Trading signal storage                                           │   │
│  │  - Bill confirmation records                                        │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 5.2 Technology Stack Summary

| Layer | Technology | Description |
|-------|-----------|-------------|
| **Message Channels** | Telegram Bot API / WhatsApp (Baileys) | Conversational interaction |
| **AI Agent** | OpenClaw | Multi-model support, skill system |
| **Quant Engine** | Freqtrade | Strategy execution, backtesting, trading |
| **Desktop Client** | Electron | Cross-platform, sensitive info management |
| **Local Storage** | SQLite + AES-256 | Encrypted data storage |
| **Cloud Service** | Supabase | User registration, key management |
| **LLM** | OpenAI / Claude / Local Models | Natural language understanding |

---

## 6. Installation & Deployment Design

### 6.1 Installation Methods Comparison

| Method | Target Users | Pros | Cons | Recommendation |
|--------|--------------|------|------|----------------|
| **Docker Image** | Regular users | One-click install, isolated environment, easy updates | Requires Docker | ⭐⭐⭐⭐⭐ |
| **Installer Package** | Regular users | Native experience, no Docker needed | Complex build, platform adaptation | ⭐⭐⭐⭐ |
| **Source Code** | Developers | Flexible, customizable | Requires technical skills | ⭐⭐⭐ |

**Recommended: Docker image as primary, source code as secondary**

### 6.2 Docker Image Solution (Recommended)

#### 6.2.1 Image Structure

See [Technical Spec - Dockerfile](technical-spec_en.md#81-dockerfile)

#### 6.2.2 One-Click Install Script

See [Technical Spec - Install Scripts](technical-spec_en.md#82-one-click-install-script-macoslinux)

#### 6.2.3 Directory Mounts

See [Technical Spec - Docker Compose Configuration](technical-spec_en.md#84-docker-compose-configuration)

#### 6.2.4 Channel Configuration (Important)

**Problem:** OpenClaw requires user's own Telegram Bot, WhatsApp, and other channel configurations. These are user's bots, not server's.

**Solution Comparison:**

| Solution | Pros | Cons | Recommendation |
|----------|------|------|----------------|
| **Environment Variables** | Simple, secure, no container access | Long command line | ⭐⭐⭐⭐ |
| **Config File Mount** | Structured, easy management, multi-channel | Requires file editing | ⭐⭐⭐⭐⭐ |
| **Interactive Config in Container** | Guided, user-friendly | Requires container access, config stuck in container | ⭐⭐⭐ |
| **Desktop Client Config** | GUI friendly, writes to config file | Extra development needed | ⭐⭐⭐⭐ |

**Recommended: Config File Mount + Initialization Wizard**

See:
- [Technical Spec - OpenClaw Configuration File](technical-spec_en.md#85-openclaw-configuration-file)
- [Technical Spec - Environment Variables File](technical-spec_en.md#86-environment-variables-file)
- [Technical Spec - Configuration Wizard Script](technical-spec_en.md#87-configuration-wizard-script)

#### 6.2.5 Desktop Client & Configuration (Important)

**Problem:** Terminal config wizard is not user-friendly. Need to clarify desktop client's role.

**Solution: Desktop Client as Primary Configuration Interface**

```
┌─────────────────────────────────────────────────────────────┐
│              Configuration Architecture                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │           Desktop Client (Electron)                  │   │
│  │                                                      │   │
│  │  ┌─────────────────────────────────────────────┐    │   │
│  │  │         First-Run Wizard                     │    │   │
│  │  │  Step 1: Check Docker                        │    │   │
│  │  │  Step 2: Download/Start Container            │    │   │
│  │  │  Step 3: User Registration/Login             │    │   │
│  │  │  Step 4: Configure Telegram Bot              │    │   │
│  │  │  Step 5: Configure LLM API                   │    │   │
│  │  │  Step 6: Complete                            │    │   │
│  │  └─────────────────────────────────────────────┘    │   │
│  │                                                      │   │
│  │  ┌─────────────────────────────────────────────┐    │   │
│  │  │         Settings Panel (Edit Anytime)        │    │   │
│  │  │  - Channel Management (Telegram/WhatsApp)   │    │   │
│  │  │  - LLM Configuration                        │    │   │
│  │  │  - Exchange API Key Management              │    │   │
│  │  │  - Container Status Monitoring              │    │   │
│  │  └─────────────────────────────────────────────┘    │   │
│  │                                                      │   │
│  │           ↓ Writes Config Files                     │   │
│  └─────────────────────────────────────────────────────┘   │
│                          ↓                                  │
│  ┌─────────────────────────────────────────────────────┐   │
│  │         Local Config Files                          │   │
│  │  ~/.cryptoclaw/config/                              │   │
│  │  ├── .env              (Sensitive Info)             │   │
│  │  ├── openclaw.yaml     (Channel Config)             │   │
│  │  └── docker-compose.yml (Container Config)          │   │
│  └─────────────────────────────────────────────────────┘   │
│                          ↓                                  │
│  ┌─────────────────────────────────────────────────────┐   │
│  │         Docker Container                            │   │
│  │  Mounts config files → Reads config on startup      │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**1. Desktop Client Installation:**

| Platform | Package | Description |
|----------|---------|-------------|
| **macOS** | CryptoClaw.dmg / .app | Drag to Applications |
| **Windows** | CryptoClaw-Setup.exe | Install wizard |
| **Linux** | CryptoClaw.AppImage / .deb / .rpm | Portable / Package manager |

**2. Desktop Client First-Run Wizard:**

```
┌─────────────────────────────────────────────────────────────┐
│              Desktop Client First-Run Wizard                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Step 1: Welcome                                            │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  🎉 Welcome to CryptoClaw!                           │   │
│  │                                                      │   │
│  │  CryptoClaw is an AI-powered quantitative trading   │   │
│  │  assistant                                           │   │
│  │                                                      │   │
│  │  This wizard will guide you through setup           │   │
│  │                                                      │   │
│  │                              [Start Setup]           │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  Step 2: Check Docker                                       │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  🔍 Checking Environment                             │   │
│  │                                                      │   │
│  │  Docker Desktop: ✅ Installed                        │   │
│  │  Docker Version: 24.0.7                              │   │
│  │  Docker Status: ✅ Running                           │   │
│  │                                                      │   │
│  │  [Show download button if not installed]            │   │
│  │  [Download Docker Desktop]                           │   │
│  │                                                      │   │
│  │                                      [Next]          │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  Step 3: Download/Start Container                           │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  📦 Downloading CryptoClaw Service                   │   │
│  │                                                      │   │
│  │  Downloading cryptoclaw/cryptoclaw:latest...        │   │
│  │  [████████████████░░░░░░░░] 65%                     │   │
│  │                                                      │   │
│  │  Service will start automatically when complete     │   │
│  │                                                      │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  Step 4: User Registration/Login                            │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  👤 User Registration/Login                          │   │
│  │                                                      │   │
│  │  ○ New User Registration                             │   │
│  │    Email: [________________________]                 │   │
│  │    Password: [________________________]              │   │
│  │                                                      │   │
│  │  ○ Existing User Login                               │   │
│  │    Email: [________________________]                 │   │
│  │    Password: [________________________]              │   │
│  │                                                      │   │
│  │  💡 For syncing config and trading data             │   │
│  │                                                      │   │
│  │  [Register] [Login] [Skip, register later]          │   │
│  │                                                      │   │
│  │                                      [Next]          │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  Step 5: Configure Telegram Bot                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  📱 Configure Telegram Bot                           │   │
│  │                                                      │   │
│  │  How to get Bot Token:                               │   │
│  │  1. Search @BotFather in Telegram                    │   │
│  │  2. Send /newbot to create a new bot                 │   │
│  │  3. Copy the token you receive                       │   │
│  │                                                      │   │
│  │  Bot Token: [________________________]               │   │
│  │                                                      │   │
│  │  [Verify Token]  [Skip, configure later]             │   │
│  │                                                      │   │
│  │                                      [Next]          │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  Step 6: Configure LLM API                                  │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  🤖 Configure AI Model                               │   │
│  │                                                      │   │
│  │  Select LLM Provider:                                │   │
│  │  ○ OpenAI (recommended)                              │   │
│  │  ○ Anthropic Claude                                  │   │
│  │  ○ Local Model (advanced)                            │   │
│  │                                                      │   │
│  │  API Key: [________________________]                 │   │
│  │                                                      │   │
│  │  [Verify API Key]  [Skip, configure later]           │   │
│  │                                                      │   │
│  │                                      [Next]          │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  Step 7: Setup Complete                                     │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  ✅ Setup Complete!                                  │   │
│  │                                                      │   │
│  │  CryptoClaw service is now running                   │   │
│  │                                                      │   │
│  │  📱 Search for your bot in Telegram to start        │   │
│  │  💡 You can modify settings anytime in Settings     │   │
│  │                                                      │   │
│  │  [Open Telegram Bot]  [Go to Settings]  [Done]      │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**3. Desktop Client Settings Panel:**

- Service status monitoring (Docker container status, version, uptime)
- Channel management (Telegram/WhatsApp/Feishu)
- AI model configuration (OpenAI/Claude/Local)
- Exchange API Key management (Binance/OKX, etc.)
- **Account management (Login/Logout)** - Independent feature for switching accounts
- Advanced settings (log viewing, data backup)

**4. Desktop Client Technical Implementation:**

See [Technical Spec - Desktop Client Configuration Manager](technical-spec_en.md#88-desktop-client-configuration-manager)

**5. Configuration Summary:**

| Config Item | Method | Location | Notes |
|-------------|--------|----------|-------|
| **Telegram Bot Token** | Desktop wizard/Settings | ~/.cryptoclaw/config/.env | Encrypted |
| **LLM API Key** | Desktop wizard/Settings | ~/.cryptoclaw/config/.env | Encrypted |
| **Exchange API Keys** | Desktop Settings (separate) | ~/.cryptoclaw/cryptoclaw.db | AES-256 encrypted |
| **Channel Toggles** | Desktop Settings | ~/.cryptoclaw/config/openclaw.yaml | Plain text |
| **Freqtrade Config** | Desktop Settings | ~/.cryptoclaw/user_data/config.json | Freqtrade standard |

**6. Terminal Script vs Desktop Client:**

- **Regular Users (Recommended)**: Download desktop client installer, launch, follow wizard to complete setup, manage all config via GUI
- **Advanced Users / Developers**: Use terminal one-click install script, use terminal config wizard (or edit files manually), manage container via docker-compose
- **Headless Server Users**: SSH into server, run terminal install script, manually edit config files, interact via Telegram

### 6.3 Software Update Mechanism

#### 6.3.1 Update Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Auto-Update Flow                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Check on Startup                                        │
│     Container checks for latest version on startup          │
│     curl api.cryptoclaw.pro/updates/check?v=1.0.0           │
│                                                             │
│  2. Version Comparison                                      │
│     { latest: "1.2.0", force: false, notes: "..." }         │
│                                                             │
│  3. User Confirmation                                       │
│     Send update notification via Telegram                   │
│     "New version v1.2.0 available, update now?"             │
│                                                             │
│  4. Execute Update                                          │
│     docker pull cryptoclaw/cryptoclaw:latest                │
│     docker restart cryptoclaw                               │
│                                                             │
│  5. Data Preservation                                       │
│     Data automatically preserved due to volume mounts       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### 6.3.2 Update Script

See [Technical Spec - Update Script](technical-spec_en.md#89-update-script)

#### 6.3.3 Version Rollback

See [Technical Spec - Version Rollback Script](technical-spec_en.md#810-version-rollback-script)

### 6.4 Source Code Solution

#### 6.4.1 Requirements

| Component | Version | Description |
|-----------|---------|-------------|
| Python | 3.11+ | Freqtrade dependency |
| Node.js | 20+ | OpenClaw dependency |
| Docker | 24+ | Optional, for containerization |
| Git | 2.x | Version control |

#### 6.4.2 Quick Start

See [Technical Spec - Source Code Solution](technical-spec_en.md#811-source-code-solution)

### 6.5 Package Distribution

#### 6.5.1 Image Registry

```
Docker Hub: cryptoclaw/cryptoclaw
├── latest          # Latest stable
├── v1.0.0          # Specific version
├── v1.1.0
├── develop         # Development build
└── nightly         # Daily build
```

#### 6.5.2 GitHub Release

```
https://github.com/franklili3/CryptoClaw/releases
├── Source code (zip)
├── Source code (tar.gz)
├── install.sh      # Linux/macOS installer
├── install.ps1     # Windows installer
└── CHANGELOG.md    # Change log
```

### 6.6 User Onboarding Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    New User Onboarding                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Visit Website                                           │
│     cryptoclaw.pro                                          │
│                                                             │
│  2. Choose Installation Method                              │
│     ├─ Docker one-click install (recommended)              │
│     ├─ Source code install                                  │
│     └─ View documentation                                   │
│                                                             │
│  3. Execute Installation                                    │
│     curl -fsSL cryptoclaw.pro/install.sh | bash            │
│                                                             │
│  4. Start Service                                           │
│     ~/.cryptoclaw/start.sh                                  │
│                                                             │
│  5. Telegram Binding                                        │
│     Search @CryptoClawBot                                   │
│     Send /start to bind account                             │
│                                                             │
│  6. Configure API Keys (via desktop client)                │
│     - Exchange API Key                                      │
│     - LLM API Key                                           │
│                                                             │
│  7. Start Using                                             │
│     "Help me create an RSI strategy"                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 6.7 Installation Verification

See [Technical Spec - Installation Verification Commands](technical-spec_en.md#812-installation-verification-commands)

---

## 7. Development Plan

### Phase 1: MVP (Week 1-4)

- [ ] Set up OpenClaw Gateway + Agent
- [ ] Implement freqtrade skill (strategy generation, backtesting)
- [ ] Telegram Bot integration
- [ ] Basic conversation functionality

### Phase 2: Trading (Week 5-7)

- [ ] Freqtrade trading integration
- [ ] Paper trading
- [ ] Live trading
- [ ] Trade notifications

### Phase 3: Payment (Week 8-9)

- [ ] Billing rule acceptance flow
- [ ] Monthly billing
- [ ] Payment QR code generation
- [ ] On-chain payment confirmation

### Phase 4: Polish (Week 10+)

- [ ] Performance optimization
- [ ] More strategies
- [ ] User feedback iteration

---

## 8. Reference Resources

- [OpenClaw Documentation](https://docs.openclaw.ai)
- [Freqtrade Documentation](https://www.freqtrade.io)
- [Product Requirements Document](requirement_en.md)
- [Technical Specification Document](technical-spec_en.md)

---

**Document Version:** v1.1  
**Last Updated:** 2026-03-18  
**Author:** CryptoClaw Team
