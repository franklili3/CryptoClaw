/**
 * CryptoClaw Desktop Client - Renderer Process
 * 
 * UI 交互和 IPC 通信
 */

// 全局状态
let currentKeyMode = 'llm';
let serviceRunning = false;
let gatewayStatus = {
  connected: false,
  host: '',
  port: 0,
  hasToken: false,
  hasDeviceToken: false
};

/**
 * 初始化应用
 */
async function init() {
  // 检查是否已配置
  const status = await window.electronAPI.getServiceStatus();
  
  if (!status.configured) {
    // 显示欢迎向导
    showPage('wizard');
  } else {
    // 显示主界面
    showPage('dashboard');
    loadDashboard();
  }
  
  // 更新服务状态
  updateServiceStatus(status);
  
  // 加载版本信息
  const version = await window.electronAPI.getVersion();
  document.getElementById('app-version').textContent = version;
  document.getElementById('config-dir').textContent = status.configDir;
  
  // 监听事件
  window.electronAPI.onShowWizard(() => {
    showPage('wizard');
  });
  
  window.electronAPI.onUpdateAvailable((info) => {
    showToast('发现新版本: ' + info.version, 'info');
  });
  
  // 监听 Gateway 状态变化
  window.electronAPI.onGatewayStatusChanged((status) => {
    gatewayStatus = status;
    updateGatewayStatusUI();
  });
  
  // 加载 Gateway 状态
  try {
    gatewayStatus = await window.electronAPI.getGatewayStatus();
    updateGatewayStatusUI();
  } catch (e) {
    console.error('Failed to get gateway status:', e);
  }
}

/**
 * 开始向导
 */
function startWizard() {
  showPage('main');
  showPage('api-keys');
  showAddKeyModal('llm');
}

/**
 * 显示页面
 */
function showPage(pageId) {
  // 隐藏所有页面
  document.querySelectorAll('[id^="page-"]').forEach(el => {
    el.classList.add('hidden');
  });
  
  // 显示目标页面
  const targetPage = document.getElementById('page-' + pageId);
  if (targetPage) {
    targetPage.classList.remove('hidden');
  }
  
  // 如果是主界面，确保显示
  if (['dashboard', 'api-keys', 'telegram', 'billing', 'settings'].includes(pageId)) {
    document.getElementById('main-page').classList.remove('hidden');
    document.getElementById('wizard-page').classList.add('hidden');
    
    // 更新导航
    document.querySelectorAll('.nav-item').forEach(el => {
      el.classList.remove('active');
    });
    event?.target?.closest('.nav-item')?.classList.add('active');
  }
  
  // 加载页面数据
  switch (pageId) {
    case 'dashboard':
      loadDashboard();
      break;
    case 'api-keys':
      loadApiKeys();
      break;
    case 'telegram':
      loadTelegramConfig();
      break;
  }
}

/**
 * 加载仪表盘
 */
async function loadDashboard() {
  const stats = document.getElementById('dashboard-stats');
  const status = await window.electronAPI.getServiceStatus();
  
  stats.innerHTML = `
    <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 20px;">
      <div style="text-align: center; padding: 20px; background: var(--bg-color); border-radius: 8px;">
        <div style="font-size: 32px; font-weight: 600; color: var(--primary-color);">${status.running ? '✅' : '⏹️'}</div>
        <div style="color: var(--text-secondary); margin-top: 8px;">服务状态</div>
        <div style="font-weight: 600;">${status.running ? '运行中' : '已停止'}</div>
      </div>
      <div style="text-align: center; padding: 20px; background: var(--bg-color); border-radius: 8px;">
        <div style="font-size: 32px; font-weight: 600; color: var(--success-color);">v${status.version}</div>
        <div style="color: var(--text-secondary); margin-top: 8px;">软件版本</div>
      </div>
      <div style="text-align: center; padding: 20px; background: var(--bg-color); border-radius: 8px;">
        <div style="font-size: 32px;">🔐</div>
        <div style="color: var(--text-secondary); margin-top: 8px;">数据存储</div>
        <div style="font-weight: 600; font-size: 12px;">本地加密</div>
      </div>
    </div>
    
    <div style="margin-top: 30px;">
      <h3 style="margin-bottom: 16px;">快速开始</h3>
      <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 16px;">
        <button class="btn btn-outline btn-full" onclick="showPage('api-keys')">
          🔑 配置 API Key
        </button>
        <button class="btn btn-outline btn-full" onclick="showPage('telegram')">
          📱 连接 Telegram
        </button>
        <button class="btn btn-outline btn-full" onclick="openDocs()">
          📚 查看文档
        </button>
        <button class="btn btn-outline btn-full" onclick="openTelegram()">
          💬 联系支持
        </button>
      </div>
    </div>
  `;
}

/**
 * 加载 API Keys
 */
async function loadApiKeys() {
  const keys = await window.electronAPI.getApiKeys();
  
  const llmList = document.getElementById('llm-keys-list');
  const exchangeList = document.getElementById('exchange-keys-list');
  
  const llmKeys = keys.filter(k => ['openai', 'anthropic', 'deepseek', 'local'].includes(k.provider));
  const exchangeKeys = keys.filter(k => ['binance', 'okx'].includes(k.provider));
  
  llmList.innerHTML = llmKeys.length === 0 
    ? '<p style="color: var(--text-secondary);">暂无 LLM API Key</p>'
    : llmKeys.map(k => createKeyItem(k)).join('');
  
  exchangeList.innerHTML = exchangeKeys.length === 0
    ? '<p style="color: var(--text-secondary);">暂无交易所 API Key</p>'
    : exchangeKeys.map(k => createKeyItem(k)).join('');
}

/**
 * 创建 Key 项目 HTML
 */
function createKeyItem(key) {
  const providerLabels = {
    openai: 'OpenAI',
    anthropic: 'Anthropic',
    deepseek: 'DeepSeek',
    local: '本地模型',
    binance: 'Binance',
    okx: 'OKX'
  };
  
  return `
    <div class="api-key-item">
      <div class="api-key-info">
        <span class="provider-badge provider-${key.provider}">${providerLabels[key.provider] || key.provider}</span>
        <span>${key.name || '默认'}</span>
        <span class="key-value">${key.key}</span>
      </div>
      <div class="api-key-actions">
        <button class="btn-icon" title="验证" onclick="verifyKey('${key.id}', '${key.provider}')">✓</button>
        <button class="btn-icon" title="删除" onclick="deleteKey('${key.id}')">🗑️</button>
      </div>
    </div>
  `;
}

/**
 * 显示添加 Key 模态框
 */
function showAddKeyModal(mode) {
  currentKeyMode = mode;
  document.getElementById('key-type').value = mode;
  updateProviderOptions();
  document.getElementById('add-key-modal').classList.add('active');
}

/**
 * 隐藏添加 Key 模态框
 */
function hideAddKeyModal() {
  document.getElementById('add-key-modal').classList.remove('active');
  document.getElementById('key-name').value = '';
  document.getElementById('key-value').value = '';
}

/**
 * 更新提供商选项
 */
function updateProviderOptions() {
  const type = document.getElementById('key-type').value;
  const providerSelect = document.getElementById('key-provider');
  
  const llmProviders = [
    { value: 'openai', label: 'OpenAI' },
    { value: 'anthropic', label: 'Anthropic (Claude)' },
    { value: 'deepseek', label: 'DeepSeek' },
    { value: 'local', label: '本地模型' }
  ];
  
  const exchangeProviders = [
    { value: 'binance', label: 'Binance' },
    { value: 'okx', label: 'OKX' }
  ];
  
  const providers = type === 'llm' ? llmProviders : exchangeProviders;
  
  providerSelect.innerHTML = providers.map(p => 
    `<option value="${p.value}">${p.label}</option>`
  ).join('');
}

/**
 * 添加 API Key
 */
async function addApiKey() {
  const provider = document.getElementById('key-provider').value;
  const name = document.getElementById('key-name').value;
  const key = document.getElementById('key-value').value;
  
  if (!key) {
    showToast('请输入 API Key', 'error');
    return;
  }
  
  // 验证 Key
  showToast('正在验证...', 'info');
  const result = await window.electronAPI.verifyApiKey(provider, key);
  
  if (!result.valid) {
    showToast('API Key 验证失败: ' + (result.error || '无效'), 'error');
    return;
  }
  
  // 保存 Key
  const saveResult = await window.electronAPI.addApiKey(provider, key, name);
  
  if (saveResult.success) {
    showToast('API Key 添加成功', 'success');
    hideAddKeyModal();
    loadApiKeys();
  } else {
    showToast('保存失败', 'error');
  }
}

/**
 * 验证 Key
 */
async function verifyKey(id, provider) {
  showToast('验证功能开发中...', 'info');
}

/**
 * 删除 Key
 */
async function deleteKey(id) {
  if (confirm('确定要删除此 API Key 吗？')) {
    const result = await window.electronAPI.deleteApiKey(id);
    if (result.success) {
      showToast('已删除', 'success');
      loadApiKeys();
    }
  }
}

/**
 * 加载 Telegram 配置
 */
async function loadTelegramConfig() {
  const token = await window.electronAPI.getConfig('telegramToken');
  if (token) {
    document.getElementById('telegram-token').value = token;
  }
}

/**
 * 保存 Telegram Token
 */
async function saveTelegramToken() {
  const token = document.getElementById('telegram-token').value;
  
  if (!token) {
    showToast('请输入 Bot Token', 'error');
    return;
  }
  
  // 验证格式
  if (!/^\d+:[A-Za-z0-9_-]+$/.test(token)) {
    showToast('Token 格式不正确', 'error');
    return;
  }
  
  const result = await window.electronAPI.setConfig('telegramToken', token);
  
  if (result.success) {
    showToast('保存成功', 'success');
  } else {
    showToast('保存失败', 'error');
  }
}

/**
 * 切换服务
 */
async function toggleService() {
  const btn = document.getElementById('service-btn');
  
  if (serviceRunning) {
    btn.textContent = '停止中...';
    btn.disabled = true;
    await window.electronAPI.stopService();
    serviceRunning = false;
    btn.textContent = '启动服务';
    btn.classList.remove('btn-danger');
    btn.classList.add('btn-primary');
  } else {
    btn.textContent = '启动中...';
    btn.disabled = true;
    await window.electronAPI.startService();
    serviceRunning = true;
    btn.textContent = '停止服务';
    btn.classList.remove('btn-primary');
    btn.classList.add('btn-danger');
  }
  
  btn.disabled = false;
  updateServiceStatusDisplay();
}

/**
 * 更新服务状态
 */
function updateServiceStatus(status) {
  serviceRunning = status.running;
  updateServiceStatusDisplay();
}

/**
 * 更新服务状态显示
 */
function updateServiceStatusDisplay() {
  const dot = document.getElementById('status-dot');
  const text = document.getElementById('status-text');
  const btn = document.getElementById('service-btn');
  
  if (serviceRunning) {
    dot.classList.add('running');
    text.textContent = '服务运行中';
    btn.textContent = '停止服务';
    btn.classList.remove('btn-primary');
    btn.classList.add('btn-danger');
  } else {
    dot.classList.remove('running');
    text.textContent = '服务未运行';
    btn.textContent = '启动服务';
    btn.classList.remove('btn-danger');
    btn.classList.add('btn-primary');
  }
}

/**
 * 打开文档
 */
function openDocs() {
  window.electronAPI.openExternal('https://docs.cryptoclaw.pro');
}

/**
 * 打开 Telegram 支持
 */
function openTelegram() {
  window.electronAPI.openExternal('https://t.me/CryptoClawBot');
}

/**
 * 显示 Toast
 */
function showToast(message, type = 'info') {
  const container = document.getElementById('toast-container');
  const toast = document.createElement('div');
  toast.className = `toast ${type}`;
  toast.textContent = message;
  container.appendChild(toast);
  
  setTimeout(() => {
    toast.remove();
  }, 3000);
}

// ========== Gateway 配对功能 ==========

/**
 * 更新 Gateway 状态 UI
 */
function updateGatewayStatusUI() {
  const statusDot = document.getElementById('gateway-status-dot');
  const statusText = document.getElementById('gateway-status-text');
  const pairBtn = document.getElementById('pair-btn');
  
  if (statusDot && statusText) {
    if (gatewayStatus.connected) {
      statusDot.classList.add('running');
      statusText.textContent = '已连接';
      if (pairBtn) pairBtn.textContent = '断开连接';
    } else {
      statusDot.classList.remove('running');
      statusText.textContent = gatewayStatus.hasDeviceToken ? '已配对，未连接' : '未连接';
      if (pairBtn) pairBtn.textContent = gatewayStatus.hasToken ? '重新配对' : '一键配对';
    }
  }
}

/**
 * 一键配对
 */
async function oneClickPair() {
  const host = document.getElementById('gateway-host')?.value || '127.0.0.1';
  const port = document.getElementById('gateway-port')?.value || '19001';
  const token = document.getElementById('gateway-token')?.value;
  
  if (!token) {
    showToast('请输入 Gateway Token', 'error');
    return;
  }
  
  try {
    showToast('正在配对...', 'info');
    
    const result = await window.electronAPI.oneClickPair(host, parseInt(port), token);
    
    if (result.success) {
      showToast('配对成功！', 'success');
      gatewayStatus.connected = true;
      gatewayStatus.hasToken = true;
      gatewayStatus.hasDeviceToken = true;
      updateGatewayStatusUI();
      
      // 跳转到仪表盘
      showPage('dashboard');
    } else {
      showToast(`配对失败: ${result.error}`, 'error');
    }
  } catch (error) {
    showToast(`配对失败: ${error.message}`, 'error');
  }
}

/**
 * 断开 Gateway
 */
async function disconnectGateway() {
  try {
    await window.electronAPI.disconnectGateway();
    gatewayStatus.connected = false;
    updateGatewayStatusUI();
    showToast('已断开连接', 'success');
  } catch (error) {
    showToast(`断开失败: ${error.message}`, 'error');
  }
}

/**
 * 配对按钮点击处理
 */
async function handlePairButton() {
  if (gatewayStatus.connected) {
    await disconnectGateway();
  } else {
    await oneClickPair();
  }
}

// 页面加载完成后初始化
document.addEventListener('DOMContentLoaded', init);
