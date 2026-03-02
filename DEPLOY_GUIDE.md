# OpenClaw AI 助手系统 - 部署指南

## 一、系统概述

OpenClaw 是一款面向个人的 AI 助手系统，支持多渠道接入、智能对话、任务自动化等功能。

---

## 二、核心功能

| 功能模块 | 功能说明 |
|----------|----------|
| **多渠道消息** | 支持飞书、Telegram、Discord、WhatsApp 等消息平台 |
| **智能对话** | 基于 MiniMax 大模型（M2.1 / M2.5），支持长对话记忆 |
| **技能扩展** | 20+ 内置技能（天气、PPT生成、Excel处理等） |
| **定时任务** | Cron 自动化任务（心跳检查、日志轮转、备份等） |
| **系统监控** | 实时监控系统健康、内存、磁盘、资源告警 |
| **记忆系统** | 三层记忆架构（L1/L2/L3），自动摘要与压缩 |
| **安全防护** | 危险操作拦截、敏感信息脱敏、操作审计 |

---

## 三、硬件要求

### 3.1 最低配置

| 项目 | 要求 |
|------|------|
| **CPU** | Apple Silicon 或 Intel x86_64 |
| **内存** | 4 GB |
| **存储** | 10 GB 可用空间 |
| **网络** | 稳定互联网（需访问 GitHub、MiniMax API） |

### 3.2 推荐配置

| 项目 | 推荐 |
|------|------|
| **CPU** | Apple Silicon (M1/M2/M3) 或 Intel i5+ |
| **内存** | 8 GB 或以上 |
| **存储** | 20 GB 可用空间（SSD） |
| **网络** | 宽带（20 Mbps+） |

---

## 四、软件环境要求

### 4.1 操作系统

| 系统 | 版本 | 状态 |
|------|------|------|
| **macOS** | 12.0 (Monterey) 或更高 | ✅ 支持 |
| **Linux Ubuntu** | 20.04 或更高 | ✅ 支持 |
| **Linux Debian** | 11 或更高 | ✅ 支持 |
| **Linux CentOS** | 8 或更高 | ✅ 支持 |
| **Windows** | 不支持 | ❌ 需 WSL |

### 4.2 必要软件

| 软件 | 版本要求 | 安装方式 |
|------|----------|----------|
| **Node.js** | 20.x 或更高 | 自动安装 / 手动安装 |
| **Git** | 任意版本 | 自动安装 |
| **Homebrew** | 最新版 | macOS 自动安装 |

### 4.3 网络要求

| 域名 | 用途 |
|------|------|
| github.com | 代码仓库访问 |
| api.minimaxi.com | MiniMax 大模型 API |
| open.feishu.cn | 飞书消息 API |

---

## 五、用户需准备的凭证

### 5.1 必需凭证（3项）

| 凭证名称 | 用途说明 | 获取方式 |
|----------|----------|----------|
| **MiniMax API Key** | 调用大模型进行智能对话 | 1. 访问 https://platform.minimaxi.com<br>2. 注册/登录账号<br>3. 进入"开放平台"<br>4. 创建 API Key |
| **飞书 App ID** | 飞书消息应用标识 | 1. 访问 https://open.feishu.cn<br>2. 创建企业自建应用<br>3. 获取 App ID |
| **飞书 App Secret** | 飞书应用身份验证密钥 | 同上，在应用详情中获取 |

### 5.2 可选凭证

| 凭证名称 | 用途 | 获取方式 |
|----------|------|----------|
| **Telegram Bot Token** | Telegram 消息渠道 | @BotFather 创建机器人获取 |
| **Discord Token** | Discord 消息渠道 | Discord Developer Portal 获取 |
| **WhatsApp** | WhatsApp 渠道 | WhatsApp Business API |

---

## 六、部署后需替换的配置项

### 6.1 配置文件位置

```
~/openclaw-deploy/configs/openclaw.json
```

### 6.2 需替换的占位符

| 占位符 | 原始值 | 替换说明 |
|--------|--------|----------|
| `${OPENCLAW_API_KEY}` | （空白） | 替换为 MiniMax API Key |
| `${FEISHU_APP_ID}` | （空白） | 替换为飞书 App ID |
| `${FEISHU_APP_SECRET}` | （空白） | 替换为飞书 App Secret |
| `${OPENCLAW_TOKEN}` | （空白） | Gateway 访问 Token（可选） |

### 6.3 替换示例

```json
{
  "models": {
    "providers": {
      "minimax-portal": {
        "apiKey": "替换为你的 MiniMax API Key"
      }
    }
  },
  "channels": {
    "feishu": {
      "appId": "替换为你的飞书 App ID",
      "appSecret": "替换为你的飞书 App Secret"
    }
  }
}
```

---

## 七、一键部署命令

### 7.1 命令

```bash
curl -fsSL https://raw.githubusercontent.com/cloudgg82-blip/openclaw-deploy/main/deploy.sh | bash
```

### 7.2 部署流程

```
┌─────────────┐
│ 1. 复制命令  │
└──────┬──────┘
       ▼
┌─────────────┐
│ 2. 粘贴终端  │
└──────┬──────┘
       ▼
┌─────────────┐
│ 3. 回车执行  │
└──────┬──────┘
       ▼
┌─────────────┐
│ 4. 自动安装  │  →  约 5 分钟完成
└─────────────┘
```

---

## 八、部署后验证

### 8.1 检查服务状态

```bash
openclaw status
```

### 8.2 检查日志

```bash
tail -f ~/.openclaw/logs/gateway.log
```

### 8.3 测试消息

通过配置的渠道发送消息，验证系统响应。

---

## 九、部署检查清单

### 部署前确认

- [ ] 硬件满足最低要求
- [ ] 操作系统为 macOS 或 Linux
- [ ] 网络可访问 GitHub 和 MiniMax API
- [ ] 已获取 3 项必需凭证

### 部署后检查

- [ ] `openclaw status` 显示 running
- [ ] 配置文件已替换占位符
- [ ] 渠道消息可正常收发
- [ ] 大模型对话功能正常

---

## 十、技术支持

| 渠道 | 地址 |
|------|------|
| 文档 | https://docs.openclaw.ai |
| GitHub | https://github.com/openclaw/openclaw |
| 问题反馈 | GitHub Issues |

---

*文档版本：1.0 | 更新日期：2026-03-02*
