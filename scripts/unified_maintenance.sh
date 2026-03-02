#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# 统一维护脚本
# 功能：日志轮转 + 记忆TTL清理 + SQLite vacuum
# 频率：每天4:00（vacuum 每周日）
# ═══════════════════════════════════════════════════════════════════

SCRIPT_DIR="$HOME/.openclaw/scripts"
LOG_FILE="$HOME/.openclaw/logs/maintenance.log"
DAY_OF_WEEK=$(date +%u)  # 1-7 (1=周一)

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 主逻辑
main() {
    log "=== 开始统一维护 ==="
    
    # 1. 日志轮转（每天）
    log "[1/3] 执行日志轮转..."
    bash "$SCRIPT_DIR/lib/log_rotator.sh" 2>&1 | tee -a "$LOG_FILE"
    
    # 2. Memory TTL Cleanup（每天）
    log "[2/3] 执行 Memory TTL 清理..."
    bash "$SCRIPT_DIR/unified_memory.sh" cleanup 2>&1 | tee -a "$LOG_FILE"
    
    # 3. SQLite vacuum（仅周日，DAY_OF_WEEK=7）
    if [ "$DAY_OF_WEEK" = "7" ]; then
        log "[3/3] 执行 SQLite vacuum..."
        # 查找并 vacuum SQLite 数据库
        for db in ~/.openclaw/*.db ~/.openclaw/**/*.db; do
            if [ -f "$db" ]; then
                log "Vacuum: $db"
                sqlite3 "$db" "VACUUM;" 2>&1 | tee -a "$LOG_FILE" || true
            fi
        done
    else
        log "[3/3] 跳过 vacuum（仅周日执行）"
    fi
    
    log "=== 统一维护完成 ==="
}

main
