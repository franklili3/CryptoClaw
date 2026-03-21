/**
 * CryptoClaw Desktop Client - Electron Main Process
 * 
 * 职责：
 * - 管理 API Key 的安全存储（AES-256 加密）
 * - 提供配置管理界面
 * - 启动/停止 OpenClaw Gateway 服务
 * - 软件更新检查
 * 
 * 参考：requirement.md - 5.1 功能架构
 */

const { app, BrowserWindow, ipcMain, dialog, shell, Menu, Tray, nativeImage } = require('electron');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');
const Store = require('electron-store');
const log = require('electron-log');
const { autoUpdater } = require('electron-updater');
const windowStateKeeper = require('electron-window-state');

// 配置日志
log.transports.file.level = 'info';
log.transports.console.level = 'debug';

// 加密存储
const secureStore = new Store({
  name: 'secure-config',
  encryptionKey: process.env.CRYPTOCLAW_MASTER_KEY || 'default-dev-key-change-in-production'
});

// 全局变量
let mainWindow = null;
let tray = null;
let isQuitting = false;
let gatewayConnection = null;
let isGatewayConnected = false;

// 配置目录
const CONFIG_DIR = path.join(app.getPath('home'), '.cryptoclaw');
const DB_PATH = path.join(CONFIG_DIR, 'cryptoclaw.db');
const ENV_PATH = path.join(CONFIG_DIR, 'config', '.env');
const OPENCLAW_CONFIG_PATH = path.join(CONFIG_DIR, 'config', 'openclaw.yaml');
const WIZARD_COMPLETED_FILE = path.join(CONFIG_DIR, '.wizard_completed');

/**
 * 检查是否已完成首次配置
 */
function isConfigured() {
  // 检查配置目录和标记文件是否存在
  return fs.existsSync(WIZARD_COMPLETED_FILE);
}

/**
 * 创建主窗口
 */
function createMainWindow() {
  // 保存窗口状态
  let mainWindowState = windowStateKeeper({
    defaultWidth: 1000,
    defaultHeight: 700
  });

  mainWindow = new BrowserWindow({
    x: mainWindowState.x,
    y: mainWindowState.y,
    width: mainWindowState.width || 1000,
    height: mainWindowState.height || 700,
    minWidth: 800,
    minHeight: 600,
    maxWidth: 1400,
    maxHeight: 900,
    title: 'CryptoClaw',
    icon: path.join(__dirname, '../../resources/icon.png'),
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js'),
      devTools: true
    },
    show: false // 先隐藏，加载完成后显示
  });
  
  // 确保窗口不会全屏
  mainWindow.setFullScreenable(false);

  // 管理窗口状态
  mainWindowState.manage(mainWindow);

  // 加载应用
  const showWizard = !isConfigured();
  const htmlFile = showWizard ? 'welcome.html' : 'index.html';
  
  if (process.env.NODE_ENV === 'development') {
    mainWindow.loadFile(path.join(__dirname, `../renderer/${htmlFile}`));
    mainWindow.webContents.openDevTools();
  } else {
    // 生产模式：检查多个可能的路径
    const possiblePaths = [
      path.join(__dirname, `../renderer/${htmlFile}`),  // app.asar 内
      path.join(app.getAppPath(), `src/renderer/${htmlFile}`),  // 开发目录
      path.join(path.dirname(app.getAppPath()), `src/renderer/${htmlFile}`),  // 解压后的目录
    ];
    
    let htmlPath = null;
    for (const p of possiblePaths) {
      log.info('Checking path:', p);
      if (fs.existsSync(p)) {
        htmlPath = p;
        log.info('Found HTML at:', htmlPath);
        break;
      }
    }
    
    if (htmlPath) {
      mainWindow.loadFile(htmlPath);
    } else {
      log.error('HTML file not found in any of:', possiblePaths);
      // 显示错误页面
      mainWindow.loadURL(`data:text/html,
        <html>
        <head><title>CryptoClaw - Error</title></head>
        <body style="background:#1a1a2e;color:#fff;font-family:sans-serif;display:flex;justify-content:center;align-items:center;height:100vh;margin:0;">
          <div style="text-align:center;">
            <h1>🦀 CryptoClaw</h1>
            <p style="color:#ff6464;">Failed to load application UI</p>
            <p style="color:#8892b0;font-size:14px;">Please check the installation or run from source</p>
            <p style="color:#64ffda;font-size:12px;margin-top:20px;">Searched paths:</p>
            <pre style="color:#8892b0;font-size:11px;text-align:left;background:rgba(0,0,0,0.3);padding:10px;border-radius:8px;">${possiblePaths.join('\n')}</pre>
          </div>
        </body>
        </html>
      `);
    }
  }

  // 窗口准备就绪
  mainWindow.once('ready-to-show', () => {
    mainWindow.show();
    
    // 检查是否需要显示欢迎向导
    if (!isConfigured()) {
      showWelcomeWizard();
    }
  });

  // 窗口关闭事件
  mainWindow.on('close', (event) => {
    if (!isQuitting) {
      event.preventDefault();
      mainWindow.hide();
    }
  });

  mainWindow.on('closed', () => {
    mainWindow = null;
  });

  // 创建菜单
  createMenu();
}

/**
 * 创建系统托盘
 */
function createTray() {
  const iconPath = path.join(__dirname, '../../resources/icon-tray.png');
  const trayIcon = nativeImage.createFromPath(iconPath);
  
  tray = new Tray(trayIcon.resize({ width: 16, height: 16 }));
  
  const contextMenu = Menu.buildFromTemplate([
    { 
      label: '显示主窗口', 
      click: () => {
        if (mainWindow) {
          mainWindow.show();
          mainWindow.focus();
        }
      }
    },
    { type: 'separator' },
    { 
      label: '服务状态', 
      enabled: false 
    },
    { 
      label: '运行中', 
      type: 'radio',
      checked: isServiceRunning()
    },
    { type: 'separator' },
    { 
      label: '退出', 
      click: () => {
        isQuitting = true;
        app.quit();
      }
    }
  ]);
  
  tray.setToolTip('CryptoClaw');
  tray.setContextMenu(contextMenu);
  
  tray.on('click', () => {
    if (mainWindow) {
      if (mainWindow.isVisible()) {
        mainWindow.hide();
      } else {
        mainWindow.show();
        mainWindow.focus();
      }
    }
  });
}

/**
 * 创建应用菜单
 */
function createMenu() {
  const template = [
    {
      label: 'CryptoClaw',
      submenu: [
        { role: 'about', label: '关于 CryptoClaw' },
        { type: 'separator' },
        { 
          label: '偏好设置',
          accelerator: 'CmdOrCtrl+,',
          click: () => mainWindow.webContents.send('navigate', 'settings')
        },
        { type: 'separator' },
        { role: 'services' },
        { type: 'separator' },
        { role: 'hide', label: '隐藏 CryptoClaw' },
        { role: 'hideOthers' },
        { role: 'unhide' },
        { type: 'separator' },
        { role: 'quit', label: '退出 CryptoClaw' }
      ]
    },
    {
      label: '编辑',
      submenu: [
        { role: 'undo', label: '撤销' },
        { role: 'redo', label: '重做' },
        { type: 'separator' },
        { role: 'cut', label: '剪切' },
        { role: 'copy', label: '复制' },
        { role: 'paste', label: '粘贴' },
        { role: 'selectAll', label: '全选' }
      ]
    },
    {
      label: '视图',
      submenu: [
        { role: 'reload', label: '重新加载' },
        { role: 'forceReload', label: '强制重新加载' },
        { role: 'toggleDevTools', label: '开发者工具' },
        { type: 'separator' },
        { role: 'resetZoom', label: '重置缩放' },
        { role: 'zoomIn', label: '放大' },
        { role: 'zoomOut', label: '缩小' },
        { type: 'separator' },
        { role: 'togglefullscreen', label: '全屏' }
      ]
    },
    {
      label: '窗口',
      submenu: [
        { role: 'minimize', label: '最小化' },
        { role: 'zoom', label: '缩放' },
        { type: 'separator' },
        { role: 'front', label: '前置全部窗口' }
      ]
    },
    {
      label: '帮助',
      submenu: [
        { 
          label: '文档',
          click: () => shell.openExternal('https://docs.cryptoclaw.pro')
        },
        { 
          label: 'Telegram 支持',
          click: () => shell.openExternal('https://t.me/CryptoClawBot')
        },
        { type: 'separator' },
        { 
          label: '检查更新',
          click: () => checkForUpdates()
        }
      ]
    }
  ];

  const menu = Menu.buildFromTemplate(template);
  Menu.setApplicationMenu(menu);
}

/**
 * 检查是否已配置
 */
/**
 * 显示欢迎向导
 */
function showWelcomeWizard() {
  if (mainWindow) {
    mainWindow.webContents.send('show-wizard');
  }
}

/**
 * 检查服务是否运行
 */
function isServiceRunning() {
  // TODO: 实现服务状态检查
  return false;
}

/**
 * 检查更新
 */
async function checkForUpdates() {
  try {
    const result = await autoUpdater.checkForUpdatesAndNotify();
    if (result) {
      log.info('Update available:', result.updateInfo.version);
    }
  } catch (error) {
    log.error('Update check failed:', error);
  }
}

/**
 * 初始化 IPC 处理器
 */
function initIpcHandlers() {
  // 获取配置
  ipcMain.handle('get-config', async (event, key) => {
    return secureStore.get(key);
  });

  // 保存配置
  ipcMain.handle('set-config', async (event, { key, value }) => {
    secureStore.set(key, value);
    
    // 如果是 wizardCompleted，创建标记文件
    if (key === 'wizardCompleted' && value === true) {
      const configDir = path.dirname(WIZARD_COMPLETED_FILE);
      if (!fs.existsSync(configDir)) {
        fs.mkdirSync(configDir, { recursive: true });
      }
      fs.writeFileSync(WIZARD_COMPLETED_FILE, '');
      log.info('Wizard completed, marker file created');
    }
    
    return { success: true };
  });

  // 获取所有 API Keys（脱敏）
  ipcMain.handle('get-api-keys', async () => {
    const keys = secureStore.get('apiKeys') || [];
    return keys.map(k => ({
      ...k,
      key: maskApiKey(k.key)
    }));
  });

  // 添加 API Key
  ipcMain.handle('add-api-key', async (event, { provider, key, name }) => {
    const keys = secureStore.get('apiKeys') || [];
    const encryptedKey = encryptData(key);
    
    keys.push({
      id: crypto.randomUUID(),
      provider,
      name,
      key: encryptedKey,
      createdAt: new Date().toISOString()
    });
    
    secureStore.set('apiKeys', keys);
    return { success: true };
  });

  // 删除 API Key
  ipcMain.handle('delete-api-key', async (event, id) => {
    let keys = secureStore.get('apiKeys') || [];
    keys = keys.filter(k => k.id !== id);
    secureStore.set('apiKeys', keys);
    return { success: true };
  });

  // 验证 API Key
  ipcMain.handle('verify-api-key', async (event, { provider, key }) => {
    return await verifyApiKey(provider, key);
  });

  // 获取服务状态
  ipcMain.handle('get-service-status', async () => {
    return {
      running: isServiceRunning(),
      version: app.getVersion(),
      configDir: CONFIG_DIR
    };
  });

  // 启动服务
  ipcMain.handle('start-service', async () => {
    const { exec } = require('child_process');
    const util = require('util');
    const execAsync = util.promisify(exec);
    
    try {
      // 检查容器是否已存在
      const { stdout: psOutput } = await execAsync('/snap/bin/docker ps -a --filter name=cryptoclaw-gateway --format "{{.Status}}"');
      
      if (psOutput.includes('Up')) {
        return { success: true, message: '服务已在运行中' };
      }
      
      if (psOutput.includes('Exited')) {
        // 容器存在但已停止，启动它
        await execAsync('/snap/bin/docker start cryptoclaw-gateway');
        log.info('Gateway container started');
        return { success: true, message: '服务已启动' };
      }
      
      // 容器不存在，创建新容器
      const configDir = CONFIG_DIR;
      await execAsync(`mkdir -p ${configDir}/config`);
      
      // 创建配置文件（如果不存在）
      const configPath = path.join(configDir, 'config', 'openclaw.yaml');
      if (!fs.existsSync(configPath)) {
        fs.writeFileSync(configPath, `gateway:
  auth:
    mode: token
    token: "test-token-12345"
  bind:
    host: 0.0.0.0
    port: 19001
`);
      }
      
      // 启动容器
      await execAsync(`/snap/bin/docker run -d --name cryptoclaw-gateway -p 19001:19001 -v ${configDir}:/app/.openclaw cryptoclaw/cryptoclaw:latest`);
      log.info('Gateway container created and started');
      
      return { success: true, message: '服务已启动' };
    } catch (error) {
      log.error('Start service error:', error);
      return { success: false, message: `启动失败: ${error.message}` };
    }
  });

  // 停止服务
  ipcMain.handle('stop-service', async () => {
    const { exec } = require('child_process');
    const util = require('util');
    const execAsync = util.promisify(exec);
    
    try {
      await execAsync('/snap/bin/docker stop cryptoclaw-gateway 2>/dev/null || true');
      log.info('Gateway container stopped');
      return { success: true, message: '服务已停止' };
    } catch (error) {
      log.error('Stop service error:', error);
      return { success: false, message: `停止失败: ${error.message}` };
    }
  });

  // 选择目录
  ipcMain.handle('select-directory', async () => {
    const result = await dialog.showOpenDialog(mainWindow, {
      properties: ['openDirectory']
    });
    return result.filePaths[0];
  });

  // 打开外部链接
  ipcMain.handle('open-external', async (event, url) => {
    await shell.openExternal(url);
  });

  // 获取应用版本
  ipcMain.handle('get-version', () => {
    return app.getVersion();
  });

  // ========== Gateway 连接与配对 ==========
  
  // 连接 Gateway
  ipcMain.handle('connect-gateway', async (event, { host, port, token }) => {
    const WebSocket = require('ws');
    
    return new Promise((resolve, reject) => {
      try {
        const wsUrl = `ws://${host}:${port}`;
        log.info(`Connecting to Gateway: ${wsUrl}`);
        
        const ws = new WebSocket(wsUrl);
        
        ws.on('open', () => {
          log.info('WebSocket connected, sending auth...');
          
          // 发送 Gateway Token 认证
          ws.send(JSON.stringify({
            type: 'auth',
            token: token
          }));
        });
        
        ws.on('message', (data) => {
          try {
            const msg = JSON.parse(data.toString());
            log.info('Gateway message:', msg.type || msg.method);
            
            // 处理挑战响应
            if (msg.type === 'event' && msg.event === 'connect.challenge') {
              log.info('Received challenge, responding...');
              // 响应挑战 - 用 token 作为签名
              ws.send(JSON.stringify({
                type: 'auth:response',
                nonce: msg.payload?.nonce,
                token: token
              }));
              return;
            }
            
            if (msg.type === 'auth:success' || msg.ok === true || msg.type === 'ready') {
              gatewayConnection = ws;
              isGatewayConnected = true;
              
              // 保存 Gateway Token
              secureStore.set('gatewayToken', token);
              secureStore.set('gatewayHost', host);
              secureStore.set('gatewayPort', port);
              
              // 通知渲染器
              mainWindow?.webContents.send('gateway-status-changed', { connected: true });
              
              resolve({ success: true, message: 'Connected to Gateway' });
            } else if (msg.type === 'auth:failed' || msg.error) {
              log.error('Auth failed:', msg.error);
              ws.close();
              reject(new Error(msg.error?.message || 'Authentication failed'));
            }
          } catch (e) {
            log.error('Parse message error:', e);
          }
        });
        
        ws.on('error', (err) => {
          log.error('WebSocket error:', err);
          reject(new Error(`Connection failed: ${err.message}`));
        });
        
        ws.on('close', () => {
          log.info('WebSocket closed');
          gatewayConnection = null;
          isGatewayConnected = false;
          mainWindow?.webContents.send('gateway-status-changed', { connected: false });
        });
        
        // 超时
        setTimeout(() => {
          if (!isGatewayConnected) {
            ws.close();
            reject(new Error('Connection timeout'));
          }
        }, 10000);
        
      } catch (error) {
        log.error('Connect error:', error);
        reject(error);
      }
    });
  });

  // 请求配对
  ipcMain.handle('request-pairing', async () => {
    if (!gatewayConnection || !isGatewayConnected) {
      throw new Error('Not connected to Gateway');
    }
    
    const clientId = secureStore.get('clientId') || crypto.randomUUID();
    secureStore.set('clientId', clientId);
    
    return new Promise((resolve, reject) => {
      const requestId = crypto.randomUUID();
      
      log.info(`Requesting pairing for client: ${clientId}`);
      
      // 发送配对请求
      gatewayConnection.send(JSON.stringify({
        jsonrpc: '2.0',
        id: requestId,
        method: 'node.pair.request',
        params: {
          nodeId: clientId,
          silent: true  // 静默模式，暗示自动批准
        }
      }));
      
      // 监听响应
      const handler = (data) => {
        try {
          const msg = JSON.parse(data.toString());
          if (msg.id === requestId) {
            gatewayConnection.off('message', handler);
            if (msg.error) {
              log.error('Pairing request error:', msg.error);
              reject(new Error(msg.error.message || 'Pairing request failed'));
            } else {
              log.info('Pairing request accepted:', msg.result);
              resolve(msg.result);
            }
          }
        } catch (e) {
          log.error('Parse pairing response error:', e);
        }
      };
      
      gatewayConnection.on('message', handler);
      
      // 超时
      setTimeout(() => {
        gatewayConnection.off('message', handler);
        reject(new Error('Pairing request timeout'));
      }, 15000);
    });
  });

  // 批准配对
  ipcMain.handle('approve-pairing', async (event, { requestId }) => {
    if (!gatewayConnection || !isGatewayConnected) {
      throw new Error('Not connected to Gateway');
    }
    
    return new Promise((resolve, reject) => {
      const callId = crypto.randomUUID();
      
      log.info(`Approving pairing request: ${requestId}`);
      
      gatewayConnection.send(JSON.stringify({
        jsonrpc: '2.0',
        id: callId,
        method: 'node.pair.approve',
        params: { requestId }
      }));
      
      const handler = (data) => {
        try {
          const msg = JSON.parse(data.toString());
          if (msg.id === callId) {
            gatewayConnection.off('message', handler);
            if (msg.error) {
              log.error('Approve error:', msg.error);
              reject(new Error(msg.error.message || 'Approve failed'));
            } else {
              // 保存 Device Token
              if (msg.result?.deviceToken) {
                secureStore.set('deviceToken', msg.result.deviceToken);
                log.info('Device token saved');
              }
              resolve(msg.result);
            }
          }
        } catch (e) {
          log.error('Parse approve response error:', e);
        }
      };
      
      gatewayConnection.on('message', handler);
      
      setTimeout(() => {
        gatewayConnection.off('message', handler);
        reject(new Error('Approve timeout'));
      }, 15000);
    });
  });

  // 一键配对（组合以上步骤）
  ipcMain.handle('one-click-pair', async (event, { host, port, token }) => {
    try {
      log.info('Starting one-click pairing...');
      
      // 1. 连接 Gateway
      await ipcMain.invoke('connect-gateway', { host, port, token });
      log.info('Gateway connected');
      
      // 2. 请求配对
      const pairResult = await ipcMain.invoke('request-pairing');
      log.info('Pairing requested:', pairResult);
      
      // 3. 自动批准
      if (pairResult?.requestId || pairResult?.pending?.requestId) {
        const requestId = pairResult.requestId || pairResult.pending.requestId;
        const approveResult = await ipcMain.invoke('approve-pairing', { requestId });
        log.info('Pairing approved:', approveResult);
        
        return {
          success: true,
          deviceToken: approveResult?.deviceToken,
          message: 'Pairing completed successfully'
        };
      } else {
        // 可能已经配对过了
        return {
          success: true,
          message: 'Already paired or pairing not required'
        };
      }
    } catch (error) {
      log.error('One-click pair error:', error);
      return {
        success: false,
        error: error.message
      };
    }
  });

  // 获取 Gateway 状态
  ipcMain.handle('get-gateway-status', async () => {
    return {
      connected: isGatewayConnected,
      host: secureStore.get('gatewayHost'),
      port: secureStore.get('gatewayPort'),
      hasToken: !!secureStore.get('gatewayToken'),
      hasDeviceToken: !!secureStore.get('deviceToken'),
      clientId: secureStore.get('clientId')
    };
  });

  // 断开 Gateway
  ipcMain.handle('disconnect-gateway', async () => {
    if (gatewayConnection) {
      gatewayConnection.close();
      gatewayConnection = null;
      isGatewayConnected = false;
      mainWindow?.webContents.send('gateway-status-changed', { connected: false });
    }
    return { success: true };
  });
}

/**
 * 加密数据
 */
function encryptData(plaintext) {
  const algorithm = 'aes-256-gcm';
  const key = crypto.scryptSync(
    process.env.CRYPTOCLAW_MASTER_KEY || 'default-dev-key',
    'salt',
    32
  );
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv(algorithm, key, iv);
  
  let encrypted = cipher.update(plaintext, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  
  const authTag = cipher.getAuthTag();
  
  return {
    iv: iv.toString('hex'),
    data: encrypted,
    tag: authTag.toString('hex')
  };
}

/**
 * 解密数据
 */
function decryptData(encrypted) {
  const algorithm = 'aes-256-gcm';
  const key = crypto.scryptSync(
    process.env.CRYPTOCLAW_MASTER_KEY || 'default-dev-key',
    'salt',
    32
  );
  
  const decipher = crypto.createDecipheriv(
    algorithm,
    key,
    Buffer.from(encrypted.iv, 'hex')
  );
  
  decipher.setAuthTag(Buffer.from(encrypted.tag, 'hex'));
  
  let decrypted = decipher.update(encrypted.data, 'hex', 'utf8');
  decrypted += decipher.final('utf8');
  
  return decrypted;
}

/**
 * 脱敏 API Key
 */
function maskApiKey(key) {
  if (typeof key === 'object' && key.data) {
    return '••••••••' + key.data.slice(-4);
  }
  if (typeof key === 'string' && key.length > 8) {
    return key.slice(0, 4) + '••••••••' + key.slice(-4);
  }
  return '••••••••';
}

/**
 * 验证 API Key
 */
async function verifyApiKey(provider, key) {
  const axios = require('axios');
  
  try {
    switch (provider) {
      case 'openai':
        const openaiRes = await axios.get('https://api.openai.com/v1/models', {
          headers: { 'Authorization': `Bearer ${key}` },
          timeout: 10000
        });
        return { valid: openaiRes.status === 200 };
        
      case 'anthropic':
        // Anthropic 没有 easy 验证端点，检查格式
        return { valid: key.startsWith('sk-ant-') };
        
      case 'binance':
        // Binance API 验证
        return { valid: key.length > 0 };
        
      case 'okx':
        // OKX API 验证
        return { valid: key.length > 0 };
        
      default:
        return { valid: false, error: 'Unknown provider' };
    }
  } catch (error) {
    return { valid: false, error: error.message };
  }
}

/**
 * 应用就绪
 */
app.whenReady().then(() => {
  // 初始化 IPC 处理器
  initIpcHandlers();
  
  // 创建系统托盘
  createTray();
  
  // 创建主窗口
  createMainWindow();
  
  // macOS 激活应用
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createMainWindow();
    }
  });
  
  // 检查更新（延迟 3 秒）
  setTimeout(checkForUpdates, 3000);
  
  log.info('CryptoClaw Client started');
});

/**
 * 所有窗口关闭
 */
app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

/**
 * 应用退出前
 */
app.on('before-quit', () => {
  isQuitting = true;
  
  // 断开 Gateway 连接
  if (gatewayConnection) {
    gatewayConnection.close();
    gatewayConnection = null;
    isGatewayConnected = false;
  }
  
  if (tray) {
    tray.destroy();
  }
});

/**
 * 自动更新事件
 */
autoUpdater.on('update-available', (info) => {
  log.info('Update available:', info.version);
  if (mainWindow) {
    mainWindow.webContents.send('update-available', info);
  }
});

autoUpdater.on('update-downloaded', (info) => {
  log.info('Update downloaded:', info.version);
  
  dialog.showMessageBox(mainWindow, {
    type: 'info',
    title: '更新可用',
    message: `新版本 ${info.version} 已下载`,
    detail: '是否立即安装？',
    buttons: ['立即安装', '稍后'],
    defaultId: 0
  }).then(result => {
    if (result.response === 0) {
      autoUpdater.quitAndInstall();
    }
  });
});
