# 🤖 本地私人AI助理

> 一键部署个人 AI 助理

## 🚀 一键安装（推荐）

```bash
curl -fsSL https://raw.githubusercontent.com/cloudgg82-blip/openclaw-deploy/main/deploy.sh | bash
```

### 或克隆部署

```bash
git clone https://github.com/cloudgg82-blip/openclaw-deploy.git
cd openclaw-deploy
./deploy.sh
```

---

## 📋 系统核心功能

| 功能模块 | 说明 |
|----------|------|
| **多渠道消息** | 飞书、Telegram、Discord、WhatsApp 全支持 |
| **智能对话** | MiniMax 大模型（M2.1/M2.5），超长记忆 |
| **技能系统** | 20+ 内置技能（天气、PPT、Excel、网页抓取等） |
| **记忆系统** | 三层记忆架构，自动摘要与压缩 |
| **定时任务** | Cron 自动化（心跳检查、日志轮转、备份） |
| **系统监控** | 实时健康检测、内存/磁盘告警 |
| **安全防护** | 危险操作拦截、敏感信息脱敏 |
| **自我优化引擎** | 每日复盘、能力计分卡、自动 Patch 生成与验证 |

---

## 📝 更新日志

每次 push 到 myclaw-backup 主分支后自动同步：

### 历史更新

| 日期 | 更新内容 |
|------|---------|
| 2026-03-05 | **自我优化引擎 v2**：每日复盘、能力计分卡、Patch 生成/执行/验证闭环 |
| 2026-03-04 | A股热点识别系统：信号打分+热点主题+RSSHub接入 |
| 2026-02-26 | Beads 问题跟踪系统集成 |
| 2026-02-20 | ARCHITECTURE.md v2.0 精简方案 |

---

## 💻 支持的终端系统

### ✅ 操作系统 | 版本 支持的系统

| | 状态 |
|----------|------|------|
| **macOS** | 12.0 (Monterey) 或更高 | ✅ 完全支持 |
| **Linux Ubuntu** | 20.04 或更高 | ✅ 完全支持 |
| **Linux Debian** | 11 或更高 | ✅ 完全支持 |
| **Linux CentOS** | 8 或更高 | ✅ 完全支持 |
| **Linux Arch** | 最新版 | ✅ 完全支持 |

### ❌ 不支持

| 操作系统 | 说明 |
|----------|------|
| Windows | 需通过 WSL 运行 |

---

## 🖥️ 硬件要求

### 最低配置

| 项目 | 要求 |
|------|------|
| CPU | Apple Silicon 或 Intel x86_64 |
| 内存 | 4 GB |
| 存储 | 10 GB 可用空间 |

### 推荐配置

| 项目 | 推荐 |
|------|------|
| CPU | Apple Silicon (M1/M2/M3) 或 Intel i5+ |
| 内存 | 8 GB 或以上 |
| 存储 | 20 GB 可用空间（SSD） |

---

## 📀 软件环境要求

### 必要软件

| 软件 | 版本要求 | 说明 |
|------|----------|------|
| **Node.js** | 20.x 或更高 | 自动安装 |
| **Git** | 任意版本 | 自动安装 |
| **Homebrew** | 最新版 | macOS 自动安装 |

### 网络要求

| 域名 | 用途 |
|------|------|
| github.com | 代码仓库访问 |
| api.minimaxi.com | MiniMax 大模型 API |
| open.feishu.cn | 飞书消息 API |

---

## 📦 仓库内容

| 目录 | 说明 |
|------|------|
| `deploy.sh` | 一键部署脚本 |
| `configs/` | 脱敏配置文件 |
| `scripts/` | 核心工具脚本 |
| `optional/` | 可选组件（Beads） |
| `DEPLOY_GUIDE.md` | 完整部署指南 |

---

## ⚙️ 首次配置

部署后编辑 `configs/openclaw.json` 替换以下占位符：

| 占位符 | 说明 | 获取 |
|--------|------|------|
| `${OPENCLAW_API_KEY}` | MiniMax API Key | [platform.minimaxi.com](https://platform.minimaxi.com) |
| `${FEISHU_APP_ID}` | 飞书 App ID | [open.feishu.cn](https://open.feishu.cn) |
| `${FEISHU_APP_SECRET}` | 飞书 App Secret | 同上 |

---

## ✅ 验证部署

```bash
openclaw status
```

---

## 📖 完整文档

- [部署指南（含硬件/软件要求）](DEPLOY_GUIDE.md)
- [OpenClaw 官方文档](https://docs.openclaw.ai)

---

**5分钟部署，一个命令上手！** 🚀
