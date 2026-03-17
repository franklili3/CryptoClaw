# CryptoClaw - Product Requirements Document (PRD)

> One-click install, locally-running AI-powered crypto quantitative trading software

[中文版](requirement.md) | [Technical Spec](technical-spec.md)

> 📋 **Note**: This is the product requirements document. For technical implementation details (code, data structures, APIs), please refer to the [Technical Specification](technical-spec.md)

---

## 1. Product Positioning

### 1.1 Core Value

**CryptoClaw** — Your AI quantitative trading team, right in your chat

| Dimension | Description |
|------|------|
| **Product Form** | Conversational AI Agent (Telegram/WhatsApp) + Lightweight Client (Sensitive Info Management) |
| **Target Users** | Cryptocurrency investors, quantitative trading enthusiasts |
| **Core Value** | AI-driven strategy backtesting + automated trading, all through conversation |
| **Business Model** | Free to use, 10% profit sharing (pay by results) |

### 1.2 Core Philosophy

> **"Chat is the interface, control trading anytime, anywhere"**

**Interaction Modes:**

| Channel | Purpose | Description |
|----------|------|------|
| **Telegram/WhatsApp** | Core feature interaction | Strategy writing, backtesting, trading, billing, payments all through conversation |
| **Desktop Client** | Sensitive info management | Only for API Key configuration, exchange keys, etc. |
| **Web Client** | Sensitive info management (alternative) | Manage sensitive info in browser, no installation needed |

**Features via Chat:**
- ✅ Strategy Writing: Describe strategy in natural language, AI generates code
- ✅ Data Download: Chat command to download historical data
- ✅ Strategy Backtesting: Chat to start backtest, AI explains results
- ✅ Paper Trading: Chat to enable/disable paper trading
- ✅ Live Trading: Chat to confirm and start live trading
- ✅ Billing Reconciliation: Chat to view trade details and bills
- ✅ Fee Calculation: Chat to view monthly fees
- ✅ Fee Confirmation: Chat to confirm bill amount
- ✅ QR Code Payment: Generate payment QR code in chat
- ✅ Risk Notifications: Real-time trading and risk control notifications

**Client Only Manages:**
- 🔐 LLM API Keys (OpenAI/Claude/Local models)
- 🔐 Exchange API Keys (Binance/OKX)
- 🔐 Local encrypted data storage

---

## 2. Business Model

### 2.1 Target Market Analysis

#### User Personas

| User Type | Characteristics | Estimated % | Payment Willingness |
|----------|------|----------|----------|
| **Quant Newbies** | Crypto investment experience, want to try quant but can't code | 40% | High |
| **Tech Enthusiasts** | Some programming background, want to learn quant trading | 30% | Medium |
| **Professional Traders** | Quant experience, looking for better tools | 20% | High |
| **Passive Investors** | Want automated investing, no time to watch charts | 10% | Medium |

#### Market Size Estimation

| Metric | Value | Source |
|------|------|------|
| Global crypto users | ~420M | TripleA 2024 Report |
| Users using quant tools | ~5% | Industry estimate |
| Potential target users | ~21M | Calculated |
| Users willing to pay >$100/year | ~10% | Industry research |

### 2.2 Profit Sharing Model

#### High Watermark Mechanism

```
High Watermark Principle:
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  Profit Curve                                               │
│     ╭─────╮        ╭──────────────╮ ← Current High Watermark│
│    ╱       ╲      ╱                ╲                        │
│   ╱         ╲____╱                  ╲                       │
│  ╱                                    ╲ ← Current Profit    │
│ ╱                                      ╲                    │
│─────────────────────────────────────────────────────────────│
│                                                             │
│  Billing Base = max(0, Cumulative Profit - Historical High) │
│  Fee Payable = Billing Base × 10%                           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### Example Scenarios

| Month | Monthly P&L | Cumulative Profit | High Watermark | Billing Base | Fee Payable |
|------|----------|----------|------------|----------|----------|
| Jan | +$500 | $500 | $0 | $500 | $50 |
| Feb | -$200 | $300 | $500 | $0 | $0 |
| Mar | +$100 | $400 | $500 | $0 | $0 |
| Apr | +$300 | $700 | $500 | $200 | $20 |
| May | -$100 | $600 | $700 | $0 | $0 |
| Jun | +$400 | $1000 | $700 | $300 | $30 |

**Core Principles:**
- Only charge for **new** profits
- No charge during recovery from losses
- Never charge users for "filling losses"

### 2.3 Fee Agreement Flow

Before first live trading, users must agree to fee rules:

```
┌─────────────────────────────────────────────────────────────┐
│                   Fee Agreement Flow                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Trigger Conditions                                     │
│     - User first attempts to start live trading            │
│     - Or user first configures exchange API                │
│                                                             │
│  2. Display Fee Rules                                      │
│     ├─ Profit Share: 10% of profits                        │
│     ├─ High Watermark: Only bill new profits               │
│     ├─ Billing Cycle: Monthly                              │
│     ├─ Payment Methods: USDT/USDC (TRC-20/ERC-20)         │
│     ├─ Payment Deadline: Within 7 days of bill generation  │
│     └─ Overdue Handling: Suspend live trading              │
│                                                             │
│  3. User Agreement                                         │
│     ├─ User reads complete rules                           │
│     ├─ Check "I have read and agree to fee rules"          │
│     └─ Click "Confirm Agreement" button                    │
│                                                             │
│  4. Upload to Server                                       │
│     ├─ Client generates agreement record                   │
│     ├─ Upload to server for archival                       │
│     └─ Server returns confirmation                         │
│                                                             │
│  5. Unlock Features                                        │
│     └─ Live trading unlocked, user can start trading       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 2.4 Monthly Billing Flow

```
┌─────────────────────────────────────────────────────────────┐
│                   Monthly Billing Flow                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Scheduled Trigger (1st of each month 00:00)            │
│     ├─ Client executes locally                             │
│     └─ Calculate last month's trading data                  │
│                                                             │
│  2. Local Calculation                                      │
│     ├─ Summarize all trades from last month                │
│     ├─ Calculate cumulative profit                         │
│     ├─ Get historical high watermark                       │
│     ├─ Calculate billable profit = max(0, profit - mark)   │
│     ├─ Calculate fee payable = billable profit × 10%       │
│     └─ Update high watermark                               │
│                                                             │
│  3. Generate Bill (Local)                                  │
│                                                             │
│  4. User Confirmation                                      │
│     ├─ Client displays bill details                        │
│     ├─ User views trade details                            │
│     └─ Click "Confirm Bill"                                │
│                                                             │
│  5. Upload to Server                                       │
│     ├─ Client uploads confirmed bill                       │
│     ├─ Server verifies signature                           │
│     ├─ Server generates payment order                      │
│     └─ Return payment address and order number             │
│                                                             │
│  6. Wait for Payment                                       │
│     └─ User completes payment within 7 days                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 2.5 Payment & Verification Flow

```
┌─────────────────────────────────────────────────────────────┐
│                   Payment & Verification Flow               │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. User Payment                                           │
│     ├─ User gets payment address (server assigned)         │
│     ├─ User transfers USDT/USDC from wallet                │
│     └─ User submits transaction hash in client             │
│                                                             │
│  2. Server Monitors On-Chain Address                       │
│     ├─ Method 1: Poll blockchain API                       │
│     │   - TronGrid API (TRC-20)                            │
│     │   - Etherscan API (ERC-20)                           │
│     │   - Check every 5 minutes                            │
│     │                                                       │
│     ├─ Method 2: Webhook listening (recommended)           │
│     │   - Use blockchain monitoring service                │
│     │   - Real-time incoming payment notifications         │
│     │                                                       │
│     └─ Method 3: Self-hosted light node                    │
│         - Higher privacy and reliability                   │
│         - Suitable at scale                                │
│                                                             │
│  3. Payment Verification                                   │
│     ├─ New incoming transaction detected                   │
│     ├─ Verification items:                                 │
│     │   ├─ Receiving address matches                       │
│     │   ├─ Amount >= payable amount                        │
│     │   ├─ Correct currency                                │
│     │   └─ Sufficient confirmations                        │
│     ├─ Match success: Update bill status                   │
│     └─ Match failure: Mark for manual review               │
│                                                             │
│  4. Status Update                                          │
│     ├─ Server updates bill status to "Paid"                │
│     ├─ Record transaction hash                             │
│     ├─ Record confirmation time                            │
│     ├─ Notify client to sync status                        │
│     └─ Reset monthly high watermark                        │
│                                                             │
│  5. Exception Handling                                     │
│     ├─ Insufficient amount: Notify user to pay difference  │
│     ├─ Overpayment: Record balance for next month credit   │
│     ├─ No payment in 7 days: Suspend live trading          │
│     └─ Payment received: Restore functionality             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 2.6 Payment Methods

| Payment Method | Chain | Notes |
|----------|-----|------|
| USDT | TRC-20 / ERC-20 | Main stablecoin |
| USDC | TRC-20 / ERC-20 | Main stablecoin |

### 2.7 Revenue Projection

#### Conservative Scenario

| Metric | Value |
|------|------|
| First year target users | 500 |
| Monthly retention rate | 85% |
| Average monthly profit per user | $150 |
| Payment conversion rate | 40% |
| First month revenue | $150 × 500 × 40% × 50% × 10% = $1,500 |
| First year revenue | ~$18,000 |

#### Optimistic Scenario (12 months)

| Metric | Value |
|------|------|
| Active users | 2,000 |
| Average monthly profit per user | $200 |
| Payment conversion rate | 50% |
| Billable user ratio | 60% |
| Monthly revenue | $200 × 2000 × 50% × 60% × 10% = **$12,000** |
| Annual revenue | **$144,000** |

---

## 3. User Journey

### 3.1 New User First-Time Flow (Chat-Based)

```
┌─────────────────────────────────────────────────────────────┐
│        New User Complete Journey (Chat-Based Version)       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Step 1: Discovery & Join                                  │
│  ├→ Learn about product via social media/friends           │
│  ├→ Search official bot on Telegram/WhatsApp               │
│  └→ Send /start to begin                                   │
│                                                             │
│  Step 2: Authentication                                    │
│  ├→ Bot guides to Web client (or download desktop client)  │
│  ├→ Complete email registration and verification in client │
│  └→ Return to chat to continue                             │
│                                                             │
│  Step 3: Configure Sensitive Info (in Client)              │
│  ├→ Open Client → Settings → API Management                │
│  ├→ Configure LLM API Key (OpenAI/Claude/Local)            │
│  ├→ Optional: Configure Exchange API (for live trading)    │
│  └→ All keys stored locally encrypted, never uploaded      │
│                                                             │
│  Step 4: Chat Experience (in Telegram/WhatsApp)            │
│  ├→ "Help me write an RSI strategy"                        │
│  ├→ "Download BTC data for the past year"                  │
│  ├→ "Backtest with this strategy"                          │
│  └→ AI explains backtest results in conversation           │
│                                                             │
│  Step 5: Pre-Live Confirmation (in Chat)                   │
│  ├→ Bot: You're about to start live trading, please        │
│  │   confirm fee rules:                                    │
│  │   📋 Fee Rules:                                         │
│  │   • Profit Share: 10%                                   │
│  │   • Billing Method: High Watermark                      │
│  │   • Payment Cycle: Monthly                              │
│  │   • Payment Methods: USDT/USDC                          │
│  ├→ [✅ I have read and agree] [❌ Cancel]                  │
│  ├→ User clicks agree → Upload to server for archive       │
│  └→ Unlock live trading functionality                      │
│                                                             │
│  Step 6: Live Trading (in Chat)                            │
│  ├→ "Start paper trading for BTC strategy"                 │
│  ├→ "View current positions"                               │
│  ├→ "Enable live trading"                                  │
│  └→ Bot pushes real-time trading notifications             │
│                                                             │
│  Step 7: Monthly Billing (in Chat)                         │
│  ├→ On the 1st of each month, bot proactively pushes:      │
│  │   📊 March bill generated                               │
│  │   ├─ Monthly profit: $1,250                             │
│  │   ├─ Historical high watermark: $1,000                  │
│  │   ├─ Billing base: $250                                 │
│  │   └─ Fee payable: $25 (10%)                             │
│  ├→ [📋 View Details] [✅ Confirm Bill]                     │
│  ├→ User confirms then uploads to server                   │
│  └→ Server generates payment order                         │
│                                                             │
│  Step 8: Payment (in Chat)                                 │
│  ├→ User: Confirm bill                                     │
│  ├→ Bot: Please select payment method                      │
│  │   [USDT-TRC20] [USDT-ERC20] [USDC-TRC20]                │
│  ├→ After user selects, bot sends:                         │
│  │   💳 Payment Info                                       │
│  │   Amount: 25.00 USDT                                    │
│  │   Address: TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t           │
│  │   [QR Code Image]                                       │
│  ├→ User completes payment                                 │
│  ├→ Server monitors on-chain address for auto-verification │
│  └→ Bot pushes: ✅ Payment confirmed, thank you!           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 4. Tech Stack

### 4.1 Client Tech Stack

| Component | Technology | Notes |
|------|------|------|
| **Framework** | Electron | Cross-platform desktop app |
| **Frontend** | React + TypeScript | Modern UI framework |
| **Local Storage** | SQLite (better-sqlite3) | Encrypted storage |
| **AI Agent** | OpenClaw | Multi-model support |
| **Quant Engine** | Freqtrade | Mature quant framework |
| **Encryption** | crypto (Node.js) | AES-256-GCM |
| **Packaging** | Electron Builder | Generate installers |

### 4.2 Cloud Service Tech Stack (Minimal)

| Component | Technology | Notes |
|------|------|------|
| **Static Website** | Vercel / Cloudflare Pages | Official site hosting |
| **User Registration** | Supabase | Email registration, issue API keys |
| **Payment Confirmation** | Serverless Functions | Confirm on-chain payments |
| **Disable Supabase Key** | Serverless Functions | Disable for overdue users |
| **Enable Supabase Key** | Serverless Functions | Re-enable after payment |
| **Software Updates** | GitHub Releases / S3 | Version distribution |
| **On-Chain Monitoring** | Self-hosted light node | Optional, for payment confirmation |
| **Generate Trading Signals** | Serverless Functions | Daily BTC/ETH strategy signals |

---

## 5. Roadmap

### 5.1 Development Phases

| Phase | Duration | Goals |
|------|------|------|
| **Phase 1: MVP** | Week 1-4 | Electron client, OpenClaw integration, Freqtrade integration, backtesting |
| **Phase 2: Trading** | Week 5-7 | Exchange API connection, paper trading, live trading, local billing |
| **Phase 3: Payment** | Week 8-9 | Fee agreement flow, bill confirmation upload, on-chain monitoring |
| **Phase 4: Optimization** | Week 10+ | Performance tuning, more strategies, user feedback |

---

## 6. Security Design

### 6.1 Data Security

| Data Type | Storage Location | Encryption | Access Control |
|----------|----------|----------|----------|
| User Password | Cloud | bcrypt (cost=12) | Verification only, irreversible |
| Master API Key | Cloud + Client | AES-256-GCM | User master key, password-derived key |
| LLM & Exchange API Keys | Client Only | Local AES-256 | User password-derived key |
| Supabase Key | Cloud-issued + Client storage | AES-256-GCM | Download trading signals, upload fee agreements & bills |
| Trading Records | Client Only | Local AES-256 | User private data |
| High Watermark Records | Client Only | Local AES-256 | User private data |

### 6.2 Key Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│                   Key Hierarchy                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Level 0: Master Key                                       │
│  ├─ Derived from user password (PBKDF2)                    │
│  ├─ Not stored, re-derived from password each time         │
│  └─ Used to encrypt Level 1 keys                           │
│                                                             │
│  Level 1: Data Encryption Key (DEK)                        │
│  ├─ One unique DEK per user                                │
│  ├─ Stored encrypted by master key                         │
│  └─ Used to encrypt actual data                            │
│                                                             │
│  Level 1.5: Supabase Key (Server-issued)                   │
│  ├─ Issued by server after user registration/login         │
│  ├─ Used to access Supabase services                       │
│  │   • Download daily trading signals (BTC/ETH strategies) │
│  │   • Upload fee rule agreement records                   │
│  │   • Upload user-confirmed bill data                     │
│  ├─ Stored locally on client (encrypted)                   │
│  ├─ Server disables key when user overdue on payment       │
│  └─ Server re-enables key after payment                    │
│                                                             │
│  Level 2: Communication Keys                               │
│  ├─ HMAC Key: For request signing                          │
│  ├─ Session Key: JWT signing                               │
│  └─ Periodic rotation                                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 7. Disclaimer

⚠️ **This is a tool, not financial advice.**

- Cryptocurrency trading carries significant risk
- Past performance does not guarantee future results
- You may lose all your invested capital
- Always do your own research (DYOR)

---

## 8. License

MIT License

---

## 9. Contact

- X (Twitter): [@cryptoclaw88](https://x.com/cryptoclaw88)
- GitHub: [franklili3/cryptoclaw](https://github.com/franklili3/cryptoclaw)

---

**Document Version:** v6.0  
**Last Updated:** 2026-03-17  
**Author:** CryptoClaw Team
