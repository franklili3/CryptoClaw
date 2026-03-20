#!/bin/bash
#
# Hyperliquid API 客户端脚本
# 用于查询行情、账户信息、执行交易
#
# 使用方法:
#   ./hyperliquid.sh meta              # 获取所有交易对信息
#   ./hyperliquid.sh price BTC         # 获取 BTC 价格
#   ./hyperliquid.sh funding BTC       # 获取 BTC 资金费率
#

set -e

# 配置
API_URL="${HYPERLIQUID_API_URL:-https://api.hyperliquid.xyz}"
PROXY="${https_proxy:-}"

# curl 命令
if [ -n "$PROXY" ]; then
  CURL="curl -s -x $PROXY"
else
  CURL="curl -s"
fi

# 帮助信息
show_help() {
  echo "Hyperliquid API 客户端"
  echo ""
  echo "用法: $0 <命令> [参数]"
  echo ""
  echo "查询命令:"
  echo "  meta                    获取所有交易对元数据"
  echo "  price <coin>            获取指定币种价格"
  echo "  funding <coin>          获取资金费率"
  echo "  orderbook <coin>        获取订单簿"
  echo "  candles <coin> <intv>   获取K线 (intv: 1m, 5m, 1h, 1d)"
  echo ""
  echo "账户命令 (需要认证):"
  echo "  balance <address>       查询账户余额"
  echo "  positions <address>     查询持仓"
  echo "  orders <address>        查询订单"
  echo ""
  echo "示例:"
  echo "  $0 price BTC"
  echo "  $0 funding ETH"
  echo "  $0 candles BTC 1h"
  echo ""
  echo "环境变量:"
  echo "  HYPERLIQUID_API_URL     API 地址 (默认: https://api.hyperliquid.xyz)"
  echo "  https_proxy             代理地址 (如: http://127.0.0.1:7890)"
}

# 获取元数据
get_meta() {
  $CURL -X POST "$API_URL/info" \
    -H "Content-Type: application/json" \
    -d '{"type": "meta"}'
}

# 获取价格
get_price() {
  local coin="$1"
  if [ -z "$coin" ]; then
    echo "错误: 请指定币种"
    exit 1
  fi

  $CURL -X POST "$API_URL/info" \
    -H "Content-Type: application/json" \
    -d "{\"type\": \"allMids\"}" | jq -r ".\"$coin\" // ."
}

# 获取资金费率
get_funding() {
  local coin="$1"
  if [ -z "$coin" ]; then
    echo "错误: 请指定币种"
    exit 1
  fi

  $CURL -X POST "$API_URL/info" \
    -H "Content-Type: application/json" \
    -d '{"type": "metaAndAssetCtxs"}' | jq ".[0][] | select(.coin == \"$coin\") | .funding"
}

# 获取订单簿
get_orderbook() {
  local coin="$1"
  if [ -z "$coin" ]; then
    echo "错误: 请指定币种"
    exit 1
  fi

  $CURL -X POST "$API_URL/info" \
    -H "Content-Type: application/json" \
    -d "{\"type\": \"l2Book\", \"coin\": \"$coin\"}"
}

# 获取K线
get_candles() {
  local coin="$1"
  local interval="$2"

  if [ -z "$coin" ] || [ -z "$interval" ]; then
    echo "错误: 请指定币种和时间间隔"
    exit 1
  fi

  # 转换时间间隔
  local interval_ms
  case "$interval" in
    "1m") interval_ms=60000 ;;
    "5m") interval_ms=300000 ;;
    "15m") interval_ms=900000 ;;
    "1h") interval_ms=3600000 ;;
    "4h") interval_ms=14400000 ;;
    "1d") interval_ms=86400000 ;;
    *) interval_ms="$interval" ;;
  esac

  local end_time=$(($(date +%s) * 1000))
  local start_time=$((end_time - 24 * 60 * 60 * 1000)) # 24小时前

  $CURL -X POST "$API_URL/info" \
    -H "Content-Type: application/json" \
    -d "{
      \"type\": \"candleSnapshot\",
      \"req\": {
        \"coin\": \"$coin\",
        \"interval\": $interval_ms,
        \"startTime\": $start_time,
        \"endTime\": $end_time
      }
    }"
}

# 获取账户余额
get_balance() {
  local address="$1"
  if [ -z "$address" ]; then
    echo "错误: 请指定钱包地址"
    exit 1
  fi

  $CURL -X POST "$API_URL/info" \
    -H "Content-Type: application/json" \
    -d "{\"type\": \"clearinghouseState\", \"user\": \"$address\"}"
}

# 获取持仓
get_positions() {
  local address="$1"
  if [ -z "$address" ]; then
    echo "错误: 请指定钱包地址"
    exit 1
  fi

  $CURL -X POST "$API_URL/info" \
    -H "Content-Type: application/json" \
    -d "{\"type\": \"clearinghouseState\", \"user\": \"$address\"}" | \
    jq '.assetPositions[]'
}

# 获取订单
get_orders() {
  local address="$1"
  if [ -z "$address" ]; then
    echo "错误: 请指定钱包地址"
    exit 1
  fi

  $CURL -X POST "$API_URL/info" \
    -H "Content-Type: application/json" \
    -d "{\"type\": \"openOrders\", \"user\": \"$address\"}"
}

# 主命令处理
case "${1:-}" in
  meta)
    get_meta
    ;;
  price)
    get_price "$2"
    ;;
  funding)
    get_funding "$2"
    ;;
  orderbook)
    get_orderbook "$2"
    ;;
  candles)
    get_candles "$2" "$3"
    ;;
  balance)
    get_balance "$2"
    ;;
  positions)
    get_positions "$2"
    ;;
  orders)
    get_orders "$2"
    ;;
  -h|--help|help)
    show_help
    ;;
  *)
    show_help
    exit 1
    ;;
esac
