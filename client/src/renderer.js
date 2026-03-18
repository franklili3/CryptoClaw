/**
 * CryptoClaw Desktop Client - Renderer Process
 * 
 * 职责：
* - 将 IPC 渑收转换为 React 组件可理解的格式
* - 管理 UI 状态
 */

const { ipcRenderer } = require('electron');
const log from 'electron-log';

// 创建渲染器
const createRenderer = () => {
  mainWindow.loadURL(path.join(__dirname, 'pages', 'config.html'));
}

ipcRenderer.on('config', (event, page) => {
  const configPath = page;
  mainWindow.webContents.send('file://' + configPath);
}

// 设置 IPC 事件监听
ipcRenderer.on('config', (event, configPath) => {
  const exists = fs.existsSync(configPath);
  if (exists) {
    // 如果 配置不存在，显示配置向导
    mainWindow.webContents.send('load-configuration', (event, page);
  } else {
    const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    const openclawConfig = JSON.parse(config);
    
    // 检查 API Keys
    const apiKeys = config.api_keys || [];
    
    // 渲染 API Keys 列表
    const container = document.getElementById('api-keys-container');
    container.innerHTML = '';
    
    apiKeys.forEach((key, index) => {
      const item = document.createElement('div');
      item.className = 'api-key-item';
      item.innerHTML = `
        <div class="api-key-header">
          <span>${key.provider}</span>
          <span>${key.name || '</span>
          <span>${key.key_name || key.key.slice(0, 4) || '-'</span>
        </div>
        <div class="api-key-actions">
          <button class="delete-btn" onclick="deleteApiKey(${key})">Delete</button>
          <button class="toggle-btn" onclick="toggleApiKeyVisibility(${key})">Show/Hide</button>
        </div>
      });
    });
  });
}
