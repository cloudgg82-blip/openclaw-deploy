#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
#  极简日志轮转 v1.0
#  功能：自动轮转超过 2MB 的日志文件
# ═══════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

LOG_DIR="$HOME/.openclaw/logs"
ARCHIVE_DIR="$LOG_DIR/archives"
MAX_SIZE=2097152  # 2MB

# 确保归档目录存在
mkdir -p "$ARCHIVE_DIR"

log_info "开始日志轮转检查..."

for log in "$LOG_DIR"/*.log; do
    [ -f "$log" ] || continue
    
    # 兼容 macOS 和 Linux
    size=$(stat -f%z "$log" 2>/dev/null || stat -c%s "$log")
    
    if [ "$size" -gt "$MAX_SIZE" ]; then
        filename=$(basename "$log")
        timestamp=$(date +%Y%m%d_%H%M%S)
        
        # 压缩并移动
        gzip -c "$log" > "$ARCHIVE_DIR/${filename}.${timestamp}.gz"
        
        # 清空原文件（保持句柄）
        : > "$log"
        
        log_info "轮转: $filename ($((size/1024/1024))MB -> archives/)"
    fi
done

log_info "日志轮转完成"
