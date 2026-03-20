#!/bin/bash
#
# DeFiLlama API 客户端脚本
# 用于查询 TVL、协议数据、收益池等
#
# 使用方法:
#   ./defillama.sh tvl                  # 获取总 TVL
#   ./defillama.sh chains               # 获取所有链 TVL
#   ./defillama.sh protocol uniswap     # 获取协议数据
#   ./defillama.sh yields               # 获取收益池
#

set -e

# 配置
API_URL="${DEFILLAMA_API_URL:-https://api.llama.fi}"
YIELDS_URL="${DEFILLAMA_YIELDS_URL:-https://yields.llama.fi}"
STABLECOINS_URL="${DEFILLAMA_STABLECOINS_URL:-https://stablecoins.llama.fi}"

CURL="curl -s"

# 帮助信息
show_help() {
  echo "DeFiLlama API 客户端"
  echo ""
  echo "用法: $0 <命令> [参数]"
  echo ""
  echo "TVL 命令:"
  echo "  tvl                      获取总 TVL"
  echo "  chains                   获取所有链 TVL"
  echo "  chain <name>             获取指定链 TVL 历史"
  echo "  protocols                获取所有协议"
  echo "  protocol <name>          获取协议详情"
  echo ""
  echo "收益命令:"
  echo "  yields                   获取所有收益池"
  echo "  yield <pool>             获取池子详情"
  echo "  pools <token>            获取代币相关池子"
  echo ""
  echo "稳定币命令:"
  echo "  stablecoins              获取所有稳定币"
  echo "  stablecoin <symbol>      获取稳定币详情"
  echo ""
  echo "示例:"
  echo "  $0 chains | jq '.[:5]'"
  echo "  $0 protocol aave | jq '.tvl'"
  echo "  $0 yields | jq 'sort_by(-.apy) | .[:10]'"
}

# 获取总 TVL
get_tvl() {
  $CURL "$API_URL/tvl" | jq '.'
}

# 获取所有链
get_chains() {
  $CURL "$API_URL/v2/chains" | jq '.'
}

# 获取指定链历史
get_chain() {
  local name="$1"
  if [ -z "$name" ]; then
    echo "错误: 请指定链名称"
    exit 1
  fi
  $CURL "$API_URL/v2/historicalChainTvl/$name" | jq '.'
}

# 获取所有协议
get_protocols() {
  $CURL "$API_URL/v2/protocols" | jq '.'
}

# 获取协议详情
get_protocol() {
  local name="$1"
  if [ -z "$name" ]; then
    echo "错误: 请指定协议名称"
    exit 1
  fi
  $CURL "$API_URL/protocol/$name" | jq '.'
}

# 获取所有收益池
get_yields() {
  $CURL "$YIELDS_URL/pools" | jq '.data'
}

# 获取池子详情
get_yield() {
  local pool="$1"
  if [ -z "$pool" ]; then
    echo "错误: 请指定池子"
    exit 1
  fi
  $CURL "$YIELDS_URL/chart/$pool" | jq '.'
}

# 获取代币相关池子
get_pools_by_token() {
  local token="$1"
  if [ -z "$token" ]; then
    echo "错误: 请指定代币"
    exit 1
  fi
  $CURL "$YIELDS_URL/pools" | jq --arg token "$token" '.data[] | select(.symbol | contains($token))'
}

# 获取稳定币列表
get_stablecoins() {
  $CURL "$STABLECOINS_URL/stablecoins" | jq '.'
}

# 获取稳定币详情
get_stablecoin() {
  local symbol="$1"
  if [ -z "$symbol" ]; then
    echo "错误: 请指定稳定币符号"
    exit 1
  fi
  $CURL "$STABLECOINS_URL/stablecoin/$symbol" | jq '.'
}

# 主命令处理
case "${1:-}" in
  tvl)
    get_tvl
    ;;
  chains)
    get_chains
    ;;
  chain)
    get_chain "$2"
    ;;
  protocols)
    get_protocols
    ;;
  protocol)
    get_protocol "$2"
    ;;
  yields)
    get_yields
    ;;
  yield)
    get_yield "$2"
    ;;
  pools)
    get_pools_by_token "$2"
    ;;
  stablecoins)
    get_stablecoins
    ;;
  stablecoin)
    get_stablecoin "$2"
    ;;
  -h|--help|help)
    show_help
    ;;
  *)
    show_help
    exit 1
    ;;
esac
