# 🔍 Search API 智能轮换器

自动在多个免费搜索 API 之间轮换，最大化免费额度使用。

## ✨ 特性

- ✅ 智能优先级轮换（优先使用额度大的）
- ✅ 自动追踪使用量
- ✅ 每月自动重置计数
- ✅ API 失败自动切换
- ✅ 实时额度显示

## 🎯 支持的搜索服务

| 服务 | 免费额度 | 优先级 |
|------|---------|--------|
| [Serper.dev](https://serper.dev) | 2500次/月 | 1 (优先) |
| [SerpAPI](https://serpapi.com) | 100次/月 | 2 (备用) |
| [Brave Search](https://brave.com/search/api/) | 2000次/月 | 3 (可选) |

**总计：最多 4600 次免费搜索/月**

## 🚀 快速开始

### 1. 配置 API Keys

```bash
# 配置 Serper.dev
node search-rotator.js configure serper YOUR_SERPER_KEY

# 配置 SerpAPI
node search-rotator.js configure serpapi YOUR_SERPAPI_KEY

# (可选) 配置 Brave Search
node search-rotator.js configure brave YOUR_BRAVE_KEY
```

### 2. 查看额度状态

```bash
node search-rotator.js status
```

输出示例：
```
📊 Search API Status

Last reset: 3/17/2026

serper     [░░░░░░░░░░░░░░░░░░░░] 0/2500 (0.0%)
serpapi    [░░░░░░░░░░░░░░░░░░░░] 0/100 (0.0%)

Total: 0/2600 searches used this month
```

### 3. 执行搜索

```bash
node search-rotator.js search "OpenClaw AI assistant"
```

## 📖 使用方法

### 命令行使用

```bash
# 搜索
node search-rotator.js search "your query here"

# 查看状态
node search-rotator.js status

# 配置 API key
node search-rotator.js configure <provider> <api-key>
```

### 作为模块使用

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
export BRAVE_API_KEY="your_key_here"

node search-rotator.js search "query"
```

## 📁 配置文件

配置文件自动保存在：

- `~/.openclaw/search-rotation-config.json` - API 配置
- `~/.openclaw/search-rotation-state.json` - 使用状态

### 配置文件示例

`~/.openclaw/search-rotation-config.json`:

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

## 🔧 工作原理

1. **优先级排序**：按 `priority` 字段排序（数字越小优先级越高）
2. **额度检查**：检查当前 provider 是否还有剩余额度
3. **自动切换**：当前 provider 额度用完或失败时，自动切换到下一个
4. **月度重置**：每月 1 号自动重置所有计数器

## 🎓 获取 API Keys

### Serper.dev
1. 访问 https://serper.dev
2. 注册账号
3. 获取 API key（免费 2500 次/月）

### SerpAPI
1. 访问 https://serpapi.com
2. 注册账号
3. 获取 API key（免费 100 次/月）

### Brave Search (可选)
1. 访问 https://brave.com/search/api/
2. 注册账号
3. 获取 API key（免费 2000 次/月，需付费订阅）

## ⚠️ 注意事项

1. **API Keys 安全**：不要将 API keys 提交到 Git 仓库
2. **配额限制**：注意各服务的免费额度限制
3. **月度重置**：计数器在每月 1 号自动重置
4. **失败重试**：API 失败时会自动切换到下一个 provider

## 📄 许可证

MIT License

---

**返回 [主页](../README.md)**
