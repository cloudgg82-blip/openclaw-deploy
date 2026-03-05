# 🤖 Personal AI Assistant

> One-click deployment for your private AI assistant

## 🚀 One-Click Install (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/cloudgg82-blip/openclaw-deploy/main/deploy.sh | bash
```

### Or Clone & Deploy

```bash
git clone https://github.com/cloudgg82-blip/openclaw-deploy.git
cd openclaw-deploy
./deploy.sh
```

---

## 📋 Core Features

| Feature | Description |
|---------|-------------|
| **Multi-Channel Messaging** | Feishu, Telegram, Discord, WhatsApp |
| **Smart Conversation** | MiniMax LLMs (M2.1/M2.5), extended memory |
| **Skill System** | 20+ built-in skills (weather, PPT, Excel, web scraping, etc.) |
| **Memory System** | 3-layer architecture, auto-summarization & compression |
| **Scheduled Tasks** | Cron automation (heartbeat, log rotation, backup) |
| **System Monitoring** | Real-time health checks, memory/disk alerts |
| **Security** | Dangerous operation blocking, sensitive data masking |
| **Self-Optimization Engine** | Daily review, capability scoring, auto patch generation |

---

## 📝 Changelog

Auto-synced from myclaw-backup main branch on each push:

| Date | Update |
|------|--------|
| 2026-03-05 | **Self-Optimization Engine v2**: daily review, scoring, patch pipeline |
| 2026-03-04 | A-Stock hotspot system: signal scoring + RSSHub integration |
| 2026-02-26 | Beads issue tracking system integration |
| 2026-02-20 | ARCHITECTURE.md v2.0 optimization |

---

## 💻 Supported Platforms

### ✅ Supported OS

| OS | Version | Status |
|----|---------|--------|
| **macOS** | 12.0 (Monterey) or higher | ✅ Supported |
| **Linux Ubuntu** | 20.04 or higher | ✅ Supported |
| **Linux Debian** | 11 or higher | ✅ Supported |
| **Linux CentOS** | 8 or higher | ✅ Supported |
| **Linux Arch** | Latest | ✅ Supported |

### ❌ Not Supported

| OS | Note |
|----|------|
| Windows | Use WSL instead |

---

## 🖥️ Hardware Requirements

### Minimum

| Component | Requirement |
|-----------|-------------|
| CPU | Apple Silicon or Intel x86_64 |
| RAM | 4 GB |
| Storage | 10 GB free |

### Recommended

| Component | Recommended |
|-----------|-------------|
| CPU | Apple Silicon (M1/M2/M3) or Intel i5+ |
| RAM | 8 GB or more |
| Storage | 20 GB free (SSD) |

---

## 📀 Software Requirements

### Required

| Software | Version | Note |
|----------|---------|------|
| **Node.js** | 20.x or higher | Auto-installed |
| **Git** | Any version | Auto-installed |
| **Homebrew** | Latest | Auto-installed on macOS |

### Network

| Domain | Purpose |
|--------|---------|
| github.com | Repository access |
| api.minimaxi.com | MiniMax LLM API |
| open.feishu.cn | Feishu messaging API |

---

## 📦 Repository Contents

| Directory | Description |
|-----------|-------------|
| `deploy.sh` | One-click deployment script |
| `configs/` | Template config files (redacted) |
| `scripts/` | Core utility scripts |
| `optional/` | Optional components (Beads) |
| `DEPLOY_GUIDE.md` | Full deployment guide |

---

## ⚙️ Initial Configuration

After deployment, edit `configs/openclaw.json` and replace placeholders:

| Placeholder | Description | Get from |
|-------------|-------------|----------|
| `${OPENCLAW_API_KEY}` | MiniMax API Key | [platform.minimaxi.com](https://platform.minimaxi.com) |
| `${FEISHU_APP_ID}` | Feishu App ID | [open.feishu.cn](https://open.feishu.cn) |
| `${FEISHU_APP_SECRET}` | Feishu App Secret | Same as above |

---

## ✅ Verify Deployment

```bash
openclaw status
```

---

## 📖 Documentation

- [Deployment Guide](DEPLOY_GUIDE.md)
- [Official Docs](https://docs.openclaw.ai)

---

**Deploy in 5 minutes with one command!** 🚀
