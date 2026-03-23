# CryptoQClaw - 技术规范文档

> 本文档从产品需求文档 (requirement.md) 中提取的所有代码块，按类别组织

---

## 目录

- [1. 数据库 Schema (SQL)](#1-数据库-schema-sql)
- [2. API 数据结构 (JSON)](#2-api-数据结构-json)
- [3. 客户端代码 (JavaScript/TypeScript)](#3-客户端代码-javascripttypescript)
- [4. 后端代码 (Python)](#4-后端代码-python)
- [5. 配置文件 (JSON)](#5-配置文件-json)

---

## 1. 数据库 Schema (SQL)

### 1.1 收费规则同意记录（服务端）

**来源**: Section 2.2 - 收费规则同意流程

**描述**: 存储用户对收费规则的同意记录，用于实盘交易前的合规确认。

```sql
-- 收费规则同意记录（服务端）
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

### 1.2 支付订单（服务端）

**来源**: Section 2.4 - 支付与核对流程

**描述**: 服务端存储的支付订单信息，记录账单对应的支付详情。

```sql
-- 支付订单（服务端）
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

### 1.3 支付记录（服务端）

**来源**: Section 2.4 - 支付与核对流程

**描述**: 服务端存储的链上支付确认记录。

```sql
-- 支付记录（服务端）
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

### 1.4 本地配置（客户端 SQLite）

**来源**: Section 7.1 - 客户端本地数据

**描述**: 客户端本地存储的加密配置信息。

```sql
-- 本地配置（加密）
CREATE TABLE config (
  key TEXT PRIMARY KEY,
  value TEXT  -- 加密存储
);
```

### 1.5 用户信息（客户端 SQLite）

**来源**: Section 7.1 - 客户端本地数据

**描述**: 客户端本地存储的用户基本信息。

```sql
-- 用户信息
CREATE TABLE user (
  id TEXT PRIMARY KEY,
  email TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### 1.6 API Key（客户端 SQLite，加密存储）

**来源**: Section 7.1 - 客户端本地数据

**描述**: 客户端本地加密存储的各类 API Key。

```sql
-- API Key（加密存储）
CREATE TABLE api_keys (
  id INTEGER PRIMARY KEY,
  provider TEXT NOT NULL,  -- openai, anthropic, binance, okx
  key_name TEXT,
  encrypted_key BLOB NOT NULL,  -- AES-256 加密
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### 1.7 交易记录（客户端 SQLite）

**来源**: Section 7.1 - 客户端本地数据

**描述**: 客户端本地存储的所有交易记录。

```sql
-- 交易记录
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

### 1.8 高水位记录（客户端 SQLite）

**来源**: Section 7.1 - 客户端本地数据

**描述**: 客户端本地存储的高水位计费记录。

```sql
-- 高水位记录
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
  tx_hash TEXT  -- 支付交易哈希
);
```

### 1.9 策略配置（客户端 SQLite）

**来源**: Section 7.1 - 客户端本地数据

**描述**: 客户端本地存储的策略代码和配置。

```sql
-- 策略配置
CREATE TABLE strategies (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  code TEXT NOT NULL,  -- Python 策略代码
  config TEXT NOT NULL,  -- JSON 配置
  enabled INTEGER DEFAULT 1,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### 1.10 支付记录（客户端 SQLite）

**来源**: Section 7.1 - 客户端本地数据

**描述**: 客户端本地存储的支付记录。

```sql
-- 支付记录
CREATE TABLE payments (
  id INTEGER PRIMARY KEY,
  month TEXT NOT NULL,  -- 对应哪个月的账单
  amount REAL NOT NULL,
  currency TEXT NOT NULL,  -- USDT, USDC
  chain TEXT NOT NULL,  -- TRC20, ERC20
  address TEXT NOT NULL,  -- 支付地址
  tx_hash TEXT,  -- 链上交易哈希
  status TEXT DEFAULT 'pending',  -- pending, confirmed
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  confirmed_at DATETIME
);
```

### 1.11 云服务用户信息（服务端）

**来源**: Section 7.2 - 云服务数据

**描述**: 服务端存储的用户基本信息。

```sql
-- 用户信息
CREATE TABLE user (
  id TEXT PRIMARY KEY,
  email TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### 1.12 云服务收费规则同意记录（服务端）

**来源**: Section 7.2 - 云服务数据

**描述**: 服务端存储的收费规则同意记录（与 1.1 相同，这里强调是云服务数据）。

```sql
-- 收费规则同意记录
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

### 1.13 用户确认的账单记录（服务端）

**来源**: Section 7.2 - 云服务数据

**描述**: 服务端存储的用户已确认的账单摘要数据。

```sql
-- 用户确认的账单记录
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

### 1.14 支付确认记录（服务端）

**来源**: Section 7.2 - 云服务数据

**描述**: 服务端存储的链上支付确认详情。

```sql
-- 支付确认记录
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

### 1.15 用户支付地址（服务端）

**来源**: Section 7.2 - 云服务数据

**描述**: 服务端存储的用户专属支付地址（HD 钱包派生）。

```sql
-- 用户支付地址（HD钱包派生）
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

## 2. API 数据结构 (JSON)

### 2.1 收费规则同意数据

**来源**: Section 2.2 - 收费规则同意流程

**描述**: 客户端生成并上传到服务器的收费规则同意记录。

```json
{
  "user_id": "xxx",
  "agreed_at": "2026-03-17T09:00:00Z",
  "rule_version": "v1.0",
  "client_signature": "xxx"
}
```

### 2.2 月度账单数据

**来源**: Section 2.3 - 月度计费流程

**描述**: 客户端本地生成的月度账单数据结构。

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

### 2.3 账单上传数据结构

**来源**: Section 2.3 - 月度计费流程

**描述**: 用户确认后上传到服务器的账单摘要数据（不含交易明细）。

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

### 2.4 风控规则配置

**来源**: Section 5.2 - 核心功能清单 (风控系统)

**描述**: 客户端风控系统的配置参数示例。

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

### 2.5 日志格式

**来源**: Section 13.2 - 日志规范

**描述**: 应用日志的标准 JSON 格式。

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

## 3. 客户端代码 (JavaScript/TypeScript)

### 3.1 高水位账单计算类

**来源**: Section 8.2 - 高水位计算（本地）

**描述**: 客户端本地计算月度账单和高水位的核心类。

```javascript
// 客户端本地计算
class BillingCalculator {
  
  /**
   * 计算月度账单
   */
  calculateMonthlyBilling(month) {
    // 1. 从本地数据库获取本月所有交易
    const trades = this.db.query(`
      SELECT * FROM trades 
      WHERE strftime('%Y-%m', timestamp) = ?
      ORDER BY timestamp
    `, [month]);
    
    // 2. 计算累计利润
    const cumulativeProfit = trades.reduce((sum, t) => sum + (t.profit || 0), 0);
    
    // 3. 获取历史高水位
    const lastWatermark = this.db.queryOne(`
      SELECT high_watermark FROM watermarks 
      WHERE month < ? 
      ORDER BY month DESC LIMIT 1
    `, [month]);
    const highWatermark = lastWatermark?.high_watermark || 0;
    
    // 4. 计算可计费利润
    const billableProfit = Math.max(0, cumulativeProfit - highWatermark);
    
    // 5. 计算费用 (10%)
    const fee = billableProfit * 0.10;
    
    // 6. 更新高水位
    const newHighWatermark = Math.max(highWatermark, cumulativeProfit);
    
    // 7. 保存到本地数据库
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
   * 获取所有历史账单
   */
  getAllBillings() {
    return this.db.query(`
      SELECT * FROM watermarks ORDER BY month
    `);
  }
}
```

### 3.2 支付地址管理

**来源**: Section 9.4 - 支付地址管理

**描述**: 固定收款地址配置和用户专属地址派生函数。

```javascript
// 固定收款地址（简单方案）
const PAYMENT_ADDRESSES = {
  'USDT-TRC20': 'TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t',
  'USDT-ERC20': '0x742d35Cc6634C0532925a3b844Bc9e7595f8bDe2',
  'USDC-TRC20': 'TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t',
  'USDC-ERC20': '0x742d35Cc6634C0532925a3b844Bc9e7595f8bDe2'
};

// 可选：用户专属地址（HD钱包派生）
function getUserPaymentAddress(userId, currency, chain) {
  // 使用主钱包的 xpub 派生子地址
  const path = `m/44'/${coinType}'/${userId}'/0/0`;
  const address = deriveAddress(masterXpub, path);
  return address;
}
```

### 3.3 服务端链上支付监控系统

**来源**: Section 9.5 - 服务器链上监控（核心功能）

**描述**: 服务端监控链上支付并自动核对的服务类。

```javascript
// 服务端链上监控系统
class PaymentMonitor {
  
  constructor() {
    this.tronGridClient = new TronGridClient(TRONGRID_API_KEY);
    this.etherscanClient = new EtherscanClient(ETHERSCAN_API_KEY);
  }
  
  /**
   * 启动监控任务
   */
  async startMonitoring() {
    
    // 使用 WebSocket 实时监听
    this.startWebSocketListener();
  }
  
  /**
   * 检查待确认支付
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
   * 检查单个订单的支付情况
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
    
    // 核对交易
    for (const tx of transactions) {
      if (this.verifyTransaction(tx, order)) {
        await this.confirmPayment(order, tx);
        break;
      }
    }
  }
  
  /**
   * 验证交易
   */
  verifyTransaction(tx, order) {
    // 核对地址
    if (tx.to.toLowerCase() !== order.payment_address.toLowerCase()) {
      return false;
    }
    
    // 核对金额（允许1%误差，应对精度问题）
    const expectedAmount = order.amount;
    const actualAmount = parseFloat(tx.value) / 1e6;  // USDT 6 decimals
    if (actualAmount < expectedAmount * 0.99) {
      return false;
    }
    
    // 核对确认数
    if (tx.confirmations < MIN_CONFIRMATIONS) {
      return false;
    }
    
    return true;
  }
  
  /**
   * 确认支付
   */
  async confirmPayment(order, tx) {
    await db.transaction(async (conn) => {
      // 更新支付订单状态
      await conn.query(`
        UPDATE payment_orders 
        SET status = 'paid', paid_at = NOW()
        WHERE id = ?
      `, [order.id]);
      
      // 记录支付详情
      await conn.query(`
        INSERT INTO payment_confirmations 
        (bill_id, user_id, tx_hash, amount, currency, chain, 
         from_address, to_address, status, confirmed_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'confirmed', NOW())
      `, [order.bill_id, order.user_id, tx.hash, 
          tx.value / 1e6, order.currency, order.chain,
          tx.from, tx.to]);
      
      // 更新账单状态
      await conn.query(`
        UPDATE confirmed_bills 
        SET status = 'paid'
        WHERE bill_id = ?
      `, [order.bill_id]);
      
      // 通知用户
      await this.notifyUser(order.user_id, {
        type: 'payment_confirmed',
        bill_id: order.bill_id,
        amount: order.amount
      });
    });
  }
}
```

### 3.4 账单确认上传客户端

**来源**: Section 9.6 - 账单确认上传机制

**描述**: 客户端账单确认并上传到服务器的类。

```javascript
// 客户端账单确认上传
class BillingUploader {
  
  /**
   * 用户确认账单并上传
   */
  async confirmAndUpload(monthBilling) {
    // 1. 用户在界面上确认账单
    const userConfirmed = await this.showBillingConfirmation(monthBilling);
    if (!userConfirmed) {
      return { success: false, reason: 'user_cancelled' };
    }
    
    // 2. 准备上传数据（不含交易明细）
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
    
    // 3. 生成客户端签名
    const signature = this.signData(uploadData);
    uploadData.client_signature = signature;
    
    // 4. 上传至服务器
    try {
      const response = await fetch('/api/billing/confirm', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(uploadData)
      });
      
      const result = await response.json();
      
      if (result.success) {
        // 5. 保存服务器返回的支付信息
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
      // 网络失败，稍后重试
      this.queueForRetry(uploadData);
      return { success: false, reason: 'network_error' };
    }
  }
  
  /**
   * 签名数据
   */
  signData(data) {
    const message = JSON.stringify(data);
    const hmac = crypto.createHmac('sha256', this.getClientSecret());
    hmac.update(message);
    return hmac.digest('hex');
  }
}
```

### 3.5 本地数据加密

**来源**: Section 10.4 - 本地数据安全

**描述**: 客户端本地数据加密和解密的实现。

```javascript
// 本地数据加密
class LocalDataSecurity {
  
  /**
   * 使用用户密码派生的密钥加密敏感数据
   */
  encryptData(plaintext, userPassword) {
    // 从密码派生密钥
    const key = this.deriveKey(userPassword);
    
    // AES-256-GCM 加密
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
   * 解密本地数据
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

### 3.6 客户端用户注册/登录

**来源**: Section 11.8 - 技术实现要点

**描述**: Electron 客户端中嵌入用户认证的实现。

```javascript
// Electron 中嵌入用户注册/登录页面
async function openAuth(mode = 'login') {
  // 打开认证窗口（内嵌浏览器）
  const authWindow = new BrowserWindow({
    width: 450,
    height: 600,
    title: mode === 'login' ? '登录' : '注册',
    resizable: false,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true
    }
  });
  
  // 加载认证页面（云端托管）
  authWindow.loadURL(`https://auth.quantagent.pro/${mode}`);
  
  // 监听认证完成事件
  ipcMain.on('auth-complete', async (event, result) => {
    if (result.success) {
      // 保存用户信息到本地（不含敏感信息）
      await localDB.saveUserInfo({
        userId: result.userId,
        email: result.email,
        supabaseKey: result.supabaseKey  // 服务端下发的 API Key
      });
      
      // 通知渠道端绑定用户
      await notifyChannelBinding(result.userId);
    }
    authWindow.close();
  });
  
  // 监听窗口关闭
  authWindow.on('closed', () => {
    authWindow = null;
  });
}

// 检查登录状态
async function checkAuthStatus() {
  const userInfo = await localDB.getUserInfo();
  if (!userInfo) {
    // 未登录，打开登录窗口
    return openAuth('login');
  }
  
  // 验证 Supabase Key 是否有效
  const isValid = await verifySupabaseKey(userInfo.supabaseKey);
  if (!isValid) {
    // Key 已失效（可能逾期未支付），提示用户
    dialog.showMessageBox({
      type: 'warning',
      title: '账户状态异常',
      message: '您的账户可能已逾期，请检查支付状态',
      buttons: ['查看账单', '稍后处理']
    }).then(result => {
      if (result.response === 0) {
        // 引导用户到渠道端查看账单
        shell.openExternal('https://t.me/quantagent_bot');
      }
    });
  }
  
  return isValid;
}
```

### 3.7 离线优先数据同步

**来源**: Section 11.8 - 技术实现要点

**描述**: 客户端数据同步策略，支持离线使用。

```javascript
// 数据同步策略
class DataSync {
  async syncBillingData() {
    if (!navigator.onLine) {
      // 离线时使用本地缓存
      return await localDB.getBillingData();
    }
    
    try {
      // 在线时同步云端数据
      const cloudData = await api.fetchBillingData();
      await localDB.saveBillingData(cloudData);
      return cloudData;
    } catch (error) {
      // 网络失败时降级到本地
      return await localDB.getBillingData();
    }
  }
}
```

### 3.8 支付确认客户端

**来源**: Section 10.5 - 支付确认安全

**描述**: 客户端支付确认和链上验证的实现。

```javascript
// 客户端支付确认
class PaymentConfirmation {
  

  async confirmPayment(month, txHash) {
       
    // 1. 验证链上交易
    const verified = await this.verifyOnChain(txHash, month);
    
    // 2. 更新本地订单状态
    this.db.run(`
      UPDATE watermarks 
      SET status = 'paid', paid_at = ?, tx_hash = ?, verified = ?
      WHERE month = ?
    `, [new Date().toISOString(), txHash, verified, month]);
    
    // 3. 通知服务端
    if (verified) {
      await this.notifyServer(month, txHash);
    }
    
    return { success: true, verified };
  }
  
  /**
   * 链上验证
   */
  async verifyOnChain(txHash, month) {
    try {
      // 使用公共 API 查询交易
      const tx = await this.fetchTransaction(txHash);
      const bill = this.getBilling(month);
      
      // 验证金额和收款地址
      return tx.to === PAYMENT_ADDRESS && 
             tx.value >= bill.fee_amount * 1e6;
    } catch {
      // 验证失败不影响用户标记为已支付
      return false;
    }
  }
}
```

---

## 4. 后端代码 (Python)

### 4.1 OpenClaw-Freqtrade 桥接层

**来源**: Section 5.2 - OpenClaw 与 Freqtrade 集成

**描述**: OpenClaw 智能体与 Freqtrade 量化引擎的集成接口。

```python
# 集成层 API (Python)

class OpenClawFreqtradeBridge:
    """OpenClaw 与 Freqtrade 的桥接层"""
    
    def __init__(self, freqtrade_path: str, config_path: str):
        self.freqtrade_path = freqtrade_path
        self.config_path = config_path
    
    async def create_strategy(self, natural_language: str) -> str:
        """
        将自然语言转换为 Freqtrade 策略代码
        
        Args:
            natural_language: 用户描述的策略逻辑
            
        Returns:
            生成的策略文件路径
        """
        # 1. 调用 OpenClaw 理解用户意图
        # 2. 生成 Freqtrade 策略代码
        # 3. 保存到 user_data/strategies/
        # 4. 验证策略语法
        pass
    
    async def run_backtest(self, strategy: str, 
                          timerange: str,
                          stake_amount: float) -> BacktestResult:
        """
        执行回测并返回结果
        
        Args:
            strategy: 策略名称
            timerange: 时间范围 (如 "20240101-20241231")
            stake_amount: 每笔交易金额
            
        Returns:
            回测结果对象
        """
        # 1. 调用 freqtrade backtesting
        # 2. 解析结果 JSON
        # 3. 返回结构化数据
        pass
    
    async def start_trading(self, strategy: str, 
                           dry_run: bool = True) -> str:
        """
        启动实盘/模拟交易
        
        Args:
            strategy: 策略名称
            dry_run: 是否模拟模式
            
        Returns:
            进程 ID
        """
        pass
    
    async def get_trade_status(self) -> TradeStatus:
        """获取当前交易状态"""
        pass
    
    async def stop_trading(self) -> bool:
        """停止交易"""
        pass
```

### 4.2 密钥管理器

**来源**: Section 10.3 - 密钥管理方案

**描述**: 服务端密钥派生和 API Key 加密解密的实现。

```python
import hashlib
import base64
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

class KeyManager:
    """密钥管理器"""
    
    ITERATIONS = 100000
    KEY_LENGTH = 32  # 256 bits
    
    @staticmethod
    def derive_master_key(password: str, salt: bytes) -> bytes:
        """
        从用户密码派生主密钥
        
        Args:
            password: 用户密码
            salt: 随机盐值 (存储在服务端)
            
        Returns:
            256-bit 主密钥
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
        加密 API Key
        
        Returns:
            {
                'ciphertext': base64编码的密文,
                'nonce': base64编码的随机数,
                'tag': base64编码的认证标签
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
        """解密 API Key"""
        nonce = base64.b64decode(encrypted['nonce'])
        ciphertext = base64.b64decode(encrypted['ciphertext'])
        
        aesgcm = AESGCM(master_key)
        plaintext = aesgcm.decrypt(nonce, ciphertext, None)
        
        return plaintext.decode()
```

### 4.3 服务端账单确认接口

**来源**: Section 9.6 - 账单确认上传机制

**描述**: 服务端接收和处理用户确认账单的 API 接口。

```python
# 服务端账单确认接口
@router.post('/api/billing/confirm')
async def confirm_billing(request: BillingConfirmRequest):
    # 1. 验证签名
    if not verify_client_signature(request.dict(), request.client_signature):
        raise HTTPException(400, 'Invalid signature')
    
    # 2. 检查是否已确认
    existing = await db.fetch_one(
        'SELECT id FROM confirmed_bills WHERE user_id = ? AND month = ?',
        request.user_id, request.month
    )
    if existing:
        raise HTTPException(400, 'Bill already confirmed')
    
    # 3. 生成支付地址
    payment_address = await generate_payment_address(
        request.user_id, 
        request.currency
    )
    
    # 4. 保存账单
    await db.execute('''
        INSERT INTO confirmed_bills 
        (bill_id, user_id, month, cumulative_profit, high_watermark, 
         billable_profit, fee_amount, currency, confirmed_at, client_signature, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending')
    ''', request.bill_id, request.user_id, request.month, 
         request.cumulative_profit, request.high_watermark,
         request.billable_profit, request.fee_amount, request.currency,
         request.confirmed_at, request.client_signature)
    
    # 5. 创建支付订单
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

### 4.4 高水位计算单元测试

**来源**: Section 13.2 - 单元测试

**描述**: 高水位计算逻辑的单元测试用例。

```python
# 示例: 高水位计算单元测试
import pytest
from datetime import datetime

class TestHighWatermark:
    
    def test_first_month_profit(self):
        """首月盈利: 全部计费"""
        result = calculate_billing(
            cumulative_profit=500,
            previous_high_watermark=0
        )
        assert result['billable'] == 500
        assert result['fee'] == 50  # 10%
        assert result['new_high_watermark'] == 500
    
    def test_below_high_watermark(self):
        """低于高水位: 不计费"""
        result = calculate_billing(
            cumulative_profit=300,
            previous_high_watermark=500
        )
        assert result['billable'] == 0
        assert result['fee'] == 0
        assert result['new_high_watermark'] == 500  # 保持不变
    
    def test_exceed_high_watermark(self):
        """超过高水位: 只计费超出部分"""
        result = calculate_billing(
            cumulative_profit=700,
            previous_high_watermark=500
        )
        assert result['billable'] == 200
        assert result['fee'] == 20
        assert result['new_high_watermark'] == 700
    
    def test_negative_profit(self):
        """亏损情况: 不计费"""
        result = calculate_billing(
            cumulative_profit=-100,
            previous_high_watermark=500
        )
        assert result['billable'] == 0
        assert result['fee'] == 0
        assert result['new_high_watermark'] == 500
```

---

## 5. 配置文件 (JSON)

### 5.1 CI/CD 发布流程

**来源**: Section 17.4 - CI/CD 流程

**描述**: GitHub Actions 自动化构建和发布配置。

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

### 4.5 自动更新 API

**来源**: Section 8.2 - 自动更新机制

**描述**: 客户端检查和下载软件更新的 API 接口。

```typescript
// 检查更新 API
// GET /api/updates/check?version=1.0.0&platform=darwin

interface UpdateCheckResponse {
  hasUpdate: boolean;
  latestVersion: string;
  forceUpdate: boolean;  // 是否强制更新
  releaseNotes: string;  // Markdown 格式的更新说明
  downloadUrl: string;   // 下载地址
  fileSize: number;      // 文件大小 (bytes)
  checksum: string;      // SHA256 校验和
}

// 示例响应
const response: UpdateCheckResponse = {
  hasUpdate: true,
  latestVersion: "1.2.0",
  forceUpdate: false,
  releaseNotes: "### 新功能\n- 新增 ETH 策略\n- 优化性能",
  downloadUrl: "/api/updates/download/v1.2.0/darwin",
  fileSize: 125829120,
  checksum: "sha256:abc123..."
};
```

---

## 6. 架构图 (ASCII Art)

### 6.1 功能架构图

**来源**: Section 5.1 - 功能架构

```
┌─────────────────────────────────────────────────────────────────┐
│                    用户交互层                                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                 对话渠道 (核心交互)                       │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │   │
│  │  │  Telegram   │  │  WhatsApp   │  │   Web Chat  │      │   │
│  │  │  (主要)     │  │  (主要)     │  │   (备选)    │      │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘      │   │
│  │                                                         │   │
│  │  通过对话完成：                                          │   │
│  │  ✅ 策略编写、数据下载、策略回测                         │   │
│  │  ✅ 模拟交易、实盘交易、交易监控                         │   │
│  │  ✅ 账单对账、计算收费、确认收费                         │   │
│  │  ✅ 二维码支付、支付状态查询                             │   │
│  │  ✅ 风控通知、交易提醒                                   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              ↓                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              桌面客户端 (仅敏感信息管理)                  │   │
│  │  ┌─────────────┐  ┌─────────────┐                       │   │
│  │  │   macOS    │  │   Linux    │                        │   │
│  │  │ (Electron) │  │ (Electron) │                        │   │
│  │  └─────────────┘  └─────────────┘                       │   │
│  │                                                         │   │
│  │  仅管理敏感信息（本地加密存储，永不上传）：               │   │
│  │  🔐 大模型 API Key (OpenAI/Claude/本地)                 │   │
│  │  🔐 交易所 API Key (Binance/OKX)                        │   │
│  │  🔐 用户主密钥（用于本地数据加密）                       │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    后端服务层                                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    智能体系统 (OpenClaw)                  │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │   │
│  │  │ 对话路由    │  │ 意图识别   │  │ 任务执行   │        │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘      │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              ↓                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                  量化引擎 (Freqtrade)                     │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │   │
│  │  │ 数据下载   │  │ 策略回测   │  │ 实盘交易   │        │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘      │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │   │
│  │  │ 参数优化   │  │ 风险分析   │  │ 账单计算   │        │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘      │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              ↓                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    本地服务 (全部离线可用)                │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │   │
│  │  │ 本地存储   │  │ 高水位计算 │  │ 账单生成   │        │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘      │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              ↕
┌─────────────────────────────────────────────────────────────────┐
│                    CryptoQClaw 云服务                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │ 收费规则存档│  │ 账单确认   │  │ 支付监控   │               │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │ 用户认证   │  │ 消息推送   │  │ 软件更新   │               │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
└─────────────────────────────────────────────────────────────────┘
```

### 6.2 高水位机制图

**来源**: Section 2.2 - 分润计费模型

```
高水位原理：
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  利润曲线                                                   │
│     ╭─────╮        ╭──────────────╮ ← 当前高水位          │
│    ╱       ╲      ╱                ╲                        │
│   ╱         ╲____╱                  ╲                       │
│  ╱                                    ╲ ← 当前利润          │
│ ╱                                      ╲                    │
│─────────────────────────────────────────────────────────────│
│                                                             │
│  计费基础 = max(0, 当前累计利润 - 历史最高累计利润)         │
│  应付费用 = 计费基础 × 10%                                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 6.3 安全架构图

**来源**: Section 10.1 - 安全架构

```
┌─────────────────────────────────────────────────────────────┐
│                       安全层级                               │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Layer 1: 传输安全                                          │
│  ├─ 所有通信使用 HTTPS (TLS 1.3)                           │
│  ├─ 证书固定 (Certificate Pinning)                         │
│  └─ API 请求签名验证                                        │
│                                                             │
│  Layer 2: 认证授权                                          │
│  ├─ JWT Token 认证                                          │
│  ├─ Refresh Token 机制                                      │
│  ├─ 设备绑定 (可选)                                         │
│  └─ 多因素认证 (可选)                                       │
│                                                             │
│  Layer 3: 数据加密                                          │
│  ├─ 敏感数据 AES-256-GCM 加密                               │
│  ├─ 密钥派生 PBKDF2 (100,000 iterations)                   │
│  ├─ 本地存储加密 (SQLite 加密)                              │
│  └─ 内存安全 (敏感数据用后即焚)                             │
│                                                             │
│  Layer 4: 业务安全                                          │
│  ├─ 交易上报 HMAC 签名                                      │
│  ├─ 防重放攻击 (Nonce + Timestamp)                         │
│  ├─ 速率限制                                                │
│  └─ 审计日志                                                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 6.4 密钥层次结构图

**来源**: Section 10.3 - 密钥管理方案

```
┌─────────────────────────────────────────────────────────────┐
│                     密钥层次结构                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Level 0: 主密钥 (Master Key)                               │
│  ├─ 由用户密码派生 (PBKDF2)                                 │
│  ├─ 不存储，每次从用户密码重新派生                          │
│  └─ 用于加密 Level 1 密钥                                   │
│                                                             │
│  Level 1: 数据加密密钥 (DEK)                                │
│  ├─ 每个用户一个唯一 DEK                                    │
│  ├─ 由主密钥加密后存储                                      │
│  └─ 用于加密实际数据                                        │
│                                                             │
│  Level 1.5: Supabase Key（服务端下发）                      │
│  ├─ 用户注册/登录后由服务端下发                             │
│  ├─ 用于访问 Supabase 服务                                  │
│  │   • 下载每日交易信号（BTC/ETH 策略）                     │
│  │   • 上传收费规则同意记录                                 │
│  │   • 上传用户确认的账单数据                               │
│  ├─ 存储在客户端本地（加密）                                │
│  ├─ 逾期未支付时服务端禁用该 Key                            │
│  └─ 支付后服务端重新启用该 Key                              │
│                                                             │
│  Level 2: 通信密钥                                          │
│  ├─ HMAC 密钥: 用于请求签名                                 │
│  ├─ Session 密钥: JWT 签名                                  │
│  └─ 定期轮换                                                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 6.5 测试金字塔

**来源**: Section 13.1 - 测试层级

```
┌─────────────────────────────────────────────────────────────┐
│                       测试金字塔                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                     ╱╲                                      │
│                    ╱  ╲                                     │
│                   ╱ E2E╲          10%                       │
│                  ╱──────╲                                   │
│                 ╱ 集成测试 ╲       20%                       │
│                ╱──────────╲                                 │
│               ╱   单元测试   ╲     70%                       │
│              ╱────────────────╲                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 7. 部署配置 (YAML)

### 7.1 CI/CD 发布流程

**来源**: Section 17.4 - CI/CD 流程

**描述**: GitHub Actions 自动化构建和发布配置。

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

## 更新日志

| 日期 | 版本 | 说明 |
|------|------|------|
| 2026-03-17 | v1.0 | 从 requirement.md v6.0 提取所有代码块 |
| 2026-03-18 | v1.1 | 补充更新 API、架构图、部署配置 |
| 2026-03-18 | v1.2 | 从 design.md 迁移安装部署代码 |

---

## 8. Docker 镜像与部署配置

### 8.1 Dockerfile

**来源**: design.md Section 6.2.1

**描述**: CryptoQClaw Docker 镜像构建文件。

```dockerfile
# Dockerfile
FROM python:3.11-slim

# 安装 Node.js (OpenClaw 依赖)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs

# 安装 Freqtrade
RUN pip install freqtrade

# 安装 OpenClaw
RUN npm install -g openclaw

# 创建工作目录
WORKDIR /app

# 复制配置模板
COPY user_data/ /app/user_data/
COPY workspace/ /app/workspace/

# 数据卷挂载点
VOLUME ["/app/user_data", "/app/workspace", "/app/logs"]

# 启动脚本
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
```

### 8.2 一键安装脚本 (macOS/Linux)

**来源**: design.md Section 6.2.2

```bash
#!/bin/bash
# install.sh - CryptoQClaw 一键安装脚本

set -e

echo "🚀 CryptoQClaw 安装程序"
echo "========================"

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo "❌ 未检测到 Docker，正在安装..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install --cask docker
        else
            echo "请先安装 Homebrew: https://brew.sh"
            exit 1
        fi
    elif [[ "$OSTYPE" == "linux"* ]]; then
        # Linux
        curl -fsSL https://get.docker.com | sh
        sudo usermod -aG docker $USER
    fi
fi

# 拉取镜像
echo "📦 正在下载 CryptoQClaw 镜像..."
docker pull cryptoclaw/cryptoclaw:latest

# 创建目录结构
echo "📁 创建工作目录..."
mkdir -p ~/.cryptoclaw/{user_data,workspace,logs,config}

# 下载配置模板
if [ ! -f ~/.cryptoclaw/user_data/config.json ]; then
    echo "⚙️  下载配置模板..."
    curl -fsSL https://raw.githubusercontent.com/franklili3/CryptoQClaw/main/templates/config.json \
        -o ~/.cryptoclaw/user_data/config.json
fi

# 创建启动脚本
cat > ~/.cryptoclaw/start.sh << 'EOF'
#!/bin/bash
cd ~/.cryptoclaw
docker-compose up -d
echo "✅ CryptoQClaw 已启动"
echo "📱 访问 Telegram 搜索您的 Bot 开始使用"
EOF
chmod +x ~/.cryptoclaw/start.sh

# 创建停止脚本
cat > ~/.cryptoclaw/stop.sh << 'EOF'
#!/bin/bash
cd ~/.cryptoclaw
docker-compose down
echo "🛑 CryptoQClaw 已停止"
EOF
chmod +x ~/.cryptoclaw/stop.sh

echo ""
echo "✅ 安装完成！"
echo ""
echo "使用方法："
echo "  启动: ~/.cryptoclaw/start.sh"
echo "  停止: ~/.cryptoclaw/stop.sh"
echo "  配置: ~/.cryptoclaw/config/"
echo ""
```

### 8.3 一键安装脚本 (Windows PowerShell)

**来源**: design.md Section 6.2.2

```powershell
# install.ps1
Write-Host "🚀 CryptoQClaw 安装程序" -ForegroundColor Green

# 检查 Docker
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "❌ 未检测到 Docker Desktop" -ForegroundColor Red
    Write-Host "请先安装: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
    exit 1
}

# 拉取镜像
Write-Host "📦 正在下载 CryptoQClaw 镜像..." -ForegroundColor Cyan
docker pull cryptoclaw/cryptoclaw:latest

# 创建目录
$cryptoclawDir = "$env:USERPROFILE\.cryptoclaw"
New-Item -ItemType Directory -Force -Path "$cryptoclawDir\user_data"
New-Item -ItemType Directory -Force -Path "$cryptoclawDir\workspace"
New-Item -ItemType Directory -Force -Path "$cryptoclawDir\logs"
New-Item -ItemType Directory -Force -Path "$cryptoclawDir\config"

# 下载配置模板
$configUrl = "https://raw.githubusercontent.com/franklili3/CryptoQClaw/main/templates/config.json"
Invoke-WebRequest -Uri $configUrl -OutFile "$cryptoclawDir\user_data\config.json"

Write-Host "✅ 安装完成！" -ForegroundColor Green
Write-Host "运行命令启动: docker-compose -f $cryptoclawDir\config\docker-compose.yml up -d"
```

### 8.4 Docker Compose 配置

**来源**: design.md Section 6.2.3 & 6.2.4

```yaml
# docker-compose.yml
version: '3.8'

services:
  cryptoclaw:
    image: cryptoclaw/cryptoclaw:latest
    container_name: cryptoclaw
    restart: unless-stopped
    
    volumes:
      # Freqtrade 数据目录
      - ~/.cryptoclaw/user_data:/app/user_data
      # OpenClaw 工作区
      - ~/.cryptoclaw/workspace:/app/workspace
      # 日志
      - ~/.cryptoclaw/logs:/app/logs
      # OpenClaw 配置
      - ~/.cryptoclaw/config/openclaw.yaml:/app/config/openclaw.yaml:ro
    
    ports:
      - "8080:8080"  # API Server (可选)
    
    env_file:
      # 从 .env 文件加载环境变量
      - ~/.cryptoclaw/config/.env
    
    environment:
      - TZ=Asia/Shanghai
      - LOG_LEVEL=info
      - OPENCLAW_CONFIG=/app/config/openclaw.yaml
```

### 8.5 OpenClaw 配置文件

**来源**: design.md Section 6.2.4

```yaml
# ~/.cryptoclaw/config/openclaw.yaml
# OpenClaw Gateway 配置

gateway:
  name: cryptoclaw
  port: 8080

channels:
  # Telegram 渠道配置（用户的 Bot）
  telegram:
    enabled: true
    token: ${TELEGRAM_BOT_TOKEN}  # 从环境变量读取
    
  # WhatsApp 渠道配置
  whatsapp:
    enabled: false
    # WhatsApp 使用 Baileys，首次需要扫码绑定
    
  # 飞书渠道配置
  feishu:
    enabled: false
    appId: ""
    appSecret: ""

llm:
  # LLM 配置
  provider: openai  # openai | anthropic | local
  apiKey: ${LLM_API_KEY}
  model: gpt-4

# Freqtrade 配置路径
freqtrade:
  configPath: /app/user_data/config.json
  userDataDir: /app/user_data
```

### 8.6 环境变量文件

**来源**: design.md Section 6.2.4

```bash
# ~/.cryptoclaw/config/.env
# 敏感信息通过环境变量传入

# Telegram Bot Token（用户的 Bot）
TELEGRAM_BOT_TOKEN=123456789:ABCdefGHIjklMNOpqrsTUVwxyz

# LLM API Key
LLM_API_KEY=sk-xxxx
LLM_PROVIDER=openai

# 交易所 API Key（可选，也可通过桌面客户端配置）
BINANCE_API_KEY=xxx
BINANCE_API_SECRET=xxx
```

### 8.7 配置向导脚本

**来源**: design.md Section 6.2.4

```bash
#!/bin/bash
# init-config.sh - 首次运行配置向导

CONFIG_DIR=~/.cryptoclaw/config

echo "🔧 CryptoQClaw 配置向导"
echo "========================"
echo ""

# 创建配置目录
mkdir -p "$CONFIG_DIR"

# 检查是否已有配置
if [ -f "$CONFIG_DIR/.env" ]; then
    echo "⚠️  检测到已有配置，是否重新配置？(y/n)"
    read -r answer
    if [ "$answer" != "y" ]; then
        echo "使用现有配置"
        exit 0
    fi
fi

# 配置 Telegram Bot
echo ""
echo "📱 Telegram Bot 配置"
echo "-------------------"
echo "请按照以下步骤获取 Bot Token:"
echo "1. 在 Telegram 中搜索 @BotFather"
echo "2. 发送 /newbot 创建新 Bot"
echo "3. 按提示设置 Bot 名称"
echo "4. 复制获得的 Token（格式：123456789:ABCdef...）"
echo ""
echo "请输入您的 Telegram Bot Token:"
read -r TELEGRAM_TOKEN

# 配置 LLM
echo ""
echo "🤖 LLM API 配置"
echo "--------------"
echo "请选择 LLM 提供商:"
echo "1) OpenAI (推荐)"
echo "2) Anthropic Claude"
echo "3) 本地模型（跳过）"
read -r llm_choice

case $llm_choice in
    1)
        echo "请输入 OpenAI API Key (sk-...):"
        read -r LLM_KEY
        LLM_PROVIDER="openai"
        ;;
    2)
        echo "请输入 Anthropic API Key (sk-ant-...):"
        read -r LLM_KEY
        LLM_PROVIDER="anthropic"
        ;;
    3)
        echo "将使用本地模型"
        LLM_KEY=""
        LLM_PROVIDER="local"
        ;;
    *)
        echo "无效选择，跳过 LLM 配置"
        LLM_KEY=""
        LLM_PROVIDER=""
        ;;
esac

# 写入 .env 文件
cat > "$CONFIG_DIR/.env" << EOF
# CryptoQClaw 环境变量配置
# 生成时间: $(date)

# Telegram Bot Token
TELEGRAM_BOT_TOKEN=$TELEGRAM_TOKEN

# LLM 配置
LLM_PROVIDER=$LLM_PROVIDER
LLM_API_KEY=$LLM_KEY
EOF

# 生成 openclaw.yaml 配置文件
cat > "$CONFIG_DIR/openclaw.yaml" << EOF
# OpenClaw 配置文件
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

# 设置文件权限
chmod 600 "$CONFIG_DIR/.env"

echo ""
echo "✅ 配置完成！"
echo ""
echo "配置文件位置:"
echo "  - $CONFIG_DIR/.env (敏感信息)"
echo "  - $CONFIG_DIR/openclaw.yaml (OpenClaw 配置)"
echo ""
echo "现在可以启动服务:"
echo "  ~/.cryptoclaw/start.sh"
echo ""
```

### 8.8 桌面客户端配置管理

**来源**: design.md Section 6.2.5

```typescript
// 桌面客户端配置管理
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
  
  // 读取配置
  async loadConfig(): Promise<CryptoQClawConfig> {
    const envPath = path.join(this.configDir, '.env');
    const yamlPath = path.join(this.configDir, 'openclaw.yaml');
    
    // 读取 .env 文件
    const envConfig = dotenv.parse(await fs.readFile(envPath));
    
    // 读取 yaml 文件
    const yamlConfig = yaml.parse(await fs.readFile(yamlPath, 'utf8'));
    
    return { env: envConfig, openclaw: yamlConfig };
  }
  
  // 保存配置
  async saveConfig(config: Partial<CryptoQClawConfig>): Promise<void> {
    // 写入 .env
    if (config.env) {
      const envContent = Object.entries(config.env)
        .map(([k, v]) => `${k}=${v}`)
        .join('\n');
      await fs.writeFile(
        path.join(this.configDir, '.env'),
        envContent,
        { mode: 0o600 }  // 仅所有者可读写
      );
    }
    
    // 写入 yaml
    if (config.openclaw) {
      await fs.writeFile(
        path.join(this.configDir, 'openclaw.yaml'),
        yaml.stringify(config.openclaw)
      );
    }
    
    // 重启容器使配置生效
    await this.restartContainer();
  }
  
  // 重启容器
  async restartContainer(): Promise<void> {
    execSync('docker restart cryptoclaw');
  }
}

// Telegram Token 验证
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

// OpenAI API Key 验证
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

### 8.9 更新脚本

**来源**: design.md Section 6.4.2

```bash
#!/bin/bash
# update.sh - CryptoQClaw 更新脚本

echo "🔄 检查更新..."

# 获取当前版本
CURRENT=$(docker exec cryptoclaw cat /app/VERSION 2>/dev/null || echo "unknown")

# 获取最新版本
LATEST=$(curl -s https://api.cryptoclaw.pro/updates/latest | jq -r '.version')

if [ "$CURRENT" != "$LATEST" ]; then
    echo "📦 发现新版本: $LATEST (当前: $CURRENT)"
    echo "正在更新..."
    
    # 拉取新镜像
    docker pull cryptoclaw/cryptoclaw:$LATEST
    
    # 停止旧容器
    docker stop cryptoclaw
    docker rm cryptoclaw
    
    # 启动新容器（使用相同配置）
    ~/.cryptoclaw/start.sh
    
    echo "✅ 更新完成！"
else
    echo "✅ 已是最新版本: $CURRENT"
fi
```

### 8.10 版本回滚脚本

**来源**: design.md Section 6.4.3

```bash
#!/bin/bash
# rollback.sh - 版本回滚脚本

VERSION=$1

if [ -z "$VERSION" ]; then
    echo "用法: ./rollback.sh <版本号>"
    echo "可用版本:"
    curl -s https://api.cryptoclaw.pro/updates/versions | jq -r '.[]'
    exit 1
fi

echo "🔄 回滚到版本 $VERSION..."

docker stop cryptoclaw
docker rm cryptoclaw
docker pull cryptoclaw/cryptoclaw:$VERSION

# 更新启动脚本使用指定版本
sed -i "s/cryptoclaw\/cryptoclaw:latest/cryptoclaw\/cryptoclaw:$VERSION/" ~/.cryptoclaw/start.sh

~/.cryptoclaw/start.sh

echo "✅ 已回滚到版本 $VERSION"
```

### 8.11 源码运行方案

**来源**: design.md Section 6.5

**环境要求:**

| 组件 | 版本 | 说明 |
|------|------|------|
| Python | 3.11+ | Freqtrade 依赖 |
| Node.js | 20+ | OpenClaw 依赖 |
| Docker | 24+ | 可选，用于容器化 |
| Git | 2.x | 版本控制 |

**快速开始:**

```bash
# 1. 克隆仓库
git clone https://github.com/franklili3/CryptoQClaw.git
cd CryptoQClaw

# 2. 安装依赖
pip install freqtrade
npm install -g openclaw

# 3. 初始化配置
cp templates/config.json user_data/config.json
cp templates/AGENTS.md workspace/AGENTS.md

# 4. 启动服务
./scripts/start.sh
```

### 8.12 安装验证命令

**来源**: design.md Section 6.8

安装完成后，用户可以通过以下方式验证：

```bash
# 检查服务状态
docker ps | grep cryptoclaw

# 检查版本
docker exec cryptoclaw cat /app/VERSION

# 检查日志
docker logs cryptoclaw --tail 100

# 检查 API
curl http://localhost:8080/health

# 测试 Telegram Bot
# 在 Telegram 中搜索您的 Bot，发送 /start
```

---

## 更新日志

| 日期 | 版本 | 说明 |
|------|------|------|
| 2026-03-17 | v1.0 | 从 requirement.md v6.0 提取所有代码块 |
| 2026-03-18 | v1.1 | 补充更新 API、架构图、部署配置 |
| 2026-03-18 | v1.2 | 从 design.md 迁移安装部署代码 |

---

*本文档由 CryptoQClaw 团队维护*
*最后更新: 2026-03-18*
