# OpenClaw Scripts

实用的 OpenClaw 工具脚本集合。

## 📦 包含脚本

### 1. 🔍 Search API 智能轮换器 (`search-rotator.js`)

自动在多个免费搜索 API 之间轮换，最大化免费额度使用。

**支持的搜索服务：**
- Brave Search (2000次/月)
- Serper.dev (2500次/月)
- SerpAPI (100次/月)

**特性：**
- ✅ 智能优先级轮换（优先使用额度大的）
- ✅ 自动追踪使用量
- ✅ 每月自动重置计数
- ✅ API 失败自动切换
- ✅ 实时额度显示

**使用方法：**

```bash
# 配置 API keys
node search-rotator.js configure serper YOUR_SERPER_KEY
node search-rotator.js configure serpapi YOUR_SERPAPI_KEY

# 查看额度状态
node search-rotator.js status

# 执行搜索
node search-rotator.js search "your query here"
```

**配置文件位置：**
- `~/.openclaw/search-rotation-config.json` - API 配置
- `~/.openclaw/search-rotation-state.json` - 使用状态

---

### 2. 🗑️ OpenClaw 卸载脚本

完整卸载 OpenClaw 及其所有组件。

**支持平台：**
- `uninstall.sh` - macOS / Linux
- `uninstall.bat` - Windows (CMD)
- `uninstall.ps1` - Windows (PowerShell)

**卸载内容：**
- ✅ OpenClaw CLI 和 Gateway
- ✅ 配置文件 (`~/.openclaw`)
- ✅ npm 全局包
- ✅ Shell 集成
- ✅ 系统服务 (systemd/launchd)
- ✅ 缓存文件

**使用方法：**

**macOS / Linux:**
```bash
bash uninstall.sh
```

**Windows (CMD):**
```cmd
uninstall.bat
```

**Windows (PowerShell):**
```powershell
.\uninstall.ps1
```

**安全特性：**
- 交互式确认
- 配置文件删除前二次确认
- 自动备份 shell 配置文件
- 彩色输出，清晰提示

---

## 🚀 快速开始

### 安装依赖

Search API 轮换器只需要 Node.js：

```bash
# 检查 Node.js 版本
node --version  # 需要 v14+
```

### 克隆仓库

```bash
git clone https://github.com/YOUR_USERNAME/openclaw-scripts.git
cd openclaw-scripts
```

### 使用脚本

```bash
# 给脚本添加执行权限
chmod +x search-rotator.js uninstall.sh

# 运行
./search-rotator.js status
./uninstall.sh
```

---

## 📝 配置示例

### Search API 配置

编辑 `~/.openclaw/search-rotation-config.json`：

```json
{
  "providers": [
    {
      "name": "serper",
      "apiKey": "YOUR_SERPER_KEY",
      "quota": 2500,
      "resetPeriod": "monthly",
      "priority": 1,
      "endpoint": "https://google.serper.dev/search"
    },
    {
      "name": "serpapi",
      "apiKey": "YOUR_SERPAPI_KEY",
      "quota": 100,
      "resetPeriod": "monthly",
      "priority": 2,
      "endpoint": "https://serpapi.com/search"
    }
  ]
}
```

---

## 🔧 高级用法

### Search Rotator 作为模块使用

```javascript
const SearchRotator = require('./search-rotator.js');

const rotator = new SearchRotator();

// 执行搜索
rotator.search('OpenClaw AI assistant', { count: 10 })
  .then(result => {
    console.log('Provider:', result.provider);
    console.log('Results:', result.results);
    console.log('Quota:', result.quota);
  });

// 查看状态
rotator.status();
```

### 环境变量配置

也可以通过环境变量配置 API keys：

```bash
export SERPER_API_KEY="your_key_here"
export SERPAPI_KEY="your_key_here"

node search-rotator.js search "query"
```

---

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

### 开发指南

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

---

## 📄 许可证

MIT License

---

## 🔗 相关链接

- [OpenClaw 官网](https://openclaw.ai)
- [OpenClaw 文档](https://docs.openclaw.ai)
- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
- [Serper.dev](https://serper.dev)
- [SerpAPI](https://serpapi.com)

---

## ⚠️ 注意事项

1. **API Keys 安全**：不要将 API keys 提交到 Git 仓库
2. **配额限制**：注意各服务的免费额度限制
3. **卸载确认**：卸载脚本会删除所有配置，请谨慎操作
4. **备份数据**：卸载前建议备份 `~/.openclaw` 目录

---

## 📮 反馈

如有问题或建议，请：
- 提交 [Issue](https://github.com/YOUR_USERNAME/openclaw-scripts/issues)
- 发送邮件至：your-email@example.com
- 加入 [OpenClaw Discord](https://discord.com/invite/clawd)

---

**Made with ❤️ by Brathon**
