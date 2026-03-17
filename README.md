# OpenClaw Scripts

实用的 OpenClaw 工具脚本集合。

## 📦 脚本列表

### 🔍 [Search API 智能轮换器](./search-rotator/)

自动在多个免费搜索 API 之间轮换，最大化免费额度使用。

- 支持 Serper.dev (2500次/月) 和 SerpAPI (100次/月)
- 智能优先级轮换
- 自动追踪使用量
- 每月自动重置

[查看详细文档 →](./search-rotator/README.md)

---

### 🗑️ [OpenClaw 卸载脚本](./uninstaller/)

完整卸载 OpenClaw 及其所有组件。

- 支持 macOS / Linux / Windows
- 交互式确认
- 自动备份配置
- 清理所有相关文件

[查看详细文档 →](./uninstaller/README.md)

---

## 🚀 快速开始

```bash
# 克隆仓库
git clone https://github.com/BrathonBai/openclaw-scripts.git
cd openclaw-scripts

# 使用 Search API 轮换器
cd search-rotator
node search-rotator.js status

# 使用卸载脚本
cd uninstaller
bash uninstall.sh  # macOS/Linux
```

---

## 📄 许可证

MIT License - 详见 [LICENSE](./LICENSE)

---

## 🔗 相关链接

- [OpenClaw 官网](https://openclaw.ai)
- [OpenClaw 文档](https://docs.openclaw.ai)
- [OpenClaw GitHub](https://github.com/openclaw/openclaw)

---

**Made with ❤️ by Brathon**
