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

// 配置目录
const CONFIG_DIR = path.join(app.getPath('home'), '.cryptoclaw');
const DB_PATH = path.join(CONFIG_DIR, 'cryptoclaw.db');
const ENV_PATH = path.join(CONFIG_DIR, 'config', '.env');
const OPENCLAW_CONFIG_PATH = path.join(CONFIG_DIR, 'config', 'openclaw.yaml');

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
    width: mainWindowState.width,
    height: mainWindowState.height,
    minWidth: 800,
    minHeight: 600,
    title: 'CryptoClaw',
    icon: path.join(__dirname, '../../resources/icon.png'),
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js')
    },
    show: false // 先隐藏，加载完成后显示
  });

  // 管理窗口状态
  mainWindowState.manage(mainWindow);

  // 加载应用
  if (process.env.NODE_ENV === 'development') {
    mainWindow.loadURL('http://localhost:3000');
    mainWindow.webContents.openDevTools();
  } else {
    mainWindow.loadFile(path.join(__dirname, '../renderer/index.html'));
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
function isConfigured() {
  return fs.existsSync(ENV_PATH) && fs.existsSync(OPENCLAW_CONFIG_PATH);
}

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
    // TODO: 实现 Docker 容器启动
    return { success: true, message: 'Service started' };
  });

  // 停止服务
  ipcMain.handle('stop-service', async () => {
    // TODO: 实现 Docker 容器停止
    return { success: true, message: 'Service stopped' };
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
