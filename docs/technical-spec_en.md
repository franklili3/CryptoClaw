# CryptoQClaw - Technical Specification

> This document contains all code blocks extracted from the Product Requirements Document (requirement.md), organized by category

[中文版](technical-spec.md) | [PRD](requirement_en.md)

---

## Table of Contents

- [1. Database Schema (SQL)](#1-database-schema-sql)
- [2. API Data Structures (JSON)](#2-api-data-structures-json)
- [3. Client Code (JavaScript/TypeScript)](#3-client-code-javascripttypescript)
- [4. Backend Code (Python)](#4-backend-code-python)
- [5. Configuration Files (YAML)](#5-configuration-files-yaml)

---

## 1. Database Schema (SQL)

### 1.1 Fee Agreement Records (Server)

**Source**: Section 2.2 - Fee Agreement Flow

**Description**: Stores user fee rule agreement records for compliance confirmation before live trading.

```sql
-- Fee Agreement Records (Server)
CREATE TABLE fee_agreements (
  id UUID PRIMARY KEY,
  user_id TEXT NOT NULL,
  rule_version TEXT NOT NULL,
  agreed_at TIMESTAMP NOT NULL,
  client_ip TEXT,
  client_signature TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  
  UNIQUE(user_id, rule_version)
);
```

### 1.2 Payment Orders (Server)

**Source**: Section 2.4 - Payment & Verification Flow

**Description**: Server-side payment order information, recording payment details for bills.

```sql
-- Payment Orders (Server)
CREATE TABLE payment_orders (
  id UUID PRIMARY KEY,
  bill_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  amount DECIMAL(20, 8) NOT NULL,
  currency TEXT NOT NULL,
  chain TEXT NOT NULL,
  payment_address TEXT NOT NULL,
  status TEXT DEFAULT 'pending',  -- pending, paid, overdue, cancelled
  created_at TIMESTAMP DEFAULT NOW(),
  expires_at TIMESTAMP,
  
  UNIQUE(bill_id)
);
```

### 1.3 Payment Records (Server)

**Source**: Section 2.4 - Payment & Verification Flow

**Description**: Server-side on-chain payment confirmation records.

```sql
-- Payment Records (Server)
CREATE TABLE payments (
  id UUID PRIMARY KEY,
  order_id TEXT NOT NULL,
  tx_hash TEXT NOT NULL,
  amount DECIMAL(20, 8) NOT NULL,
  currency TEXT NOT NULL,
  chain TEXT NOT NULL,
  confirmations INTEGER DEFAULT 0,
  status TEXT DEFAULT 'pending',  -- pending, confirmed, failed
  detected_at TIMESTAMP,
  confirmed_at TIMESTAMP,
  
  UNIQUE(tx_hash)
);
```

### 1.4 Local Config (Client SQLite)

**Source**: Section 7.1 - Client Local Data

**Description**: Client-side encrypted configuration storage.

```sql
-- Local Config (Encrypted)
CREATE TABLE config (
  key TEXT PRIMARY KEY,
  value TEXT  -- Encrypted storage
);
```

### 1.5 User Info (Client SQLite)

**Source**: Section 7.1 - Client Local Data

**Description**: Client-side basic user information storage.

```sql
-- User Info
CREATE TABLE user (
  id TEXT PRIMARY KEY,
  email TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### 1.6 API Keys (Client SQLite, Encrypted)

**Source**: Section 7.1 - Client Local Data

**Description**: Client-side encrypted storage of various API keys.

```sql
-- API Keys (Encrypted Storage)
CREATE TABLE api_keys (
  id INTEGER PRIMARY KEY,
  provider TEXT NOT NULL,  -- openai, anthropic, binance, okx
  key_name TEXT,
  encrypted_key BLOB NOT NULL,  -- AES-256 encrypted
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### 1.7 Trade Records (Client SQLite)

**Source**: Section 7.1 - Client Local Data

**Description**: Client-side storage of all trade records.

```sql
-- Trade Records
CREATE TABLE trades (
  id INTEGER PRIMARY KEY,
  pair TEXT NOT NULL,
  side TEXT NOT NULL,  -- buy/sell
  amount REAL NOT NULL,
  price REAL NOT NULL,
  cost REAL NOT NULL,
  profit REAL,
  fee REAL,
  strategy TEXT,
  exchange TEXT,
  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### 1.8 High Watermark Records (Client SQLite)

**Source**: Section 7.1 - Client Local Data

**Description**: Client-side storage of high watermark billing records.

```sql
-- High Watermark Records
CREATE TABLE watermarks (
  id INTEGER PRIMARY KEY,
  month TEXT NOT NULL UNIQUE,  -- YYYY-MM
  starting_profit REAL NOT NULL,
  ending_profit REAL NOT NULL,
  high_watermark REAL NOT NULL,
  billable_profit REAL NOT NULL,
  fee_amount REAL NOT NULL,
  status TEXT DEFAULT 'pending',  -- pending, paid
  paid_at DATETIME,
  tx_hash TEXT  -- Payment transaction hash
);
```

### 1.9 Strategy Config (Client SQLite)

**Source**: Section 7.1 - Client Local Data

**Description**: Client-side storage of strategy code and configuration.

```sql
-- Strategy Config
CREATE TABLE strategies (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  code TEXT NOT NULL,  -- Python strategy code
  config TEXT NOT NULL,  -- JSON config
  enabled INTEGER DEFAULT 1,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### 1.10 Payment Records (Client SQLite)

**Source**: Section 7.1 - Client Local Data

**Description**: Client-side storage of payment records.

```sql
-- Payment Records
CREATE TABLE payments (
  id INTEGER PRIMARY KEY,
  month TEXT NOT NULL,  -- Corresponding bill month
  amount REAL NOT NULL,
  currency TEXT NOT NULL,  -- USDT, USDC
  chain TEXT NOT NULL,  -- TRC20, ERC20
  address TEXT NOT NULL,  -- Payment address
  tx_hash TEXT,  -- On-chain transaction hash
  status TEXT DEFAULT 'pending',  -- pending, confirmed
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  confirmed_at DATETIME
);
```

### 1.11 Cloud Service User Info (Server)

**Source**: Section 7.2 - Cloud Service Data

**Description**: Server-side basic user information storage.

```sql
-- User Info
CREATE TABLE user (
  id TEXT PRIMARY KEY,
  email TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### 1.12 Cloud Service Fee Agreement Records (Server)

**Source**: Section 7.2 - Cloud Service Data

**Description**: Server-side fee agreement records (same as 1.1, emphasized as cloud service data).

```sql
-- Fee Agreement Records
CREATE TABLE fee_agreements (
  id UUID PRIMARY KEY,
  user_id TEXT NOT NULL,
  rule_version TEXT NOT NULL,
  agreed_at TIMESTAMP NOT NULL,
  client_ip TEXT,
  client_signature TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  
  UNIQUE(user_id, rule_version)
);
```

### 1.13 Confirmed Bills (Server)

**Source**: Section 7.2 - Cloud Service Data

**Description**: Server-side storage of user-confirmed bill summary data.

```sql
-- Confirmed Bills
CREATE TABLE confirmed_bills (
  id UUID PRIMARY KEY,
  bill_id TEXT NOT NULL UNIQUE,
  user_id TEXT NOT NULL,
  month TEXT NOT NULL,
  cumulative_profit DECIMAL(20, 8) NOT NULL,
  high_watermark DECIMAL(20, 8) NOT NULL,
  billable_profit DECIMAL(20, 8) NOT NULL,
  fee_amount DECIMAL(20, 8) NOT NULL,
  currency VARCHAR(10) NOT NULL DEFAULT 'USDT',
  confirmed_at TIMESTAMP NOT NULL,
  client_signature TEXT NOT NULL,
  status VARCHAR(20) DEFAULT 'pending',  -- pending, paid, overdue
  created_at TIMESTAMP DEFAULT NOW()
);
```

### 1.14 Payment Confirmations (Server)

**Source**: Section 7.2 - Cloud Service Data

**Description**: Server-side storage of on-chain payment confirmation details.

```sql
-- Payment Confirmations
CREATE TABLE payment_confirmations (
  id UUID PRIMARY KEY,
  bill_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  tx_hash TEXT NOT NULL UNIQUE,
  amount DECIMAL(20, 8) NOT NULL,
  currency VARCHAR(10) NOT NULL,
  chain VARCHAR(20) NOT NULL,  -- TRC20, ERC20
  from_address TEXT,
  to_address TEXT NOT NULL,
  block_number BIGINT,
  confirmations INTEGER DEFAULT 0,
  status VARCHAR(20) DEFAULT 'pending',  -- pending, confirmed, failed
  confirmed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  
  FOREIGN KEY (bill_id) REFERENCES confirmed_bills(bill_id)
);
```

### 1.15 User Payment Addresses (Server)

**Source**: Section 7.2 - Cloud Service Data

**Description**: Server-side storage of user-specific payment addresses (HD wallet derived).

```sql
-- User Payment Addresses (HD Wallet Derived)
CREATE TABLE user_payment_addresses (
  id UUID PRIMARY KEY,
  user_id TEXT NOT NULL,
  currency VARCHAR(10) NOT NULL,
  chain VARCHAR(20) NOT NULL,
  address TEXT NOT NULL,
  derivation_path TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  expires_at TIMESTAMP,
  
  UNIQUE(user_id, currency, chain)
);
```

---

## 2. API Data Structures (JSON)

### 2.1 Fee Agreement Data

**Source**: Section 2.2 - Fee Agreement Flow

**Description**: Fee agreement record generated by client and uploaded to server.

```json
{
  "user_id": "xxx",
  "agreed_at": "2026-03-17T09:00:00Z",
  "rule_version": "v1.0",
  "client_signature": "xxx"
}
```

### 2.2 Monthly Bill Data

**Source**: Section 2.3 - Monthly Billing Flow

**Description**: Monthly bill data structure generated locally by client.

```json
{
  "month": "2026-02",
  "cumulative_profit": 1250.00,
  "high_watermark": 1000.00,
  "billable_profit": 250.00,
  "fee_amount": 25.00,
  "trades": [],
  "generated_at": "2026-03-01T00:00:00Z"
}
```

### 2.3 Bill Upload Data Structure

**Source**: Section 2.3 - Monthly Billing Flow

**Description**: Bill summary data uploaded to server after user confirmation (without trade details).

```json
{
  "bill_id": "bill_xxx",
  "user_id": "user_xxx",
  "month": "2026-02",
  "cumulative_profit": 1250.00,
  "high_watermark": 1000.00,
  "billable_profit": 250.00,
  "fee_amount": 25.00,
  "currency": "USDT",
  "confirmed_at": "2026-03-01T10:30:00Z",
  "client_signature": "hmac_sha256_signature",
  "trade_count": 45
}
```

### 2.4 Risk Control Config

**Source**: Section 5.2 - Core Features (Risk System)

**Description**: Client risk control system configuration parameters example.

```json
{
  "risk_control": {
    "account": {
      "max_position_value": 10000,
      "max_daily_loss_percent": 5,
      "max_daily_trades": 20,
      "max_open_trades": 5
    },
    "trade": {
      "default_stoploss": -0.05,
      "default_take_profit": 0.10,
      "max_position_time_hours": 24,
      "single_trade_max_stake": 500
    },
    "market": {
      "volatility_threshold": 0.1,
      "min_volume_24h": 1000000,
      "blacklist": ["DOGE", "SHIB", "PEPE"]
    },
    "alerts": {
      "channels": ["email", "push", "telegram"],
      "risk_trigger": true,
      "large_loss": 100,
      "api_error": true
    }
  }
}
```

### 2.5 Log Format

**Source**: Section 13.2 - Logging Standards

**Description**: Standard JSON format for application logs.

```json
{
  "timestamp": "2026-03-16T08:30:00.000Z",
  "level": "INFO",
  "service": "quantagent-api",
  "trace_id": "abc123",
  "user_id": "user_xxx",
  "action": "trade_report",
  "result": "success",
  "duration_ms": 45,
  "metadata": {
    "pair": "BTC/USDT",
    "profit": 25.50
  }
}
```

---

## 3. Client Code (JavaScript/TypeScript)

### 3.1 High Watermark Billing Calculator

**Source**: Section 8.2 - High Watermark Calculation (Local)

**Description**: Core class for calculating monthly bills and high watermarks locally on client.

```javascript
// Client-side local calculation
class BillingCalculator {
  
  /**
   * Calculate monthly bill
   */
  calculateMonthlyBilling(month) {
    // 1. Get all trades for this month from local database
    const trades = this.db.query(`
      SELECT * FROM trades 
      WHERE strftime('%Y-%m', timestamp) = ?
      ORDER BY timestamp
    `, [month]);
    
    // 2. Calculate cumulative profit
    const cumulativeProfit = trades.reduce((sum, t) => sum + (t.profit || 0), 0);
    
    // 3. Get historical high watermark
    const lastWatermark = this.db.queryOne(`
      SELECT high_watermark FROM watermarks 
      WHERE month < ? 
      ORDER BY month DESC LIMIT 1
    `, [month]);
    const highWatermark = lastWatermark?.high_watermark || 0;
    
    // 4. Calculate billable profit
    const billableProfit = Math.max(0, cumulativeProfit - highWatermark);
    
    // 5. Calculate fee (10%)
    const fee = billableProfit * 0.10;
    
    // 6. Update high watermark
    const newHighWatermark = Math.max(highWatermark, cumulativeProfit);
    
    // 7. Save to local database
    this.db.run(`
      INSERT OR REPLACE INTO watermarks 
      (month, starting_profit, ending_profit, high_watermark, billable_profit, fee_amount, status)
      VALUES (?, ?, ?, ?, ?, ?, 'pending')
    `, [month, lastWatermark?.ending_profit || 0, cumulativeProfit, 
        newHighWatermark, billableProfit, fee]);
    
    return {
      month,
      cumulativeProfit,
      highWatermark,
      billableProfit,
      fee,
      newHighWatermark
    };
  }
  
  /**
   * Get all historical bills
   */
  getAllBillings() {
    return this.db.query(`
      SELECT * FROM watermarks ORDER BY month
    `);
  }
}
```

### 3.2 Payment Address Management

**Source**: Section 9.4 - Payment Address Management

**Description**: Fixed receiving address configuration and user-specific address derivation function.

```javascript
// Fixed receiving addresses (simple approach)
const PAYMENT_ADDRESSES = {
  'USDT-TRC20': 'TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t',
  'USDT-ERC20': '0x742d35Cc6634C0532925a3b844Bc9e7595f8bDe2',
  'USDC-TRC20': 'TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t',
  'USDC-ERC20': '0x742d35Cc6634C0532925a3b844Bc9e7595f8bDe2'
};

// Optional: User-specific addresses (HD wallet derivation)
function getUserPaymentAddress(userId, currency, chain) {
  // Derive child address using master wallet's xpub
  const path = `m/44'/${coinType}'/${userId}'/0/0`;
  const address = deriveAddress(masterXpub, path);
  return address;
}
```

### 3.3 Server On-Chain Payment Monitoring System

**Source**: Section 9.5 - Server On-Chain Monitoring (Core Feature)

**Description**: Server-side service class for monitoring on-chain payments and automatic verification.

```javascript
// Server-side on-chain monitoring system
class PaymentMonitor {
  
  constructor() {
    this.tronGridClient = new TronGridClient(TRONGRID_API_KEY);
    this.etherscanClient = new EtherscanClient(ETHERSCAN_API_KEY);
  }
  
  /**
   * Start monitoring task
   */
  async startMonitoring() {
    
    // Use WebSocket for real-time listening
    this.startWebSocketListener();
  }
  
  /**
   * Check pending payments
   */
  async checkPendingPayments() {
    const pendingOrders = await db.query(`
      SELECT * FROM payment_orders 
      WHERE status = 'pending' 
      AND created_at > NOW() - INTERVAL '7 days'
    `);
    
    for (const order of pendingOrders) {
      await this.checkOrderPayment(order);
    }
  }
  
  /**
   * Check payment for a single order
   */
  async checkOrderPayment(order) {
    const { payment_address, amount, currency, chain } = order;
    
    let transactions;
    if (chain === 'TRC20') {
      transactions = await this.tronGridClient.getTRC20Transactions(
        payment_address,
        currency
      );
    } else if (chain === 'ERC20') {
      transactions = await this.etherscanClient.getERC20Transactions(
        payment_address,
        currency
      );
    }
    
    // Verify transactions
    for (const tx of transactions) {
      if (this.verifyTransaction(tx, order)) {
        await this.confirmPayment(order, tx);
        break;
      }
    }
  }
  
  /**
   * Verify transaction
   */
  verifyTransaction(tx, order) {
    // Verify address
    if (tx.to.toLowerCase() !== order.payment_address.toLowerCase()) {
      return false;
    }
    
    // Verify amount (allow 1% tolerance for precision issues)
    const expectedAmount = order.amount;
    const actualAmount = parseFloat(tx.value) / 1e6;  // USDT 6 decimals
    if (actualAmount < expectedAmount * 0.99) {
      return false;
    }
    
    // Verify confirmations
    if (tx.confirmations < MIN_CONFIRMATIONS) {
      return false;
    }
    
    return true;
  }
  
  /**
   * Confirm payment
   */
  async confirmPayment(order, tx) {
    await db.transaction(async (conn) => {
      // Update payment order status
      await conn.query(`
        UPDATE payment_orders 
        SET status = 'paid', paid_at = NOW()
        WHERE id = ?
      `, [order.id]);
      
      // Record payment details
      await conn.query(`
        INSERT INTO payment_confirmations 
        (bill_id, user_id, tx_hash, amount, currency, chain, 
         from_address, to_address, status, confirmed_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'confirmed', NOW())
      `, [order.bill_id, order.user_id, tx.hash, 
          tx.value / 1e6, order.currency, order.chain,
          tx.from, tx.to]);
      
      // Update bill status
      await conn.query(`
        UPDATE confirmed_bills 
        SET status = 'paid'
        WHERE bill_id = ?
      `, [order.bill_id]);
      
      // Notify user
      await this.notifyUser(order.user_id, {
        type: 'payment_confirmed',
        bill_id: order.bill_id,
        amount: order.amount
      });
    });
  }
}
```

### 3.4 Bill Confirmation Upload Client

**Source**: Section 9.6 - Bill Confirmation Upload Mechanism

**Description**: Client-side class for bill confirmation and upload to server.

```javascript
// Client-side bill confirmation upload
class BillingUploader {
  
  /**
   * User confirms bill and uploads
   */
  async confirmAndUpload(monthBilling) {
    // 1. User confirms bill on UI
    const userConfirmed = await this.showBillingConfirmation(monthBilling);
    if (!userConfirmed) {
      return { success: false, reason: 'user_cancelled' };
    }
    
    // 2. Prepare upload data (without trade details)
    const uploadData = {
      bill_id: this.generateBillId(),
      user_id: this.getCurrentUserId(),
      month: monthBilling.month,
      cumulative_profit: monthBilling.cumulativeProfit,
      high_watermark: monthBilling.highWatermark,
      billable_profit: monthBilling.billableProfit,
      fee_amount: monthBilling.fee,
      currency: 'USDT',
      trade_count: monthBilling.trades.length,
      confirmed_at: new Date().toISOString()
    };
    
    // 3. Generate client signature
    const signature = this.signData(uploadData);
    uploadData.client_signature = signature;
    
    // 4. Upload to server
    try {
      const response = await fetch('/api/billing/confirm', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(uploadData)
      });
      
      const result = await response.json();
      
      if (result.success) {
        // 5. Save payment info returned from server
        this.savePaymentInfo({
          bill_id: uploadData.bill_id,
          payment_address: result.payment_address,
          expires_at: result.expires_at
        });
        
        return { 
          success: true, 
          payment_address: result.payment_address 
        };
      } else {
        return { success: false, reason: result.error };
      }
    } catch (error) {
      // Network failure, retry later
      this.queueForRetry(uploadData);
      return { success: false, reason: 'network_error' };
    }
  }
  
  /**
   * Sign data
   */
  signData(data) {
    const message = JSON.stringify(data);
    const hmac = crypto.createHmac('sha256', this.getClientSecret());
    hmac.update(message);
    return hmac.digest('hex');
  }
}
```

### 3.5 Local Data Encryption

**Source**: Section 10.4 - Local Data Security

**Description**: Client-side implementation of local data encryption and decryption.

```javascript
// Local data encryption
class LocalDataSecurity {
  
  /**
   * Encrypt sensitive data using key derived from user password
   */
  encryptData(plaintext, userPassword) {
    // Derive key from password
    const key = this.deriveKey(userPassword);
    
    // AES-256-GCM encryption
    const nonce = crypto.randomBytes(12);
    const cipher = crypto.createCipheriv('aes-256-gcm', key, nonce);
    const encrypted = Buffer.concat([
      cipher.update(plaintext, 'utf8'),
      cipher.final()
    ]);
    const tag = cipher.getAuthTag();
    
    return {
      nonce: nonce.toString('base64'),
      data: encrypted.toString('base64'),
      tag: tag.toString('base64')
    };
  }
  
  /**
   * Decrypt local data
   */
  decryptData(encrypted, userPassword) {
    const key = this.deriveKey(userPassword);
    
    const decipher = crypto.createDecipheriv(
      'aes-256-gcm', 
      key, 
      Buffer.from(encrypted.nonce, 'base64')
    );
    decipher.setAuthTag(Buffer.from(encrypted.tag, 'base64'));
    
    const decrypted = Buffer.concat([
      decipher.update(Buffer.from(encrypted.data, 'base64')),
      decipher.final()
    ]);
    
    return decrypted.toString('utf8');
  }
}
```

### 3.6 Client User Registration/Login

**Source**: Section 11.8 - Technical Implementation

**Description**: Implementation of embedded user authentication in Electron client.

```javascript
// Embedded user registration/login page in Electron
async function openAuth(mode = 'login') {
  // Open auth window (embedded browser)
  const authWindow = new BrowserWindow({
    width: 450,
    height: 600,
    title: mode === 'login' ? 'Login' : 'Register',
    resizable: false,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true
    }
  });
  
  // Load auth page (cloud-hosted)
  authWindow.loadURL(`https://auth.quantagent.pro/${mode}`);
  
  // Listen for auth complete event
  ipcMain.on('auth-complete', async (event, result) => {
    if (result.success) {
      // Save user info locally (without sensitive info)
      await localDB.saveUserInfo({
        userId: result.userId,
        email: result.email,
        supabaseKey: result.supabaseKey  // Server-issued API Key
      });
      
      // Notify channel to bind user
      await notifyChannelBinding(result.userId);
    }
    authWindow.close();
  });
  
  // Listen for window close
  authWindow.on('closed', () => {
    authWindow = null;
  });
}

// Check login status
async function checkAuthStatus() {
  const userInfo = await localDB.getUserInfo();
  if (!userInfo) {
    // Not logged in, open login window
    return openAuth('login');
  }
  
  // Verify if Supabase Key is valid
  const isValid = await verifySupabaseKey(userInfo.supabaseKey);
  if (!isValid) {
    // Key invalid (possibly overdue payment), notify user
    dialog.showMessageBox({
      type: 'warning',
      title: 'Account Status Abnormal',
      message: 'Your account may be overdue, please check payment status',
      buttons: ['View Bill', 'Later']
    }).then(result => {
      if (result.response === 0) {
        // Guide user to channel to view bill
        shell.openExternal('https://t.me/quantagent_bot');
      }
    });
  }
  
  return isValid;
}
```

### 3.7 Offline-First Data Sync

**Source**: Section 11.8 - Technical Implementation

**Description**: Client data sync strategy supporting offline usage.

```javascript
// Data sync strategy
class DataSync {
  async syncBillingData() {
    if (!navigator.onLine) {
      // Use local cache when offline
      return await localDB.getBillingData();
    }
    
    try {
      // Sync cloud data when online
      const cloudData = await api.fetchBillingData();
      await localDB.saveBillingData(cloudData);
      return cloudData;
    } catch (error) {
      // Fallback to local on network failure
      return await localDB.getBillingData();
    }
  }
}
```

### 3.8 Payment Confirmation Client

**Source**: Section 10.5 - Payment Confirmation Security

**Description**: Client-side implementation of payment confirmation and on-chain verification.

```javascript
// Client-side payment confirmation
class PaymentConfirmation {
  
  async confirmPayment(month, txHash) {
       
    // 1. Verify on-chain transaction
    const verified = await this.verifyOnChain(txHash, month);
    
    // 2. Update local order status
    this.db.run(`
      UPDATE watermarks 
      SET status = 'paid', paid_at = ?, tx_hash = ?, verified = ?
      WHERE month = ?
    `, [new Date().toISOString(), txHash, verified, month]);
    
    // 3. Notify server
    if (verified) {
      await this.notifyServer(month, txHash);
    }
    
    return { success: true, verified };
  }
  
  /**
   * On-chain verification
   */
  async verifyOnChain(txHash, month) {
    try {
      // Query transaction using public API
      const tx = await this.fetchTransaction(txHash);
      const bill = this.getBilling(month);
      
      // Verify amount and receiving address
      return tx.to === PAYMENT_ADDRESS && 
             tx.value >= bill.fee_amount * 1e6;
    } catch {
      // Verification failure doesn't prevent user from marking as paid
      return false;
    }
  }
}
```

---

## 4. Backend Code (Python)

### 4.1 OpenClaw-Freqtrade Bridge Layer

**Source**: Section 5.2 - OpenClaw & Freqtrade Integration

**Description**: Integration interface between OpenClaw agent and Freqtrade quant engine.

```python
# Integration Layer API (Python)

class OpenClawFreqtradeBridge:
    """Bridge layer between OpenClaw and Freqtrade"""
    
    def __init__(self, freqtrade_path: str, config_path: str):
        self.freqtrade_path = freqtrade_path
        self.config_path = config_path
    
    async def create_strategy(self, natural_language: str) -> str:
        """
        Convert natural language to Freqtrade strategy code
        
        Args:
            natural_language: User-described strategy logic
            
        Returns:
            Generated strategy file path
        """
        # 1. Call OpenClaw to understand user intent
        # 2. Generate Freqtrade strategy code
        # 3. Save to user_data/strategies/
        # 4. Validate strategy syntax
        pass
    
    async def run_backtest(self, strategy: str, 
                          timerange: str,
                          stake_amount: float) -> BacktestResult:
        """
        Execute backtest and return results
        
        Args:
            strategy: Strategy name
            timerange: Time range (e.g., "20240101-20241231")
            stake_amount: Stake amount per trade
            
        Returns:
            Backtest result object
        """
        # 1. Call freqtrade backtesting
        # 2. Parse result JSON
        # 3. Return structured data
        pass
    
    async def start_trading(self, strategy: str, 
                           dry_run: bool = True) -> str:
        """
        Start live/paper trading
        
        Args:
            strategy: Strategy name
            dry_run: Whether paper trading mode
            
        Returns:
            Process ID
        """
        pass
    
    async def get_trade_status(self) -> TradeStatus:
        """Get current trading status"""
        pass
    
    async def stop_trading(self) -> bool:
        """Stop trading"""
        pass
```

### 4.2 Key Manager

**Source**: Section 10.3 - Key Management Scheme

**Description**: Server-side implementation of key derivation and API key encryption/decryption.

```python
import hashlib
import base64
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

class KeyManager:
    """Key Manager"""
    
    ITERATIONS = 100000
    KEY_LENGTH = 32  # 256 bits
    
    @staticmethod
    def derive_master_key(password: str, salt: bytes) -> bytes:
        """
        Derive master key from user password
        
        Args:
            password: User password
            salt: Random salt value (stored on server)
            
        Returns:
            256-bit master key
        """
        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=KeyManager.KEY_LENGTH,
            salt=salt,
            iterations=KeyManager.ITERATIONS,
        )
        return kdf.derive(password.encode())
    
    @staticmethod
    def encrypt_api_key(api_key: str, master_key: bytes) -> dict:
        """
        Encrypt API Key
        
        Returns:
            {
                'ciphertext': base64-encoded ciphertext,
                'nonce': base64-encoded nonce,
                'tag': base64-encoded auth tag
            }
        """
        nonce = os.urandom(12)  # 96-bit nonce for GCM
        aesgcm = AESGCM(master_key)
        
        ciphertext = aesgcm.encrypt(
            nonce,
            api_key.encode(),
            None  # no additional data
        )
        
        return {
            'ciphertext': base64.b64encode(ciphertext).decode(),
            'nonce': base64.b64encode(nonce).decode()
        }
    
    @staticmethod
    def decrypt_api_key(encrypted: dict, master_key: bytes) -> str:
        """Decrypt API Key"""
        nonce = base64.b64decode(encrypted['nonce'])
        ciphertext = base64.b64decode(encrypted['ciphertext'])
        
        aesgcm = AESGCM(master_key)
        plaintext = aesgcm.decrypt(nonce, ciphertext, None)
        
        return plaintext.decode()
```

### 4.3 Server Bill Confirmation API

**Source**: Section 9.6 - Bill Confirmation Upload Mechanism

**Description**: Server API endpoint for receiving and processing user-confirmed bills.

```python
# Server bill confirmation API
@router.post('/api/billing/confirm')
async def confirm_billing(request: BillingConfirmRequest):
    # 1. Verify signature
    if not verify_client_signature(request.dict(), request.client_signature):
        raise HTTPException(400, 'Invalid signature')
    
    # 2. Check if already confirmed
    existing = await db.fetch_one(
        'SELECT id FROM confirmed_bills WHERE user_id = ? AND month = ?',
        request.user_id, request.month
    )
    if existing:
        raise HTTPException(400, 'Bill already confirmed')
    
    # 3. Generate payment address
    payment_address = await generate_payment_address(
        request.user_id, 
        request.currency
    )
    
    # 4. Save bill
    await db.execute('''
        INSERT INTO confirmed_bills 
        (bill_id, user_id, month, cumulative_profit, high_watermark, 
         billable_profit, fee_amount, currency, confirmed_at, client_signature, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending')
    ''', request.bill_id, request.user_id, request.month, 
         request.cumulative_profit, request.high_watermark,
         request.billable_profit, request.fee_amount, request.currency,
         request.confirmed_at, request.client_signature)
    
    # 5. Create payment order
    await db.execute('''
        INSERT INTO payment_orders 
        (bill_id, user_id, amount, currency, chain, payment_address, status, expires_at)
        VALUES (?, ?, ?, ?, ?, ?, 'pending', ?)
    ''', request.bill_id, request.user_id, request.fee_amount,
         request.currency, 'TRC20', payment_address,
         datetime.now() + timedelta(days=7))
    
    return {
        'success': True,
        'bill_id': request.bill_id,
        'payment_address': payment_address,
        'amount': request.fee_amount,
        'expires_at': (datetime.now() + timedelta(days=7)).isoformat()
    }
```

### 4.4 High Watermark Calculation Unit Tests

**Source**: Section 13.2 - Unit Testing

**Description**: Unit test cases for high watermark calculation logic.

```python
# Example: High watermark calculation unit tests
import pytest
from datetime import datetime

class TestHighWatermark:
    
    def test_first_month_profit(self):
        """First month profit: all billable"""
        result = calculate_billing(
            cumulative_profit=500,
            previous_high_watermark=0
        )
        assert result['billable'] == 500
        assert result['fee'] == 50  # 10%
        assert result['new_high_watermark'] == 500
    
    def test_below_high_watermark(self):
        """Below high watermark: no billing"""
        result = calculate_billing(
            cumulative_profit=300,
            previous_high_watermark=500
        )
        assert result['billable'] == 0
        assert result['fee'] == 0
        assert result['new_high_watermark'] == 500  # Unchanged
    
    def test_exceed_high_watermark(self):
        """Exceed high watermark: only bill excess"""
        result = calculate_billing(
            cumulative_profit=700,
            previous_high_watermark=500
        )
        assert result['billable'] == 200
        assert result['fee'] == 20
        assert result['new_high_watermark'] == 700
    
    def test_negative_profit(self):
        """Loss situation: no billing"""
        result = calculate_billing(
            cumulative_profit=-100,
            previous_high_watermark=500
        )
        assert result['billable'] == 0
        assert result['fee'] == 0
        assert result['new_high_watermark'] == 500
```

---

## 5. Configuration Files (YAML)

### 5.1 CI/CD Release Pipeline

**Source**: Section 17.4 - CI/CD Flow

**Description**: GitHub Actions automated build and release configuration.

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build macOS app
        run: |
          npm ci
          npm run build:mac
          
      - name: Upload to Release
        uses: softprops/action-gh-release@v1
        with:
          files: dist/*.dmg
          
      - name: Upload to S3 (optional)
        run: |
          aws s3 sync dist/ s3://quantagent-releases/
```

### 4.5 Auto-Update API

**Source**: Section 8.2 - Auto-Update Mechanism

**Description**: Client API for checking and downloading software updates.

```typescript
// Check Update API
// GET /api/updates/check?version=1.0.0&platform=darwin

interface UpdateCheckResponse {
  hasUpdate: boolean;
  latestVersion: string;
  forceUpdate: boolean;  // Force update required
  releaseNotes: string;  // Markdown release notes
  downloadUrl: string;   // Download URL
  fileSize: number;      // File size (bytes)
  checksum: string;      // SHA256 checksum
}

// Example response
const response: UpdateCheckResponse = {
  hasUpdate: true,
  latestVersion: "1.2.0",
  forceUpdate: false,
  releaseNotes: "### New Features\n- Added ETH strategy\n- Performance optimization",
  downloadUrl: "/api/updates/download/v1.2.0/darwin",
  fileSize: 125829120,
  checksum: "sha256:abc123..."
};
```

---

## 6. Architecture Diagrams (ASCII Art)

### 6.1 Functional Architecture

**Source**: Section 5.1 - Functional Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    User Interaction Layer                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              Chat Channels (Core Interaction)            │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │   │
│  │  │  Telegram   │  │  WhatsApp   │  │   Web Chat  │      │   │
│  │  │  (Primary)  │  │  (Primary)  │  │  (Backup)   │      │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘      │   │
│  │                                                         │   │
│  │  Complete via Chat:                                      │   │
│  │  ✅ Strategy writing, data download, backtesting         │   │
│  │  ✅ Paper trading, live trading, monitoring              │   │
│  │  ✅ Billing reconciliation, fee calculation              │   │
│  │  ✅ QR code payment, payment status                      │   │
│  │  ✅ Risk alerts, trade notifications                     │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              ↓                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │          Desktop Client (Sensitive Info Only)            │   │
│  │  ┌─────────────┐  ┌─────────────┐                       │   │
│  │  │   macOS    │  │   Linux    │                        │   │
│  │  │ (Electron) │  │ (Electron) │                        │   │
│  │  └─────────────┘  └─────────────┘                       │   │
│  │                                                         │   │
│  │  Manage Sensitive Info Only (Local Encrypted, Never Upload):│
│  │  🔐 LLM API Keys (OpenAI/Claude/Local)                  │   │
│  │  🔐 Exchange API Keys (Binance/OKX)                     │   │
│  │  🔐 User Master Key (for local data encryption)         │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    Backend Service Layer                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              Agent System (OpenClaw)                     │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │   │
│  │  │ Dialog Route│  │ Intent Rec  │  │Task Executor│      │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘      │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              ↓                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              Quant Engine (Freqtrade)                    │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │   │
│  │  │Data Download│  │  Backtest   │  │Live Trading │      │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘      │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │   │
│  │  │Param Optimize│  │Risk Analysis│  │Bill Calc   │      │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘      │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              ↓                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              Local Services (All Offline)                │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │   │
│  │  │Local Storage│  │High Watermark│  │Bill Generate│     │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘      │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              ↕
┌─────────────────────────────────────────────────────────────────┐
│                    CryptoQClaw Cloud Services                    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │Fee Agreement│  │Bill Confirm │  │Pay Monitor  │              │
│  │   Archive   │  │             │  │             │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │User Auth    │  │Push Notify  │  │SW Updates   │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
└─────────────────────────────────────────────────────────────────┘
```

### 6.2 High Watermark Mechanism

**Source**: Section 2.2 - Profit Sharing Model

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

### 6.3 Security Architecture

**Source**: Section 10.1 - Security Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Security Layers                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Layer 1: Transport Security                                │
│  ├─ All communications use HTTPS (TLS 1.3)                 │
│  ├─ Certificate Pinning                                     │
│  └─ API request signature verification                     │
│                                                             │
│  Layer 2: Authentication & Authorization                    │
│  ├─ JWT Token authentication                                │
│  ├─ Refresh Token mechanism                                 │
│  ├─ Device binding (optional)                               │
│  └─ Multi-factor auth (optional)                            │
│                                                             │
│  Layer 3: Data Encryption                                   │
│  ├─ Sensitive data AES-256-GCM encrypted                    │
│  ├─ Key derivation PBKDF2 (100,000 iterations)              │
│  ├─ Local storage encryption (SQLite encrypted)             │
│  └─ Memory safety (sensitive data zeroed after use)         │
│                                                             │
│  Layer 4: Business Security                                 │
│  ├─ Trade report HMAC signature                             │
│  ├─ Replay attack prevention (Nonce + Timestamp)            │
│  ├─ Rate limiting                                           │
│  └─ Audit logs                                              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 6.4 Key Hierarchy

**Source**: Section 10.3 - Key Management Scheme

```
┌─────────────────────────────────────────────────────────────┐
│                     Key Hierarchy                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Level 0: Master Key                                        │
│  ├─ Derived from user password (PBKDF2)                     │
│  ├─ Not stored, re-derived from password each time          │
│  └─ Used to encrypt Level 1 keys                            │
│                                                             │
│  Level 1: Data Encryption Key (DEK)                         │
│  ├─ One unique DEK per user                                 │
│  ├─ Stored encrypted by master key                          │
│  └─ Used to encrypt actual data                             │
│                                                             │
│  Level 1.5: Supabase Key (Server-issued)                    │
│  ├─ Issued by server after user registration/login          │
│  ├─ Used to access Supabase services                        │
│  │   • Download daily trading signals (BTC/ETH strategies)  │
│  │   • Upload fee rule agreement records                    │
│  │   • Upload user-confirmed bill data                      │
│  ├─ Stored locally on client (encrypted)                    │
│  ├─ Server disables key when user overdue on payment        │
│  └─ Server re-enables key after payment                     │
│                                                             │
│  Level 2: Communication Keys                                │
│  ├─ HMAC Key: For request signing                           │
│  ├─ Session Key: JWT signing                                │
│  └─ Periodic rotation                                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 6.5 Testing Pyramid

**Source**: Section 13.1 - Testing Layers

```
┌─────────────────────────────────────────────────────────────┐
│                     Testing Pyramid                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                     ╱╲                                      │
│                    ╱  ╲                                     │
│                   ╱ E2E╲          10%                       │
│                  ╱──────╲                                   │
│                 ╱Integration╲     20%                       │
│                ╱────────────╲                               │
│               ╱  Unit Tests  ╲    70%                       │
│              ╱────────────────╲                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 7. Deployment Configuration (YAML)

### 7.1 CI/CD Release Pipeline

**Source**: Section 17.4 - CI/CD Flow

**Description**: GitHub Actions automated build and release configuration.

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build macOS app
        run: |
          npm ci
          npm run build:mac
          
      - name: Upload to Release
        uses: softprops/action-gh-release@v1
        with:
          files: dist/*.dmg
          
      - name: Upload to S3 (optional)
        run: |
          aws s3 sync dist/ s3://quantagent-releases/
```

---

## 8. Docker Image & Deployment Configuration

### 8.1 Dockerfile

**Source**: design_en.md Section 6.2.1

**Description**: CryptoQClaw Docker image build file.

```dockerfile
# Dockerfile
FROM python:3.11-slim

# Install Node.js (OpenClaw dependency)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs

# Install Freqtrade
RUN pip install freqtrade

# Install OpenClaw
RUN npm install -g openclaw

# Create working directory
WORKDIR /app

# Copy configuration templates
COPY user_data/ /app/user_data/
COPY workspace/ /app/workspace/

# Data volume mount points
VOLUME ["/app/user_data", "/app/workspace", "/app/logs"]

# Startup script
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
```

### 8.2 One-Click Install Script (macOS/Linux)

**Source**: design_en.md Section 6.2.2

```bash
#!/bin/bash
# install.sh - CryptoQClaw one-click installer

set -e

echo "🚀 CryptoQClaw Installer"
echo "========================"

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not detected, installing..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install --cask docker
        else
            echo "Please install Homebrew first: https://brew.sh"
            exit 1
        fi
    elif [[ "$OSTYPE" == "linux"* ]]; then
        # Linux
        curl -fsSL https://get.docker.com | sh
        sudo usermod -aG docker $USER
    fi
fi

# Pull image
echo "📦 Downloading CryptoQClaw image..."
docker pull cryptoclaw/cryptoclaw:latest

# Create directory structure
echo "📁 Creating working directories..."
mkdir -p ~/.cryptoclaw/{user_data,workspace,logs,config}

# Download config template
if [ ! -f ~/.cryptoclaw/user_data/config.json ]; then
    echo "⚙️  Downloading config template..."
    curl -fsSL https://raw.githubusercontent.com/franklili3/CryptoQClaw/main/templates/config.json \
        -o ~/.cryptoclaw/user_data/config.json
fi

# Create start script
cat > ~/.cryptoclaw/start.sh << 'EOF'
#!/bin/bash
cd ~/.cryptoclaw
docker-compose up -d
echo "✅ CryptoQClaw started"
echo "📱 Visit Telegram and search your bot to get started"
EOF
chmod +x ~/.cryptoclaw/start.sh

# Create stop script
cat > ~/.cryptoclaw/stop.sh << 'EOF'
#!/bin/bash
cd ~/.cryptoclaw
docker-compose down
echo "🛑 CryptoQClaw stopped"
EOF
chmod +x ~/.cryptoclaw/stop.sh

echo ""
echo "✅ Installation complete!"
echo ""
echo "Usage:"
echo "  Start: ~/.cryptoclaw/start.sh"
echo "  Stop:  ~/.cryptoclaw/stop.sh"
echo "  Config: ~/.cryptoclaw/config/"
echo ""
```

### 8.3 One-Click Install Script (Windows PowerShell)

**Source**: design_en.md Section 6.2.2

```powershell
# install.ps1
Write-Host "🚀 CryptoQClaw Installer" -ForegroundColor Green

# Check Docker
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Docker Desktop not detected" -ForegroundColor Red
    Write-Host "Please install first: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
    exit 1
}

# Pull image
Write-Host "📦 Downloading CryptoQClaw image..." -ForegroundColor Cyan
docker pull cryptoclaw/cryptoclaw:latest

# Create directories
$cryptoclawDir = "$env:USERPROFILE\.cryptoclaw"
New-Item -ItemType Directory -Force -Path "$cryptoclawDir\user_data"
New-Item -ItemType Directory -Force -Path "$cryptoclawDir\workspace"
New-Item -ItemType Directory -Force -Path "$cryptoclawDir\logs"
New-Item -ItemType Directory -Force -Path "$cryptoclawDir\config"

# Download config template
$configUrl = "https://raw.githubusercontent.com/franklili3/CryptoQClaw/main/templates/config.json"
Invoke-WebRequest -Uri $configUrl -OutFile "$cryptoclawDir\user_data\config.json"

Write-Host "✅ Installation complete!" -ForegroundColor Green
Write-Host "Run to start: docker-compose -f $cryptoclawDir\config\docker-compose.yml up -d"
```

### 8.4 Docker Compose Configuration

**Source**: design_en.md Section 6.2.3 & 6.2.4

```yaml
# docker-compose.yml
version: '3.8'

services:
  cryptoclaw:
    image: cryptoclaw/cryptoclaw:latest
    container_name: cryptoclaw
    restart: unless-stopped
    
    volumes:
      # Freqtrade data directory
      - ~/.cryptoclaw/user_data:/app/user_data
      # OpenClaw workspace
      - ~/.cryptoclaw/workspace:/app/workspace
      # Logs
      - ~/.cryptoclaw/logs:/app/logs
      # OpenClaw config
      - ~/.cryptoclaw/config/openclaw.yaml:/app/config/openclaw.yaml:ro
    
    ports:
      - "8080:8080"  # API Server (optional)
    
    env_file:
      # Load env vars from .env file
      - ~/.cryptoclaw/config/.env
    
    environment:
      - TZ=Asia/Shanghai
      - LOG_LEVEL=info
      - OPENCLAW_CONFIG=/app/config/openclaw.yaml
```

### 8.5 OpenClaw Configuration File

**Source**: design_en.md Section 6.2.4

```yaml
# ~/.cryptoclaw/config/openclaw.yaml
# OpenClaw Gateway Configuration

gateway:
  name: cryptoclaw
  port: 8080

channels:
  # Telegram channel config (user's bot)
  telegram:
    enabled: true
    token: ${TELEGRAM_BOT_TOKEN}  # Read from environment variable
    
  # WhatsApp channel config
  whatsapp:
    enabled: false
    # WhatsApp uses Baileys, requires QR scan on first use
    
  # Feishu channel config
  feishu:
    enabled: false
    appId: ""
    appSecret: ""

llm:
  # LLM config
  provider: openai  # openai | anthropic | local
  apiKey: ${LLM_API_KEY}
  model: gpt-4

# Freqtrade config path
freqtrade:
  configPath: /app/user_data/config.json
  userDataDir: /app/user_data
```

### 8.6 Environment Variables File

**Source**: design_en.md Section 6.2.4

```bash
# ~/.cryptoclaw/config/.env
# Sensitive info via environment variables

# Telegram Bot Token (user's bot)
TELEGRAM_BOT_TOKEN=123456789:ABCdefGHIjklMNOpqrsTUVwxyz

# LLM API Key
LLM_API_KEY=sk-xxxx
LLM_PROVIDER=openai

# Exchange API Keys (optional, can also configure via desktop client)
BINANCE_API_KEY=xxx
BINANCE_API_SECRET=xxx
```

### 8.7 Configuration Wizard Script

**Source**: design_en.md Section 6.2.4

```bash
#!/bin/bash
# init-config.sh - First-run configuration wizard

CONFIG_DIR=~/.cryptoclaw/config

echo "🔧 CryptoQClaw Configuration Wizard"
echo "==================================="
echo ""

# Create config directory
mkdir -p "$CONFIG_DIR"

# Check for existing config
if [ -f "$CONFIG_DIR/.env" ]; then
    echo "⚠️  Existing config detected, reconfigure? (y/n)"
    read -r answer
    if [ "$answer" != "y" ]; then
        echo "Using existing config"
        exit 0
    fi
fi

# Configure Telegram Bot
echo ""
echo "📱 Telegram Bot Configuration"
echo "-----------------------------"
echo "Follow these steps to get your Bot Token:"
echo "1. Search @BotFather in Telegram"
echo "2. Send /newbot to create a new bot"
echo "3. Follow prompts to set bot name"
echo "4. Copy the token (format: 123456789:ABCdef...)"
echo ""
echo "Enter your Telegram Bot Token:"
read -r TELEGRAM_TOKEN

# Configure LLM
echo ""
echo "🤖 LLM API Configuration"
echo "----------------------"
echo "Select LLM provider:"
echo "1) OpenAI (recommended)"
echo "2) Anthropic Claude"
echo "3) Local model (skip)"
read -r llm_choice

case $llm_choice in
    1)
        echo "Enter OpenAI API Key (sk-...):"
        read -r LLM_KEY
        LLM_PROVIDER="openai"
        ;;
    2)
        echo "Enter Anthropic API Key (sk-ant-...):"
        read -r LLM_KEY
        LLM_PROVIDER="anthropic"
        ;;
    3)
        echo "Will use local model"
        LLM_KEY=""
        LLM_PROVIDER="local"
        ;;
    *)
        echo "Invalid choice, skipping LLM config"
        LLM_KEY=""
        LLM_PROVIDER=""
        ;;
esac

# Write .env file
cat > "$CONFIG_DIR/.env" << EOF
# CryptoQClaw Environment Variables
# Generated: $(date)

# Telegram Bot Token
TELEGRAM_BOT_TOKEN=$TELEGRAM_TOKEN

# LLM Configuration
LLM_PROVIDER=$LLM_PROVIDER
LLM_API_KEY=$LLM_KEY
EOF

# Generate openclaw.yaml config
cat > "$CONFIG_DIR/openclaw.yaml" << EOF
# OpenClaw Configuration File
gateway:
  name: cryptoclaw
  port: 8080

channels:
  telegram:
    enabled: true
    token: \${TELEGRAM_BOT_TOKEN}
  whatsapp:
    enabled: false
  feishu:
    enabled: false

llm:
  provider: \${LLM_PROVIDER}
  apiKey: \${LLM_API_KEY}
  model: gpt-4

freqtrade:
  configPath: /app/user_data/config.json
  userDataDir: /app/user_data
EOF

# Set file permissions
chmod 600 "$CONFIG_DIR/.env"

echo ""
echo "✅ Configuration complete!"
echo ""
echo "Config files located at:"
echo "  - $CONFIG_DIR/.env (sensitive info)"
echo "  - $CONFIG_DIR/openclaw.yaml (OpenClaw config)"
echo ""
echo "Now start the service:"
echo "  ~/.cryptoclaw/start.sh"
echo ""
```

### 8.8 Desktop Client Configuration Manager

**Source**: design_en.md Section 6.2.5

```typescript
// Desktop Client Config Manager
import * as os from 'os';
import * as path from 'path';
import * as fs from 'fs/promises';
import * as dotenv from 'dotenv';
import * as yaml from 'yaml';
import { execSync } from 'child_process';

interface CryptoQClawConfig {
  env: Record<string, string>;
  openclaw: any;
}

class ConfigManager {
  private configDir: string;
  
  constructor() {
    this.configDir = path.join(os.homedir(), '.cryptoclaw', 'config');
  }
  
  // Load configuration
  async loadConfig(): Promise<CryptoQClawConfig> {
    const envPath = path.join(this.configDir, '.env');
    const yamlPath = path.join(this.configDir, 'openclaw.yaml');
    
    // Read .env file
    const envConfig = dotenv.parse(await fs.readFile(envPath));
    
    // Read yaml file
    const yamlConfig = yaml.parse(await fs.readFile(yamlPath, 'utf8'));
    
    return { env: envConfig, openclaw: yamlConfig };
  }
  
  // Save configuration
  async saveConfig(config: Partial<CryptoQClawConfig>): Promise<void> {
    // Write .env
    if (config.env) {
      const envContent = Object.entries(config.env)
        .map(([k, v]) => `${k}=${v}`)
        .join('\n');
      await fs.writeFile(
        path.join(this.configDir, '.env'),
        envContent,
        { mode: 0o600 }  // Owner read/write only
      );
    }
    
    // Write yaml
    if (config.openclaw) {
      await fs.writeFile(
        path.join(this.configDir, 'openclaw.yaml'),
        yaml.stringify(config.openclaw)
      );
    }
    
    // Restart container to apply config
    await this.restartContainer();
  }
  
  // Restart container
  async restartContainer(): Promise<void> {
    execSync('docker restart cryptoclaw');
  }
}

// Telegram Token Verification
async function verifyTelegramToken(token: string): Promise<boolean> {
  try {
    const response = await fetch(
      `https://api.telegram.org/bot${token}/getMe`
    );
    const data = await response.json();
    return data.ok === true;
  } catch {
    return false;
  }
}

// OpenAI API Key Verification
async function verifyOpenAIKey(apiKey: string): Promise<boolean> {
  try {
    const response = await fetch('https://api.openai.com/v1/models', {
      headers: { 'Authorization': `Bearer ${apiKey}` }
    });
    return response.ok;
  } catch {
    return false;
  }
}
```

### 8.9 Update Script

**Source**: design_en.md Section 6.4.2

```bash
#!/bin/bash
# update.sh - CryptoQClaw update script

echo "🔄 Checking for updates..."

# Get current version
CURRENT=$(docker exec cryptoclaw cat /app/VERSION 2>/dev/null || echo "unknown")

# Get latest version
LATEST=$(curl -s https://api.cryptoclaw.pro/updates/latest | jq -r '.version')

if [ "$CURRENT" != "$LATEST" ]; then
    echo "📦 New version available: $LATEST (current: $CURRENT)"
    echo "Updating..."
    
    # Pull new image
    docker pull cryptoclaw/cryptoclaw:$LATEST
    
    # Stop old container
    docker stop cryptoclaw
    docker rm cryptoclaw
    
    # Start new container (using same config)
    ~/.cryptoclaw/start.sh
    
    echo "✅ Update complete!"
else
    echo "✅ Already on latest version: $CURRENT"
fi
```

### 8.10 Version Rollback Script

**Source**: design_en.md Section 6.4.3

```bash
#!/bin/bash
# rollback.sh - Version rollback script

VERSION=$1

if [ -z "$VERSION" ]; then
    echo "Usage: ./rollback.sh <version>"
    echo "Available versions:"
    curl -s https://api.cryptoclaw.pro/updates/versions | jq -r '.[]'
    exit 1
fi

echo "🔄 Rolling back to version $VERSION..."

docker stop cryptoclaw
docker rm cryptoclaw
docker pull cryptoclaw/cryptoclaw:$VERSION

# Update start script to use specified version
sed -i "s/cryptoclaw\/cryptoclaw:latest/cryptoclaw\/cryptoclaw:$VERSION/" ~/.cryptoclaw/start.sh

~/.cryptoclaw/start.sh

echo "✅ Rolled back to version $VERSION"
```

---

## Changelog

| Date | Version | Description |
|------|------|------|
| 2026-03-17 | v1.0 | Extracted all code blocks from requirement.md v6.0 |
| 2026-03-18 | v1.1 | Added update API, architecture diagrams, deployment config |
| 2026-03-18 | v1.2 | English translation |
| 2026-03-18 | v1.3 | Migrated installation & deployment code from design.md |

---

*Maintained by CryptoQClaw Team*
*Last Updated: 2026-03-18*
