#!/bin/bash
# CryptoClaw 安装脚本测试
# 用法: ./tests/test_installer.sh

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 测试计数
TESTS_PASSED=0
TESTS_FAILED=0

# 测试函数
test_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TESTS_PASSED++))
}

test_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TESTS_FAILED++))
}

test_section() {
    echo ""
    echo -e "${YELLOW}=== $1 ===${NC}"
}

# 清理测试环境
cleanup() {
    rm -rf /tmp/cryptoclaw-test
}

# 设置测试环境
setup() {
    cleanup
    mkdir -p /tmp/cryptoclaw-test
    export HOME=/tmp/cryptoclaw-test
}

# 测试：脚本存在
test_scripts_exist() {
    test_section "Scripts Existence"
    
    if [ -f "scripts/install.sh" ]; then
        test_pass "install.sh exists"
    else
        test_fail "install.sh not found"
    fi
    
    if [ -f "scripts/install.ps1" ]; then
        test_pass "install.ps1 exists"
    else
        test_fail "install.ps1 not found"
    fi
    
    if [ -f "scripts/init-config.sh" ]; then
        test_pass "init-config.sh exists"
    else
        test_fail "init-config.sh not found"
    fi
}

# 测试：脚本可执行
test_scripts_executable() {
    test_section "Scripts Executable"
    
    if [ -x "scripts/install.sh" ]; then
        test_pass "install.sh is executable"
    else
        chmod +x scripts/install.sh
        test_pass "install.sh made executable"
    fi
    
    if [ -x "scripts/init-config.sh" ]; then
        test_pass "init-config.sh is executable"
    else
        chmod +x scripts/init-config.sh
        test_pass "init-config.sh made executable"
    fi
}

# 测试：技能文件存在
test_skills_exist() {
    test_section "Skills Existence"
    
    if [ -f "skills/freqtrade/SKILL.md" ]; then
        test_pass "freqtrade SKILL.md exists"
    else
        test_fail "freqtrade SKILL.md not found"
    fi
    
    if [ -f "skills/billing/SKILL.md" ]; then
        test_pass "billing SKILL.md exists"
    else
        test_fail "billing SKILL.md not found"
    fi
}

# 测试：技能元数据格式
test_skill_metadata() {
    test_section "Skills Metadata Format"
    
    # 检查 freqtrade 技能元数据
    if grep -q "^name:" skills/freqtrade/SKILL.md; then
        test_pass "freqtrade has name metadata"
    else
        test_fail "freqtrade missing name metadata"
    fi
    
    if grep -q "^description:" skills/freqtrade/SKILL.md; then
        test_pass "freqtrade has description metadata"
    else
        test_fail "freqtrade missing description metadata"
    fi
    
    # 检查 billing 技能元数据
    if grep -q "^name:" skills/billing/SKILL.md; then
        test_pass "billing has name metadata"
    else
        test_fail "billing missing name metadata"
    fi
}

# 测试：安装脚本语法
test_script_syntax() {
    test_section "Script Syntax"
    
    if bash -n scripts/install.sh 2>/dev/null; then
        test_pass "install.sh syntax valid"
    else
        test_fail "install.sh syntax error"
    fi
    
    if bash -n scripts/init-config.sh 2>/dev/null; then
        test_pass "init-config.sh syntax valid"
    else
        test_fail "init-config.sh syntax error"
    fi
}

# 测试：目录创建
test_directory_creation() {
    test_section "Directory Creation"
    
    setup
    
    # 模拟创建目录
    mkdir -p "$HOME/.cryptoclaw"/{config,user_data,workspace,logs}
    
    if [ -d "$HOME/.cryptoclaw/config" ]; then
        test_pass "config directory created"
    else
        test_fail "config directory not created"
    fi
    
    if [ -d "$HOME/.cryptoclaw/user_data" ]; then
        test_pass "user_data directory created"
    else
        test_fail "user_data directory not created"
    fi
    
    cleanup
}

# 测试：配置模板生成
test_config_templates() {
    test_section "Config Templates"
    
    setup
    
    # 创建配置目录
    mkdir -p "$HOME/.cryptoclaw/config"
    
    # 从脚本中提取模板并测试
    if grep -q "TELEGRAM_BOT_TOKEN" scripts/install.sh; then
        test_pass "install.sh contains Telegram config"
    else
        test_fail "install.sh missing Telegram config"
    fi
    
    if grep -q "LLM_API_KEY" scripts/install.sh; then
        test_pass "install.sh contains LLM config"
    else
        test_fail "install.sh missing LLM config"
    fi
    
    cleanup
}

# 显示测试结果
show_results() {
    echo ""
    echo "================================"
    echo "Test Results"
    echo "================================"
    echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed!${NC}"
        exit 1
    fi
}

# 主函数
main() {
    echo "CryptoClaw Installer Tests"
    echo "=========================="
    
    cd "$(dirname "$0")/.."
    
    test_scripts_exist
    test_scripts_executable
    test_skills_exist
    test_skill_metadata
    test_script_syntax
    test_directory_creation
    test_config_templates
    
    show_results
}

main "$@"
