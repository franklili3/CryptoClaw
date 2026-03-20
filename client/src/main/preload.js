/**
 * CryptoClaw Desktop Client - Preload Script
 * 
 * 安全桥接渲染进程和主进程
 */

const { contextBridge, ipcRenderer } = require('electron');

// 暴露安全的 API 给渲染进程
contextBridge.exposeInMainWorld('electronAPI', {
  // 配置管理
  getConfig: (key) => ipcRenderer.invoke('get-config', key),
  setConfig: (key, value) => ipcRenderer.invoke('set-config', { key, value }),
  
  // API Key 管理
  getApiKeys: () => ipcRenderer.invoke('get-api-keys'),
  addApiKey: (provider, key, name) => ipcRenderer.invoke('add-api-key', { provider, key, name }),
  deleteApiKey: (id) => ipcRenderer.invoke('delete-api-key', id),
  verifyApiKey: (provider, key) => ipcRenderer.invoke('verify-api-key', { provider, key }),
  
  // 服务管理
  getServiceStatus: () => ipcRenderer.invoke('get-service-status'),
  startService: () => ipcRenderer.invoke('start-service'),
  stopService: () => ipcRenderer.invoke('stop-service'),
  
  // 工具
  selectDirectory: () => ipcRenderer.invoke('select-directory'),
  openExternal: (url) => ipcRenderer.invoke('open-external', url),
  getVersion: () => ipcRenderer.invoke('get-version'),
  
  // Gateway 连接
  connectGateway: (host, port, token) => ipcRenderer.invoke('connect-gateway', { host, port, token }),
  requestPairing: () => ipcRenderer.invoke('request-pairing'),
  approvePairing: (requestId) => ipcRenderer.invoke('approve-pairing', { requestId }),
  oneClickPair: (host, port, token) => ipcRenderer.invoke('one-click-pair', { host, port, token }),
  getGatewayStatus: () => ipcRenderer.invoke('get-gateway-status'),
  disconnectGateway: () => ipcRenderer.invoke('disconnect-gateway'),
  
  // 事件监听
  onUpdateAvailable: (callback) => {
    ipcRenderer.on('update-available', (event, info) => callback(info));
  },
  onNavigate: (callback) => {
    ipcRenderer.on('navigate', (event, page) => callback(page));
  },
  onShowWizard: (callback) => {
    ipcRenderer.on('show-wizard', () => callback());
  },
  onGatewayStatusChanged: (callback) => {
    ipcRenderer.on('gateway-status-changed', (event, status) => callback(status));
  }
});
