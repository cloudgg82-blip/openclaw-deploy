#!/bin/bash
DB_PATH="$HOME/.openclaw/memory/memory_access.db"

if [[ -f "$DB_PATH" ]]; then
    sqlite3 "$DB_PATH" "DELETE FROM memory_access WHERE timestamp < datetime('now', '-30 days');"
    echo "[INFO] Cleaned old memory access records"
else
    echo "[INFO] No memory database found"
fi

find "$HOME/.openclaw/memory" -name "*.log" -mtime +7 -delete 2>/dev/null
echo "[INFO] Memory cleanup completed"
