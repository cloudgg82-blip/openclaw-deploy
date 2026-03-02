#!/bin/bash
# 引入公共库
source ~/.openclaw/scripts/lib/common.sh
# 统一健康检查 v3.1 - 增加系统负载保护
# 正常静默，异常告警

STATE_DIR="$HOME/.openclaw/state"
STATE_FILE="$STATE_DIR/health_check_state.json"
DB="$HOME/.openclaw/memory/main.sqlite"
mkdir -p "$STATE_DIR"

# ===== 新增：系统负载保护 =====
check_system_load() {
    local load=$(uptime | awk -F'load averages:' '{print $2}' | awk '{print $1}' | tr -d ',')
    local load_int=${load%.*}
    
    # Load > 100 时跳过执行，防止外部进程导致超时
    if [[ $load_int -gt 100 ]]; then
        echo "SKIP:系统负载过高 ($load)，跳过健康检查"
        echo "状态: 系统负载保护"
        exit 0
    fi
}

# 开头先检查系统负载
check_system_load

# 获取内存压力
get_mem_pressure() {
    local free=$(top -l 1 | grep "PhysMem" | sed 's/.*, \([0-9]*\)M unused.*/\1/')
    free=${free:-0}
    [[ $free -lt 100 ]] && echo "critical:$free" || [[ $free -lt 200 ]] && echo "warning:$free" || echo "normal:$free"
}

# 紧急内存清理
emergency_cleanup() {
    find "$HOME/.openclaw/agents/main/sessions" -name "*.jsonl" -mmin +60 -delete 2>/dev/null
}

# 清理过大的会话文件
cleanup_large_sessions() {
    local max_size=1024
    local max_age_minutes=1440
    find "$HOME/.openclaw/agents/main/sessions" -name "*.jsonl" -type f \
        \( -size +${max_size}k -mmin +$max_age_minutes \) -delete 2>/dev/null
    find "$HOME/.openclaw/agents/main/sessions" -name "*.reset.*" -mmin +1440 -delete 2>/dev/null
    find "$HOME/.openclaw/agents/main/sessions" -name "*.deleted.*" -mmin +1440 -delete 2>/dev/null
}

# 异常检测
check_anomaly() {
    bash "$HOME/.openclaw/workspace/lib/anomaly_detector.sh" 2>&1 | grep -qiE "error|fail" && echo "fail" || echo "ok"
}

# 资源状态
get_resources() {
    local mem_pct=$(top -l 1 | grep "PhysMem" | awk '{print $2}' | sed 's/M//')
    local mem_total=$(/usr/sbin/sysctl -n hw.memsize 2>/dev/null | awk '{printf "%.0f", $1/1024/1024/1024}' || echo "8")
    mem_pct=$((mem_pct * 100 / (mem_total * 1024)))
    local disk_pct=$(df -h / | tail -1 | awk '{print $5}' | tr -d '%')
    local load=$(uptime | awk '{print $10}' | tr -d ',')
    echo "mem:$mem_pct disk:$disk_pct load:$load"
}

# 记忆健康评分
get_mem_health() {
    [[ ! -f "$DB" ]] && echo "score:0" && return
    local l3=$(sqlite3 "$DB" "SELECT COUNT(DISTINCT memory_key) FROM memory_events WHERE layer = 'L3' AND event_at > datetime('now', '-30 days');" 2>/dev/null)
    local score=$((l3 * 60))
    [[ $score -gt 100 ]] && score=100
    [[ -z "$l3" || "$l3" -eq 0 ]] && score=30
    echo "score:$score"
}

# Gateway 优雅重启
check_gateway() {
    local pid_file="$HOME/.openclaw/gateway.pid"
    local lock_file="$HOME/.openclaw/gateway.lock"
    local current_pid=""
    [[ -f "$pid_file" ]] && current_pid=$(cat "$pid_file" 2>/dev/null)
    if [[ -n "$current_pid" ]] && kill -0 "$current_pid" 2>/dev/null; then
        return 0
    fi
    [[ -f "$lock_file" ]] && rm -f "$lock_file"
    [[ -f "$pid_file" ]] && rm -f "$pid_file"
    pkill -f "openclaw-gateway" 2>/dev/null
    sleep 1
    nohup openclaw gateway --port 18789 > /dev/null 2>&1 &
    echo "Gateway 已重启 (PID: $!)"
}

# 评估状态
evaluate() {
    local prev="$1"
    local anomaly="$2"
    local mem="$3"
    local pressure="$4"
    local score="$5"
    local mem_cons=$(echo "$prev" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('memory_consecutive',0))" 2>/dev/null || echo "0")
    local disk_cons=$(echo "$prev" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('disk_consecutive',0))" 2>/dev/null || echo "0")
    local p_level=$(echo "$pressure" | cut -d: -f1)
    local p_val=$(echo "$pressure" | cut -d: -f2)
    [[ "$p_level" == "critical" ]] && { emergency_cleanup; echo "CRITICAL:内存紧急 (${p_val}MB)"; echo "mem_cons:0 disk_cons:0"; return; }
    [[ "$p_level" == "warning" ]] && { echo "WARNING:内存警告 (${p_val}MB)"; echo "mem_cons:0 disk_cons:0"; return; }
    cleanup_large_sessions
    [[ "$anomaly" == "fail" ]] && { echo "CRITICAL:异常检测失败"; echo "mem_cons:0 disk_cons:0"; return; }
    [[ $mem -gt 95 ]] && mem_cons=$((mem_cons + 1)) || mem_cons=0
    [[ $disk -gt 80 ]] && disk_cons=$((disk_cons + 1)) || disk_cons=0
    [[ $mem_cons -ge 3 ]] && echo "WARNING:内存持续偏高" || [[ $disk_cons -ge 2 ]] && echo "WARNING:磁盘空间不足" || echo "OK:状态正常"
    echo "mem_cons:$mem_cons disk_cons:$disk_cons"
}

# ===== 主流程 =====
prev_state=$(cat "$STATE_FILE" 2>/dev/null || echo '{}')
check_gateway
pressure=$(get_mem_pressure)
anomaly=$(check_anomaly)
resources=$(get_resources)
health=$(get_mem_health)
mem=$(echo "$resources" | grep -o 'mem:[0-9]*' | cut -d: -f2)
disk=$(echo "$resources" | grep -o 'disk:[0-9]*' | cut -d: -f2)
score=$(echo "$health" | cut -d: -f2)
eval_result=$(evaluate "$prev_state" "$anomaly" "$mem" "$pressure" "$score")
status=$(echo "$eval_result" | head -1)
mem_cons=$(echo "$eval_result" | grep "mem_cons:" | cut -d: -f2 | awk '{print $1}')
disk_cons=$(echo "$eval_result" | grep "disk_cons:" | cut -d: -f2 | awk '{print $1}')
p_level=$(echo "$pressure" | cut -d: -f1)
new_state="{\"memory_consecutive\":$mem_cons,\"disk_consecutive\":$disk_cons,\"pressure_level\":\"$p_level\",\"last_check\":\"$(date -Iseconds)\",\"last_status\":\"$status\",\"health_score\":$score}"
echo "$new_state" > "$STATE_FILE"
echo "----------------------------------------"
echo "  OpenClaw 健康检查 v3.1 - $(date '+%H:%M:%S')"
echo "----------------------------------------"
echo "内存压力: $pressure"
echo "异常检测: $anomaly"
echo "资源: 内存${mem}% 磁盘${disk}%"
echo "健康评分: $score/100"
echo "状态: $status"
echo "----------------------------------------"
if echo "$status" | grep -qE "WARNING|CRITICAL"; then
    log_warn " 告警: $status"
else
    log_info " 正常"
fi
echo ""
