#!/bin/bash
# CryptoClaw 数据库初始化脚本
# 参考: technical-spec.md - 1. 数据库 Schema

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置目录
CONFIG_DIR="${CONFIG_DIR:-$HOME/.cryptoclaw}"
DB_FILE="$CONFIG_DIR/cryptoclaw.db"

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

# 创建数据库目录
mkdir -p "$CONFIG_DIR"

# 初始化 SQLite 数据库
init_database() {
    log_info "初始化 CryptoClaw 数据库..."
    
    sqlite3 "$DB_FILE" << 'EOF'
-- 本地配置（加密）
CREATE TABLE IF NOT EXISTS config (
    key TEXT PRIMARY KEY,
    value TEXT  -- 加密存储
);

-- 用户信息
CREATE TABLE IF NOT EXISTS user (
    id TEXT PRIMARY KEY,
    email TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- API Key（加密存储）
CREATE TABLE IF NOT EXISTS api_keys (
    id INTEGER PRIMARY KEY,
    provider TEXT NOT NULL,  -- openai, anthropic, binance, okx
    key_name TEXT,
    encrypted_key BLOB NOT NULL,  -- AES-256 加密
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 交易记录
CREATE TABLE IF NOT EXISTS trades (
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

-- 高水位记录
CREATE TABLE IF NOT EXISTS watermarks (
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

-- 策略配置
CREATE TABLE IF NOT EXISTS strategies (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    code TEXT NOT NULL,  -- Python 策略代码
    config TEXT NOT NULL,  -- JSON 配置
    enabled INTEGER DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 支付记录
CREATE TABLE IF NOT EXISTS payments (
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

-- 收费规则同意记录
CREATE TABLE IF NOT EXISTS fee_agreements (
    id INTEGER PRIMARY KEY,
    user_id TEXT NOT NULL,
    rule_version TEXT NOT NULL,
    agreed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    client_signature TEXT,
    UNIQUE(user_id, rule_version)
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_trades_pair ON trades(pair);
CREATE INDEX IF NOT EXISTS idx_trades_timestamp ON trades(timestamp);
CREATE INDEX IF NOT EXISTS idx_watermarks_month ON watermarks(month);
CREATE INDEX IF NOT EXISTS idx_payments_month ON payments(month);

-- 插入默认配置
INSERT OR IGNORE INTO config (key, value) VALUES 
    ('version', '1.0.0'),
    ('fee_rate', '0.10'),
    ('currency', 'USDT');
EOF

    log_success "数据库初始化完成: $DB_FILE"
}

# 验证数据库
verify_database() {
    log_info "验证数据库结构..."
    
    # 检查表是否存在
    TABLES=$(sqlite3 "$DB_FILE" "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;")
    EXPECTED_TABLES="api_keys config fee_agreements payments strategies trades user watermarks"
    
    for table in $EXPECTED_TABLES; do
        if echo "$TABLES" | grep -q "^$table$"; then
            echo "  ✓ 表 $table 存在"
        else
            echo "  ✗ 表 $table 缺失"
            return 1
        fi
    done
    
    log_success "数据库结构验证通过"
}

# 主函数
main() {
    echo "CryptoClaw 数据库初始化"
    echo "======================="
    echo ""
    
    init_database
    verify_database
    
    echo ""
    echo "数据库文件: $DB_FILE"
    echo "大小: $(ls -lh "$DB_FILE" | awk '{print $5}')"
}

main "$@"
