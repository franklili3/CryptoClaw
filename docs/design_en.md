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

**Directory Structure:**

```
~/.cryptoclaw/
├── workspace/                    # Agent workspace
│   ├── AGENTS.md                 # Runtime behavior rules
│   ├── SOUL.md                   # Persona definition
│   ├── USER.md                   # User configuration
│   ├── TOOLS.md                  # Tool documentation
│   ├── MEMORY.md                 # Long-term memory
│   ├── memory/                   # Daily memory
│   │   └── 2026-03-17.md
│   ├── skills/                   # Custom skills
│   │   ├── freqtrade/
│   │   │   └── SKILL.md
│   │   ├── billing/
│   │   │   └── SKILL.md
│   │   └── trading-signals/
│   │       └── SKILL.md
│   └── strategies/               # Freqtrade strategies
│       └── user_strategies/
│           └── rsi_strategy.py
├── data/                         # Local data
│   ├── freqtrade.db              # Trading database
│   ├── keys.db                   # Encrypted key storage
│   └── trades/                   # Trade records
└── config/                       # Configuration files
    ├── freqtrade.json            # Freqtrade config
    └── keys.json                 # API Key config (encrypted)
```

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

## 6. Development Plan

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

## 7. Reference Resources

- [OpenClaw Documentation](https://docs.openclaw.ai)
- [Freqtrade Documentation](https://www.freqtrade.io)
- [Product Requirements Document](requirement.md)
- [Technical Specification Document](technical-spec.md)

---

**Document Version:** v1.0  
**Last Updated:** 2026-03-17  
**Author:** CryptoClaw Team
