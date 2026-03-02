#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# 模型分级选择器
# 功能：根据规则选择 M2.1 或 M2.5 并记录日志
# ═══════════════════════════════════════════════════════════════════

SCRIPT_DIR="$HOME/.openclaw/scripts"
LOG_FILE="$HOME/.openclaw/logs/model_routing.log"
DB_DIR="$HOME/.openclaw/data/adaptive"
DB_FILE="$DB_DIR/model_routing.db"

# 升级关键词
UPGRADE_KEYWORDS="系统设计|优化方案|深度分析|架构|分析|评估|比较|方案|设计|implement|design|architecture|optimize"

# 初始化数据库
init_db() {
    mkdir -p "$DB_DIR"
    if [ ! -f "$DB_FILE" ]; then
        sqlite3 "$DB_FILE" "CREATE TABLE model_routing_log (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp DATETIME DEFAULT NOW,
            query TEXT,
            model_used TEXT,
            upgraded INTEGER DEFAULT 0,
            reason TEXT
        );"
    fi
}

# Token 估算（简单实现）
estimate_tokens() {
    echo "$1" | wc -c | awk '{print int($1/2)}'
}

# 检查关键词
check_keyword() {
    echo "$1" | grep -iqE "$UPGRADE_KEYWORDS"
    return $?
}

# 选择模型
select_model() {
    local query="$1"
    local tokens=$(estimate_tokens "$query")
    local model="M2.1"
    local upgraded=0
    local reason="default"
    
    # 关键词检查
    if check_keyword "$query"; then
        model="M2.5"
        upgraded=1
        reason="keyword"
    # Token 超过阈值
    elif [ "$tokens" -gt 4000 ]; then
        model="M2.5"
        upgraded=1
        reason="token_overflow"
    fi
    
    # 记录日志
    init_db
    sqlite3 "$DB_FILE" "INSERT INTO model_routing_log (query, model_used, upgraded, reason) 
        VALUES ('${query:0:100}', '$model', $upgraded, '$reason')"
    
    # 输出日志
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] query='${query:0:30}...' model=$model upgraded=$upgraded reason=$reason" >> "$LOG_FILE"
    
    echo "$model"
}

# 统计功能
stats() {
    init_db
    echo "=== 模型分级统计 ==="
    echo ""
    echo "总调用次数:"
    sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM model_routing_log"
    echo ""
    echo "按模型分布:"
    sqlite3 "$DB_FILE" "SELECT model_used, COUNT(*) as count FROM model_routing_log GROUP BY model_used"
    echo ""
    echo "按原因分布:"
    sqlite3 "$DB_FILE" "SELECT reason, COUNT(*) as count FROM model_routing_log GROUP BY reason"
    echo ""
    echo "升级比例:"
    sqlite3 "$DB_FILE" "SELECT ROUND(CAST(SUM(upgraded) AS FLOAT) / COUNT(*) * 100, 1) || '%' FROM model_routing_log"
}

# 主逻辑
case "$1" in
    select)
        select_model "$2"
        ;;
    stats)
        stats
        ;;
    *)
        echo "用法: $0 <select|stats> [query]"
        echo "  select [query]  - 选择模型并记录"
        echo "  stats           - 显示统计"
        ;;
esac
