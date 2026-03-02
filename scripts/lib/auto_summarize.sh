#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
#  自动摘要触发器 v1.0
#  功能：Token 超阈值时自动调用 M2.1 生成上下文快照
# ═══════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "$0")"

# 引入公共库
source "$SCRIPT_DIR/common.sh"

# 配置
DB_PATH="$HOME/.openclaw/data/adaptive/behavior.db"
MEMORY_DIR="$HOME/.openclaw/memory"
LOG_DIR="$HOME/.openclaw/logs"

# MiniMax API (使用 OpenClaw OAuth 配置)
API_URL="https://api.minimax.io/v1/text/chatcompletion_v2"
MODEL="abab6.5s-chat"  # M2.1-lightning

# 可调参数
TOKEN_THRESHOLD="${TOKEN_THRESHOLD:-8000}"  # 8GB Mac 激进阈值
MEMORY_THRESHOLD="${MEMORY_THRESHOLD:-200}"  # 内存 MB
MAX_RECORDS="10"  # 摘要记录数（优化：减少输入 token）

# ─────────────────────────────────────────────────────────────────
log_info "开始自动摘要检查..."

# 1. 检查是否需要触发摘要
if check_token_threshold $TOKEN_THRESHOLD; then
    log_info "Token 未超阈值 ($TOKEN_THRESHOLD)，跳过摘要"
    exit 0
fi

# 2. 检查内存压力
if ! check_memory_pressure $MEMORY_THRESHOLD; then
    log_warn "内存压力高，跳过摘要以保护系统"
    exit 1
fi

# 3. 提取最近对话上下文（优化：只取 action 字段，减少输入 token）
log_info "提取最近 $MAX_RECORDS 条行为记录..."

CONTEXT_RAW=$(sqlite3 "$DB_PATH" \
    "SELECT action FROM behavior ORDER BY id DESC LIMIT $MAX_RECORDS;" 2>/dev/null)

if [ -z "$CONTEXT_RAW" ]; then
    log_warn "没有找到可摘要的记录"
    exit 0
fi

log_info "调用 M2.1 生成摘要..."

# 4. 调用 MiniMax API
RESPONSE=$(curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer minimax-oauth" \
  -d "$(jq -n \
    --arg model "$MODEL" \
    --arg context "$CONTEXT_RAW" \
    '{
      "model": $model,
      "messages": [
        {"role": "system", "content": "你是上下文压缩助手。请总结以下对话历史，提取：1.核心技术逻辑 2.当前待办事项 3.关键变量/路径信息。字数控制在300字以内。"},
        {"role": "user", "content": "请摘要：\n" + $context}
      ]
    }')")

# 5. 解析响应
SUMMARY=$(echo "$RESPONSE" | jq -r '.choices[0].message.content // empty')

if [ -z "$SUMMARY" ] || [ "$SUMMARY" = "null" ]; then
    log_error "API 调用失败: $RESPONSE"
    exit 1
fi

# 6. 保存摘要到记忆文件
TIMESTAMP=$(date +%Y-%m-%d_%H%M%S)
SNAPSHOT_FILE="$MEMORY_DIR/snapshot_${TIMESTAMP}.md"

cat > "$SNAPSHOT_FILE" << EOF
# 上下文快照 - $TIMESTAMP

## 摘要
$SUMMARY

## 原始记录 (已归档)
$(echo "$CONTEXT_RAW" | head -5)
...
EOF

log_info "摘要已保存: $SNAPSHOT_FILE"

# 7. 清理旧记录 (优化：保留 30 条，减少数据库压力)
OLD_COUNT=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM behavior;" 2>/dev/null)
if [ "$OLD_COUNT" -gt 30 ]; then
    DELETE_COUNT=$((OLD_COUNT - 30))
    sqlite3 "$DB_PATH" "DELETE FROM behavior WHERE id IN (SELECT id FROM behavior ORDER BY id ASC LIMIT $DELETE_COUNT);" 2>/dev/null
    log_info "已清理 $DELETE_COUNT 条旧记录"
fi

log_info "自动摘要完成 ✅"
echo "[TRIGGER_COMPACT] 摘要已生成"
