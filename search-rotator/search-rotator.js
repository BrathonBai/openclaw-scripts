#!/usr/bin/env node
/**
 * 智能搜索 API 轮换器
 * 自动在多个免费搜索 API 之间轮换，最大化免费额度
 */

const fs = require('fs');
const path = require('path');
const https = require('https');

// 配置文件路径
const CONFIG_FILE = path.join(process.env.HOME, '.openclaw', 'search-rotation-config.json');
const STATE_FILE = path.join(process.env.HOME, '.openclaw', 'search-rotation-state.json');

// 默认配置
const DEFAULT_CONFIG = {
  providers: [
    {
      name: 'brave',
      apiKey: process.env.BRAVE_API_KEY || '',
      quota: 2000,
      resetPeriod: 'monthly',
      priority: 1,
      endpoint: 'https://api.search.brave.com/res/v1/web/search'
    },
    {
      name: 'serper',
      apiKey: process.env.SERPER_API_KEY || '',
      quota: 2500,
      resetPeriod: 'monthly',
      priority: 2,
      endpoint: 'https://google.serper.dev/search'
    },
    {
      name: 'serpapi',
      apiKey: process.env.SERPAPI_KEY || '',
      quota: 100,
      resetPeriod: 'monthly',
      priority: 3,
      endpoint: 'https://serpapi.com/search'
    }
  ]
};

// 默认状态
const DEFAULT_STATE = {
  providers: {},
  lastReset: new Date().toISOString()
};

class SearchRotator {
  constructor() {
    this.config = this.loadConfig();
    this.state = this.loadState();
    this.checkReset();
  }

  loadConfig() {
    try {
      if (fs.existsSync(CONFIG_FILE)) {
        return JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8'));
      }
    } catch (err) {
      console.error('Failed to load config:', err.message);
    }
    return DEFAULT_CONFIG;
  }

  loadState() {
    try {
      if (fs.existsSync(STATE_FILE)) {
        return JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
      }
    } catch (err) {
      console.error('Failed to load state:', err.message);
    }
    return DEFAULT_STATE;
  }

  saveConfig() {
    const dir = path.dirname(CONFIG_FILE);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    fs.writeFileSync(CONFIG_FILE, JSON.stringify(this.config, null, 2));
  }

  saveState() {
    const dir = path.dirname(STATE_FILE);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    fs.writeFileSync(STATE_FILE, JSON.stringify(this.state, null, 2));
  }

  checkReset() {
    const now = new Date();
    const lastReset = new Date(this.state.lastReset);
    
    // 检查是否需要重置（每月1号）
    if (now.getMonth() !== lastReset.getMonth() || now.getFullYear() !== lastReset.getFullYear()) {
      console.log('🔄 Monthly reset - clearing usage counters');
      this.state.providers = {};
      this.state.lastReset = now.toISOString();
      this.saveState();
    }
  }

  getAvailableProvider() {
    // 按优先级排序
    const providers = this.config.providers
      .filter(p => p.apiKey) // 只考虑有 API key 的
      .sort((a, b) => a.priority - b.priority);

    for (const provider of providers) {
      const used = this.state.providers[provider.name]?.used || 0;
      const remaining = provider.quota - used;

      if (remaining > 0) {
        return {
          ...provider,
          used,
          remaining
        };
      }
    }

    return null;
  }

  async search(query, options = {}) {
    const provider = this.getAvailableProvider();

    if (!provider) {
      throw new Error('No available search provider (all quotas exhausted)');
    }

    console.log(`🔍 Using ${provider.name} (${provider.remaining}/${provider.quota} remaining)`);

    try {
      const result = await this.executeSearch(provider, query, options);
      
      // 更新使用计数
      if (!this.state.providers[provider.name]) {
        this.state.providers[provider.name] = { used: 0 };
      }
      this.state.providers[provider.name].used++;
      this.saveState();

      return {
        provider: provider.name,
        results: result,
        quota: {
          used: this.state.providers[provider.name].used,
          remaining: provider.quota - this.state.providers[provider.name].used,
          total: provider.quota
        }
      };
    } catch (err) {
      console.error(`❌ ${provider.name} failed:`, err.message);
      
      // 如果失败，标记为已用完，尝试下一个
      this.state.providers[provider.name] = { used: provider.quota };
      this.saveState();
      
      // 递归尝试下一个 provider
      return this.search(query, options);
    }
  }

  async executeSearch(provider, query, options) {
    switch (provider.name) {
      case 'brave':
        return this.searchBrave(provider, query, options);
      case 'serper':
        return this.searchSerper(provider, query, options);
      case 'serpapi':
        return this.searchSerpAPI(provider, query, options);
      default:
        throw new Error(`Unknown provider: ${provider.name}`);
    }
  }

  async searchBrave(provider, query, options) {
    const url = new URL(provider.endpoint);
    url.searchParams.set('q', query);
    url.searchParams.set('count', options.count || 10);

    return new Promise((resolve, reject) => {
      const req = https.request(url, {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'X-Subscription-Token': provider.apiKey
        }
      }, (res) => {
        let data = '';
        res.on('data', chunk => data += chunk);
        res.on('end', () => {
          if (res.statusCode === 200) {
            resolve(JSON.parse(data));
          } else {
            reject(new Error(`HTTP ${res.statusCode}: ${data}`));
          }
        });
      });
      req.on('error', reject);
      req.end();
    });
  }

  async searchSerper(provider, query, options) {
    const postData = JSON.stringify({
      q: query,
      num: options.count || 10
    });

    return new Promise((resolve, reject) => {
      const req = https.request(provider.endpoint, {
        method: 'POST',
        headers: {
          'X-API-KEY': provider.apiKey,
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(postData)
        }
      }, (res) => {
        let data = '';
        res.on('data', chunk => data += chunk);
        res.on('end', () => {
          if (res.statusCode === 200) {
            resolve(JSON.parse(data));
          } else {
            reject(new Error(`HTTP ${res.statusCode}: ${data}`));
          }
        });
      });
      req.on('error', reject);
      req.write(postData);
      req.end();
    });
  }

  async searchSerpAPI(provider, query, options) {
    const url = new URL(provider.endpoint);
    url.searchParams.set('q', query);
    url.searchParams.set('api_key', provider.apiKey);
    url.searchParams.set('num', options.count || 10);

    return new Promise((resolve, reject) => {
      https.get(url, (res) => {
        let data = '';
        res.on('data', chunk => data += chunk);
        res.on('end', () => {
          if (res.statusCode === 200) {
            resolve(JSON.parse(data));
          } else {
            reject(new Error(`HTTP ${res.statusCode}: ${data}`));
          }
        });
      }).on('error', reject);
    });
  }

  status() {
    console.log('\n📊 Search API Status\n');
    console.log('Last reset:', new Date(this.state.lastReset).toLocaleDateString());
    console.log('');

    const providers = this.config.providers
      .filter(p => p.apiKey)
      .sort((a, b) => a.priority - b.priority);

    for (const provider of providers) {
      const used = this.state.providers[provider.name]?.used || 0;
      const remaining = provider.quota - used;
      const percentage = ((used / provider.quota) * 100).toFixed(1);
      
      const bar = this.createProgressBar(used, provider.quota);
      
      console.log(`${provider.name.padEnd(10)} ${bar} ${used}/${provider.quota} (${percentage}%)`);
    }

    const totalUsed = Object.values(this.state.providers).reduce((sum, p) => sum + (p.used || 0), 0);
    const totalQuota = providers.reduce((sum, p) => sum + p.quota, 0);
    console.log('');
    console.log(`Total: ${totalUsed}/${totalQuota} searches used this month`);
  }

  createProgressBar(used, total, width = 20) {
    const filled = Math.round((used / total) * width);
    const empty = width - filled;
    return '[' + '█'.repeat(filled) + '░'.repeat(empty) + ']';
  }

  configure(providerName, apiKey) {
    const provider = this.config.providers.find(p => p.name === providerName);
    if (!provider) {
      throw new Error(`Unknown provider: ${providerName}`);
    }
    provider.apiKey = apiKey;
    this.saveConfig();
    console.log(`✅ Configured ${providerName}`);
  }
}

// CLI
if (require.main === module) {
  const rotator = new SearchRotator();
  const args = process.argv.slice(2);
  const command = args[0];

  switch (command) {
    case 'search':
      const query = args.slice(1).join(' ');
      if (!query) {
        console.error('Usage: search-rotator.js search <query>');
        process.exit(1);
      }
      rotator.search(query)
        .then(result => {
          console.log(JSON.stringify(result, null, 2));
        })
        .catch(err => {
          console.error('Search failed:', err.message);
          process.exit(1);
        });
      break;

    case 'status':
      rotator.status();
      break;

    case 'configure':
      const [, provider, apiKey] = args;
      if (!provider || !apiKey) {
        console.error('Usage: search-rotator.js configure <provider> <api-key>');
        console.error('Providers: brave, serper, serpapi');
        process.exit(1);
      }
      rotator.configure(provider, apiKey);
      break;

    default:
      console.log('Usage:');
      console.log('  search-rotator.js search <query>     - Search with automatic rotation');
      console.log('  search-rotator.js status             - Show quota status');
      console.log('  search-rotator.js configure <provider> <key> - Configure API key');
      break;
  }
}

module.exports = SearchRotator;
