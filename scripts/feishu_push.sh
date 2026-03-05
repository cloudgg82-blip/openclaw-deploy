#!/bin/bash
# 飞书群机器人推送脚本 (优化版)
# 优化：添加缓存，减少重复API调用

WEBHOOK="https://open.feishu.cn/open-apis/bot/v2/hook/89aa82c6-07f8-41ba-97d5-4c809709bcce"
CACHE_DIR="/tmp/clawdbot/cache"
CACHE_TTL=300  # 缓存5分钟

# 初始化缓存目录
mkdir -p "$CACHE_DIR"

# 获取日期时间
DATE=$(date "+%Y-%m-%d %H:%M")

# 缓存读取
get_cache() {
    local key="$1"
    local cache_file="$CACHE_DIR/$key.cache"
    if [ -f "$cache_file" ]; then
        local age=$(($(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file" 2>/dev/null)))
        if [ "$age" -lt "$CACHE_TTL" ]; then
            cat "$cache_file"
            return 0
        fi
    fi
    return 1
}

# 缓存写入
set_cache() {
    local key="$1"
    local value="$2"
    echo "$value" > "$CACHE_DIR/$key.cache"
}

# 构建消息
build_msg() {
    local title="$1"
    local content="$2"
    echo "【$title】$DATE
$content"
}

# 1. 健康检查 (缓存)
check_health() {
    if get_cache "health"; then
        return
    fi
    local result=$(~/.openclaw/scripts/unified_health_check.sh health 2>/dev/null | tail -6 | sed 's/\x1b\[[0-9;]*m//g')
    if [ -z "$result" ]; then
        result="✅ 系统正常"
    fi
    set_cache "health" "$result"
    echo "$result"
}

# 2. MiniMax剩余次数 (已禁用)
check_minimax() {
    echo "（MiniMax监控已禁用）"
}

# 3. 每周汇总
weekly_summary() {
    echo "📊 周报：
- 会话数、X次
- Token消耗
- 待办事项、X项"
}

# 发送消息 (单次curl)
send_msg() {
    local msg="$1"
    local escaped_msg=$(echo "$msg" | awk '{gsub(/\\/,"\\\\"); gsub(/"/,"\\\""); printf "%s\\n", $0}' | sed 's/\\n$//')
    curl -X POST -H "Content-Type: application/json" \
        -d "{\"msg_type\":\"text\",\"content\":{\"text\":\"[告警] $escaped_msg\"}}" \
        "$WEBHOOK" 2>/dev/null
}

# 主逻辑
case "${1:-daily}" in
    daily)
        HEALTH=$(check_health)
        MSG=$(build_msg "每日汇总" "$HEALTH")
        ;;
    weekly)
        SUMMARY=$(weekly_summary)
        MSG=$(build_msg "每周汇总" "$SUMMARY")
        ;;
    *)
        MSG="$1"
        ;;
esac

send_msg "$MSG"
echo "推送完成"
