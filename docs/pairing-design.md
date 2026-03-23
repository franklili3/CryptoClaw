# CryptoQClaw 客户端配对方案设计

## 目标

实现一键配对：用户点击"连接 Gateway"按钮，自动完成：
1. Token 认证
2. 配对请求
3. 自动批准
4. 连接成功

## OpenClaw Gateway 配对机制

### 两种认证

| 认证类型 | 用途 | 存储位置 |
|---------|------|---------|
| Gateway Token | 访问 Gateway WebSocket | `~/.openclaw/openclaw.json` → `gateway.auth.token` |
| Device Token | 设备配对后的身份凭证 | `~/.openclaw/nodes/paired.json` |

### 配对流程

```
1. 客户端连接 ws://gateway:19001
2. 发送 Gateway Token 认证
3. 调用 node.pair.request (silent: true)
4. Gateway 创建 pending request
5. 自动批准 (调用 node.pair.approve)
6. Gateway 返回 Device Token
7. 客户端保存 Device Token
8. 后续连接使用 Device Token
```

### API 方法

```javascript
// 请求配对
{ method: "node.pair.request", params: { nodeId, silent: true } }

// 批准配对
{ method: "node.pair.approve", params: { requestId } }

// 拒绝配对
{ method: "node.pair.reject", params: { requestId } }

// 验证配对
{ method: "node.pair.verify", params: { nodeId, token } }
```

## 实现方案

### 方案 1：客户端内嵌 Token（推荐）

**流程：**
1. 客户端启动时读取本地配置的 Gateway Token
2. 连接 Gateway WebSocket
3. 自动发送 Token 认证
4. 调用 `node.pair.request` 请求配对
5. 调用 `node.pair.approve` 自动批准
6. 保存返回的 Device Token
7. 后续自动使用 Device Token 连接

**优点：**
- 用户只需配置一次 Gateway Token
- 配对完全自动化
- 支持"静默配对"（silent: true）

**缺点：**
- 需要在客户端存储 Gateway Token

### 方案 2：Gateway 预配置自动批准

**流程：**
1. Gateway 启动时配置 `gateway.auth.autoApprove: true`
2. 客户端连接时自动批准

**优点：**
- 客户端更简单

**缺点：**
- 安全风险：任何知道 Gateway 地址的客户端都能配对
- 需要修改 OpenClaw 配置

### 最终方案：方案 1 + 方案 2 结合

1. **Gateway 配置固定 Token**
   ```json
   {
     "gateway": {
       "auth": {
         "mode": "token",
         "token": "cryptoclaw-gateway-token-xxxxx"
       }
     }
   }
   ```

2. **客户端内置 Token**
   - 从 `.env` 文件读取 `OPENCLAW_GATEWAY_TOKEN`
   - 或从环境变量读取

3. **一键配对按钮**
   ```javascript
   async function connectAndPair() {
     // 1. 连接 Gateway
     const ws = new WebSocket('ws://127.0.0.1:19001');
     
     // 2. 发送 Gateway Token
     ws.send(JSON.stringify({
       type: 'auth',
       token: gatewayToken
     }));
     
     // 3. 请求配对
     const pairRequest = await rpc.call('node.pair.request', {
       nodeId: clientId,
       silent: true
     });
     
     // 4. 自动批准
     await rpc.call('node.pair.approve', {
       requestId: pairRequest.requestId
     });
     
     // 5. 保存 Device Token
     store.set('deviceToken', pairRequest.deviceToken);
     
     // 6. 连接成功
     console.log('Paired successfully!');
   }
   ```

## 客户端代码实现

### 1. 添加 IPC 处理器

```javascript
// src/main/index.js

// Gateway 连接状态
let gatewayConnection = null;

// 连接 Gateway
ipcMain.handle('connect-gateway', async (event, { host, port, token }) => {
  const WebSocket = require('ws');
  
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(`ws://${host}:${port}`);
    
    ws.on('open', () => {
      // 发送 Gateway Token 认证
      ws.send(JSON.stringify({
        type: 'auth',
        token: token
      }));
    });
    
    ws.on('message', (data) => {
      const msg = JSON.parse(data.toString());
      
      if (msg.type === 'auth:success') {
        gatewayConnection = ws;
        resolve({ success: true, message: 'Connected to Gateway' });
      } else if (msg.type === 'auth:failed') {
        reject(new Error('Authentication failed'));
      }
    });
    
    ws.on('error', (err) => {
      reject(new Error(`Connection failed: ${err.message}`));
    });
  });
});

// 请求配对
ipcMain.handle('request-pairing', async () => {
  if (!gatewayConnection) {
    throw new Error('Not connected to Gateway');
  }
  
  const clientId = secureStore.get('clientId') || crypto.randomUUID();
  secureStore.set('clientId', clientId);
  
  return new Promise((resolve, reject) => {
    const requestId = crypto.randomUUID();
    
    // 发送配对请求
    gatewayConnection.send(JSON.stringify({
      jsonrpc: '2.0',
      id: requestId,
      method: 'node.pair.request',
      params: {
        nodeId: clientId,
        silent: true
      }
    }));
    
    // 监听响应
    const handler = (data) => {
      const msg = JSON.parse(data.toString());
      if (msg.id === requestId) {
        gatewayConnection.off('message', handler);
        if (msg.error) {
          reject(new Error(msg.error.message));
        } else {
          resolve(msg.result);
        }
      }
    };
    
    gatewayConnection.on('message', handler);
    
    // 超时
    setTimeout(() => {
      gatewayConnection.off('message', handler);
      reject(new Error('Pairing request timeout'));
    }, 10000);
  });
});

// 批准配对
ipcMain.handle('approve-pairing', async (event, { requestId }) => {
  if (!gatewayConnection) {
    throw new Error('Not connected to Gateway');
  }
  
  return new Promise((resolve, reject) => {
    const callId = crypto.randomUUID();
    
    gatewayConnection.send(JSON.stringify({
      jsonrpc: '2.0',
      id: callId,
      method: 'node.pair.approve',
      params: { requestId }
    }));
    
    const handler = (data) => {
      const msg = JSON.parse(data.toString());
      if (msg.id === callId) {
        gatewayConnection.off('message', handler);
        if (msg.error) {
          reject(new Error(msg.error.message));
        } else {
          // 保存 Device Token
          if (msg.result.deviceToken) {
            secureStore.set('deviceToken', msg.result.deviceToken);
          }
          resolve(msg.result);
        }
      }
    };
    
    gatewayConnection.on('message', handler);
    
    setTimeout(() => {
      gatewayConnection.off('message', handler);
      reject(new Error('Approve timeout'));
    }, 10000);
  });
});

// 一键配对（组合以上步骤）
ipcMain.handle('one-click-pair', async (event, { host, port, token }) => {
  try {
    // 1. 连接 Gateway
    await ipcMain.invoke('connect-gateway', { host, port, token });
    
    // 2. 请求配对
    const pairResult = await ipcMain.invoke('request-pairing');
    
    // 3. 自动批准
    const approveResult = await ipcMain.invoke('approve-pairing', {
      requestId: pairResult.requestId
    });
    
    return {
      success: true,
      deviceToken: approveResult.deviceToken,
      message: 'Pairing completed successfully'
    };
  } catch (error) {
    return {
      success: false,
      error: error.message
    };
  }
});
```

### 2. 渲染器 UI

```javascript
// public/renderer.js

async function connectGateway() {
  const host = document.getElementById('gateway-host').value || '127.0.0.1';
  const port = document.getElementById('gateway-port').value || '19001';
  const token = document.getElementById('gateway-token').value;
  
  if (!token) {
    showToast('请输入 Gateway Token', 'error');
    return;
  }
  
  try {
    showLoading('正在连接...');
    
    const result = await window.electronAPI.oneClickPair({ host, port, token });
    
    if (result.success) {
      showToast('配对成功！', 'success');
      updateConnectionStatus(true);
    } else {
      showToast(`配对失败: ${result.error}`, 'error');
    }
  } catch (error) {
    showToast(`连接失败: ${error.message}`, 'error');
  } finally {
    hideLoading();
  }
}
```

### 3. HTML 界面

```html
<!-- 设置页面 - Gateway 连接 -->
<div class="card">
  <div class="card-header">
    <h2 class="card-title">Gateway 连接</h2>
  </div>
  
  <div class="form-group">
    <label class="form-label">Gateway 地址</label>
    <input type="text" class="form-input" id="gateway-host" value="127.0.0.1">
  </div>
  
  <div class="form-group">
    <label class="form-label">端口</label>
    <input type="text" class="form-input" id="gateway-port" value="19001">
  </div>
  
  <div class="form-group">
    <label class="form-label">Gateway Token</label>
    <input type="password" class="form-input" id="gateway-token" placeholder="从 Gateway 获取">
  </div>
  
  <button class="btn btn-primary" onclick="connectGateway()">
    一键配对
  </button>
  
  <div class="connection-status">
    <span class="status-dot" id="connection-status"></span>
    <span id="connection-text">未连接</span>
  </div>
</div>
```

## 安全考虑

1. **Token 存储**
   - Gateway Token 存储在客户端加密存储中
   - Device Token 也加密存储
   - 使用 AES-256-GCM 加密

2. **自动批准风险**
   - 只有知道 Gateway Token 的客户端才能配对
   - 建议使用强 Token（至少 32 字符）

3. **Token 轮换**
   - Gateway 可以随时轮换 Token
   - 客户端需要重新配对

## 测试计划

1. **单元测试**
   - 连接 Gateway
   - Token 认证
   - 配对请求
   - 自动批准

2. **集成测试**
   - 一键配对完整流程
   - 重连使用 Device Token
   - Token 错误处理

3. **端到端测试**
   - 用户点击"一键配对"
   - 验证配对成功
   - 验证后续连接自动认证
