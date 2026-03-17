# 🗑️ OpenClaw 卸载脚本

完整卸载 OpenClaw 及其所有组件。

## ✨ 特性

- ✅ 完整卸载 OpenClaw CLI 和 Gateway
- ✅ 清理配置文件和缓存
- ✅ 移除 npm 全局包
- ✅ 清理 Shell 集成
- ✅ 移除系统服务 (systemd/launchd)
- ✅ 交互式确认，安全可靠
- ✅ 自动备份 shell 配置文件

## 🎯 支持平台

| 平台 | 脚本 | 说明 |
|------|------|------|
| macOS / Linux | `uninstall.sh` | Bash 脚本 |
| Windows (CMD) | `uninstall.bat` | 批处理脚本 |
| Windows (PowerShell) | `uninstall.ps1` | PowerShell 脚本 |

## 🚀 使用方法

### macOS / Linux

```bash
bash uninstall.sh
```

### Windows (CMD)

```cmd
uninstall.bat
```

### Windows (PowerShell)

```powershell
.\uninstall.ps1
```

## 📦 卸载内容

脚本会移除以下内容：

### 1. OpenClaw 程序
- OpenClaw CLI (`openclaw` 命令)
- OpenClaw Gateway 服务
- npm 全局包：`openclaw`, `@openclaw/gateway`, `@openclaw/cli`

### 2. 配置文件
- `~/.openclaw/` 目录（会二次确认）
  - 配置文件
  - 工作区数据
  - 插件和扩展
  - 会话历史

### 3. Shell 集成
- `.bashrc` / `.bash_profile`
- `.zshrc`
- `.config/fish/config.fish`
- 自动备份原文件

### 4. 系统服务
- **macOS**: `~/Library/LaunchAgents/ai.openclaw.gateway.plist`
- **Linux**: `~/.config/systemd/user/openclaw-gateway.service`
- **Windows**: 注册表和服务项

### 5. 缓存文件
- `~/.cache/openclaw/` (Linux)
- `~/Library/Caches/openclaw/` (macOS)
- `%LOCALAPPDATA%\openclaw\` (Windows)

## 🛡️ 安全特性

### 交互式确认

脚本会在执行前显示将要删除的内容，并要求确认：

```
⚠ This will remove:
  • OpenClaw CLI and Gateway
  • Configuration files in ~/.openclaw
  • Global npm packages (openclaw, @openclaw/*)
  • Shell integration (if installed)

Continue with uninstallation? (y/N):
```

### 配置文件二次确认

删除 `~/.openclaw` 目录前会再次确认：

```
Remove ~/.openclaw directory? This will delete all your data. (y/N):
```

### 自动备份

Shell 配置文件在修改前会自动备份：

```
~/.bashrc.backup.1710691200
~/.zshrc.backup.1710691200
```

## 📝 运行示例

### macOS / Linux

```bash
$ bash uninstall.sh

OpenClaw Uninstaller

⚠ This will remove:
  • OpenClaw CLI and Gateway
  • Configuration files in ~/.openclaw
  • Global npm packages (openclaw, @openclaw/*)
  • Shell integration (if installed)

Continue with uninstallation? (y/N): y

▸ Stopping OpenClaw Gateway
✓ Gateway stopped

▸ Checking for launchd service
✓ Removed launchd service

▸ Removing npm packages
✓ Removed openclaw
✓ Removed @openclaw/gateway
✓ Removed @openclaw/cli

▸ Removing shell integration
✓ Removed integration from ~/.zshrc

▸ Cleaning up cache
✓ Removed ~/.cache/openclaw

▸ Removing configuration files
Remove ~/.openclaw directory? This will delete all your data. (y/N): y
✓ Removed ~/.openclaw

✓ OpenClaw has been uninstalled

ℹ Note: Node.js was not removed (it may be used by other applications)
ℹ If you want to remove Node.js, please do so manually

ℹ Please restart your shell or run: source ~/.zshrc
```

## ⚠️ 注意事项

1. **数据备份**：卸载前建议备份 `~/.openclaw` 目录
2. **Node.js 保留**：脚本不会删除 Node.js（可能被其他应用使用）
3. **Shell 重启**：卸载后需要重启 shell 或执行 `source ~/.bashrc`
4. **权限要求**：
   - macOS/Linux: 可能需要 `sudo` 权限删除全局 npm 包
   - Windows: 需要管理员权限运行

## 🔧 手动卸载

如果脚本无法运行，可以手动执行以下步骤：

### 1. 停止 Gateway

```bash
openclaw gateway stop
```

### 2. 卸载 npm 包

```bash
npm uninstall -g openclaw @openclaw/gateway @openclaw/cli
```

### 3. 删除配置文件

```bash
rm -rf ~/.openclaw
```

### 4. 清理 Shell 集成

编辑 `~/.bashrc` 或 `~/.zshrc`，删除包含 `openclaw` 的行。

### 5. 移除系统服务

**macOS:**
```bash
launchctl unload ~/Library/LaunchAgents/ai.openclaw.gateway.plist
rm ~/Library/LaunchAgents/ai.openclaw.gateway.plist
```

**Linux:**
```bash
systemctl --user stop openclaw-gateway
systemctl --user disable openclaw-gateway
rm ~/.config/systemd/user/openclaw-gateway.service
systemctl --user daemon-reload
```

## 🤝 反馈

如有问题，请在 [GitHub Issues](https://github.com/BrathonBai/openclaw-scripts/issues) 提交。

## 📄 许可证

MIT License

---

**返回 [主页](../README.md)**
