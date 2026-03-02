# 🤖 OpenClaw AI 助手系统

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

---

## 🛠️ 已包含工具脚本

| 脚本 | 功能 |
|------|------|
| `unified_memory.sh` | 统一记忆管理 |
| `unified_health_check.sh` | 系统健康检查 |
| `unified_maintenance.sh` | 统一维护（日志轮转、清理） |
| `model_select.sh` | 模型分级（简单任务用 M2.1） |
| `memory_cleanup.sh` | 记忆 TTL 清理 |
| `check_memory_size.sh` | 记忆数据量监控 |
| `skill_loader.sh` | 技能自动加载 |
| `skill_access_auto.sh` | 技能使用统计 |

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
