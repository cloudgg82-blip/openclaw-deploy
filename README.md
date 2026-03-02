# OpenClaw 部署配置

本仓库包含 OpenClaw 的配置和核心脚本。

## 使用方法

### 首次部署

```bash
# 克隆后运行
git clone https://github.com/cloudgg82-blip/openclaw-deploy.git
cd openclaw-deploy
./deploy.sh
```

### 增量更新

```bash
./deploy.sh update
```

## 包含内容

- `configs/` - 配置文件
- `scripts/` - 核心脚本
- `optional/` - 可选组件

## 首次配置（必需）

部署后需要编辑 `configs/openclaw.json` 替换以下占位符：

| 占位符 | 说明 | 获取方式 |
|--------|------|----------|
| `${OPENCLAW_API_KEY}` | MiniMax API Key | [MiniMax 开放平台](https://platform.minimaxi.com) |
| `${FEISHU_APP_ID}` | 飞书 App ID | [飞书开放平台](https://open.feishu.cn) |
| `${FEISHU_APP_SECRET}` | 飞书 App Secret | 同上 |
| `${OPENCLAW_TOKEN}` | 渠道 Token | 根据渠道类型获取 |

## 安全说明

- ✅ 配置文件已脱敏，不含实际凭证
- ✅ 凭证目录 (credentials/) 不纳入仓库
- ⚠️ 部署后请立即替换上述占位符

## 验证部署

```bash
openclaw status
```
