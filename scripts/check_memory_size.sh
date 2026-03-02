#!/bin/bash
# 引入公共库
source ~/.openclaw/scripts/lib/common.sh
# ═══════════════════════════════════════════════════════════════════
# 记忆数据量监控 - 超过阈值时提醒启用向量数据库
# 阈值: 100MB
# ═══════════════════════════════════════════════════════════════════

THRESHOLD_MB=100
MEMORY_DIR="$HOME/.openclaw/memory"
STATE_FILE="$HOME/.openclaw/state/memory_size_alert.json"

# 获取当前记忆目录大小
size_mb=$(du -sm "$MEMORY_DIR" 2>/dev/null | cut -f1)

echo "当前记忆数据量: ${size_mb}MB (阈值: ${THRESHOLD_MB}MB)"

# 检查是否超过阈值
if [ "$size_mb" -gt "$THRESHOLD_MB" ]; then
    log_warn " 记忆数据量超过阈值，建议启用 memory-lancedb"
    
    # 记录状态
    mkdir -p "$(dirname "$STATE_FILE")"
    echo "{\"checked_at\": \"$(date -Iseconds)\", \"size_mb\": $size_mb, \"threshold_mb\": $THRESHOLD_MB, \"alert\": true}" > "$STATE_FILE"
    
    # 退出码 1 表示需要提醒
    exit 1
else
    log_info " 记忆数据量正常"
    mkdir -p "$(dirname "$STATE_FILE")"
    echo "{\"checked_at\": \"$(date -Iseconds)\", \"size_mb\": $size_mb, \"threshold_mb\": $THRESHOLD_MB, \"alert\": false}" > "$STATE_FILE"
    exit 0
fi
