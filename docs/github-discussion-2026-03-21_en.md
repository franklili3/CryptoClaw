# Dev Log: 2026-03-21 - Installation Experience & Local Build Support

## Overview

Today's focus was on **improving the first-time installation experience**, especially for developers building locally.

---

## Completed Work

### 1. Installer Script Improvements

#### Problem
The original installer assumed users download pre-built artifacts from GitHub Releases, not considering developers building locally.

#### Solution
Modified `scripts/install.sh` to detect local builds:

**Docker Image Detection:**
```bash
# Check if local image exists first
if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${IMAGE}$"; then
    echo -e "${GREEN}[✓]${NC} Local image exists: $IMAGE"
    return 0
fi
```

**Client Local Build Detection:**
```bash
# Prefer locally built client
if [ -f "$LOCAL_CLIENT" ]; then
    echo -e "${GREEN}[✓]${NC} Found locally built client"
    cp "$LOCAL_CLIENT" "$CLIENT_FILE"
    return 0
fi
```

#### Rationale
1. **Local First**: Local builds are usually the latest development version
2. **Remote Fallback**: Download from GitHub only when local doesn't exist
3. **Zero Config**: Auto-detect, no user path specification needed

---

### 2. Docker Registry Mirror Troubleshooting

#### Problem
TLS handshake failures when using Aliyun Docker registry mirror in mainland China:

```
ERROR: failed to solve: node:22-alpine: failed to resolve source metadata
```

#### Debugging Process
1. Tried multiple mirrors (Aliyun, DaoCloud, custom)
2. Finally succeeded with `https://hub.rat.dev`

#### Solution
Updated `~/.docker/daemon.json`:
```json
{
  "dns": ["8.8.8.8", "114.114.114.114"],
  "registry-mirrors": ["https://hub.rat.dev"]
}
```

#### Lessons Learned
- Mirror stability varies, needs regular testing
- Consider adding mirror troubleshooting guide in docs

---

### 3. macOS ARM64 Client Build

#### Problem
Only Linux AppImage existed in `dist/`, missing macOS .dmg file.

#### Solution
Ran Electron Builder build:
```bash
cd client && npm run build:mac
```

#### Build Artifacts
- `CryptoQClaw-1.0.0-arm64.dmg` (92 MB) - Apple Silicon
- `CryptoQClaw-1.0.0-arm64-mac.zip` - Backup format

---

### 4. End-to-End Installation Test

#### Test Environment
- macOS 15 (Apple Silicon M2)
- Docker Desktop 29.2.0
- Node.js 24.13.0

#### Test Results
| Step | Status |
|------|--------|
| Docker Image Build | ✅ Success |
| macOS Client Build | ✅ Success |
| Installer Execution | ✅ Success |
| Gateway Container Start | ✅ Success |
| Client Launch | ✅ Success |

---

## Key Decisions

### Decision 1: Local Build First
**Choice**: Installer prefers local build artifacts
**Rationale**:
- Developers usually test latest code locally
- Avoids CI/CD build delays
- Supports offline installation scenarios

### Decision 2: Keep Remote Download Fallback
**Choice**: Still download from GitHub when local doesn't exist
**Rationale**:
- Compatible with non-developer users
- Supports direct installation from Releases

### Decision 3: Configurable Docker Mirror
**Choice**: Use `daemon.json` config instead of hardcoding
**Rationale**:
- Different users in different regions have different needs
- Easier troubleshooting and switching

---

## Open Issues

1. **Windows Support**: Need to create `.ps1` installer script
2. **Auto-Update**: Client missing `app-update.yml`
3. **i18n**: Installer only supports English output

---

## Next Steps

1. Improve installation docs, add mirror troubleshooting guide
2. Test Linux installation flow
3. Consider adding Windows support
4. Explore GStack workflow integration

---

## Related Links

- [Installation Docs](../README.md#installation)
- [Technical Spec](./technical-spec.md)
- [Design Doc](./design.md)

---

*This post was AI-assisted, compiled from today's development session records.*
