#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
#  OpenClaw 公共库 - common.sh
#  提供日志、锁、配置、错误处理等公共功能
#  版本: 1.1 | 日期: 2026-02-21
# ═══════════════════════════════════════════════════════════════════

# 确保 Cron 环境能找到命令
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# ---------- 配置 ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "$0")"
LOG_DIR="${LOG_DIR:-$HOME/.openclaw/logs}"
LOCK_DIR="${LOCK_DIR:-$HOME/.openclaw/state/locks}"

# 创建必要目录
mkdir -p "$LOG_DIR" 2>/dev/null
mkdir -p "$LOCK_DIR" 2>/dev/null

# ---------- 颜色输出 ----------
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# ---------- 日志函数 ----------
log_info() {
    echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') [$SCRIPT_NAME] $*"
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') [$SCRIPT_NAME] $*" >> "$LOG_DIR/$(date +%Y-%m-%d).log" 2>/dev/null
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') [$SCRIPT_NAME] $*" >&2
    echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') [$SCRIPT_NAME] $*" >> "$LOG_DIR/$(date +%Y-%m-%d).log" 2>/dev/null
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') [$SCRIPT_NAME] $*" >&2
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') [$SCRIPT_NAME] $*" >> "$LOG_DIR/$(date +%Y-%m-%d).log" 2>/dev/null
}

log_debug() {
    if [ "${DEBUG:-0}" = "1" ]; then
        echo -e "${BLUE}[DEBUG]${NC} $(date '+%Y-%m-%d %H:%M:%S') [$SCRIPT_NAME] $*"
    fi
}

# ---------- 锁机制 ----------
# 用法: acquire_lock "script_name" [timeout_seconds]
acquire_lock() {
    local name="${1:-default}"
    local timeout="${2:-300}"
    local lock_file="$LOCK_DIR/${name}.lock"
    local start_time=$(date +%s)
    
    while [ -f "$lock_file" ]; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        if [ $elapsed -gt $timeout ]; then
            log_warn "Lock timeout: $name"
            return 1
        fi
        
        sleep 1
    done
    
    echo "$$" > "$lock_file"
    log_debug "Lock acquired: $name"
    return 0
}

# 用法: release_lock "script_name"
release_lock() {
    local name="${1:-default}"
    local lock_file="$LOCK_DIR/${name}.lock"
    
    if [ -f "$lock_file" ]; then
        rm -f "$lock_file"
        log_debug "Lock released: $name"
    fi
}

# 锁的陷阱（确保退出时释放锁）
setup_lock_trap() {
    local name="${1:-default}"
    trap "release_lock '$name'" EXIT INT TERM
}

# ---------- 配置加载 ----------
# 用法: load_config "config_key" [default_value]
load_config() {
    local key="$1"
    local default="${2:-}"
    
    # 从环境变量读取
    local value="${!key:-$default}"
    
    if [ -z "$value" ]; then
        log_debug "Config not found: $key"
    fi
    
    echo "$value"
}

# ---------- 路径解析 ----------
resolve_path() {
    local path="$1"
    
    # 处理 ~ 和 $HOME
    path="${path/#\~/$HOME}"
    path="${path//\$HOME/$HOME}"
    
    # 返回绝对路径
    if [ -d "$path" ] || [ -f "$path" ]; then
        cd "$(dirname "$path")" 2>/dev/null && pwd || echo "$path"
    else
        echo "$path"
    fi
}

# ---------- 错误处理 ----------
# 用法: handle_error "error_message" [exit_code]
handle_error() {
    local msg="$1"
    local code="${2:-1}"
    
    log_error "$msg (exit code: $code)"
    
    if [ "${IGNORE_ERRORS:-0}" != "1" ]; then
        exit $code
    fi
}

# 启用错误退出
set_error_exit() {
    set -euo pipefail
}

# 禁用错误退出（用于容忍部分失败）
unset_error_exit() {
    set +euo pipefail
}

# ---------- 进度显示 ----------
show_progress() {
    local current="$1"
    local total="$2"
    local prefix="${3:-Progress}"
    local width=30
    
    local percent=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))
    
    printf "\r${prefix}: [%s%s] %d%%" \
        "$(printf '#%.0s' $(seq 1 $filled 2>/dev/null) 2>/dev/null)" \
        "$(printf '.%.0s' $(seq 1 $empty 2>/dev/null) 2>/dev/null)" \
        $percent
}

complete_progress() {
    echo ""
    log_info "Done"
}

# ---------- 时间格式化 ----------
# 用法: timestamp [format]
timestamp() {
    local format="${1:-%Y-%m-%d %H:%M:%S}"
    date "+$format"
}

# 计算时间差（秒）
time_diff() {
    local start="$1"
    local end="${2:-$(date +%s)}"
    echo $((end - start))
}

# ---------- 简单统计 ----------
count_files() {
    local dir="$1"
    local pattern="${2:-*}"
    ls -1 "$dir"/$pattern 2>/dev/null | wc -l
}

file_size() {
    local path="$1"
    du -h "$path" 2>/dev/null | cut -f1 || echo "0"
}

# ---------- 导入检查 ----------
# 用法: require_command "command_name"
require_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "Required command not found: $1"
        return 1
    fi
    return 0
}

# 用法: require_file "file_path"
require_file() {
    if [ ! -f "$1" ]; then
        log_error "Required file not found: $1"
        return 1
    fi
    return 0
}

# 用法: require_dir "directory_path"
require_dir() {
    if [ ! -d "$1" ]; then
        log_error "Required directory not found: $1"
        return 1
    fi
    return 0
}

# ---------- JSON 解析 ----------
# 用法: json_get "json_string" "key"
json_get() {
    local json="$1"
    local key="$2"
    echo "$json" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('$key', ''))" 2>/dev/null
}

# ---------- Token 阈值检查 ----------
# 用法: check_token_threshold [threshold]
# 返回: 0=未超阈值, 1=超过阈值
check_token_threshold() {
    local threshold="${1:-10000}"
    local db="$HOME/.openclaw/data/adaptive/behavior.db"
    
    # 如果数据库文件不存在，直接跳过
    [ ! -f "$db" ] && return 0
    
    # 获取今日凌晨时间戳（避免 SQLite 时间函数兼容性问题）
    local today_start
    today_start=$(date -v0H -v0M -v0S +%s 2>/dev/null || date -d "today 00:00:00" +%s)
    
    # 获取当天累计 token
    local today_tokens
    today_tokens=$(sqlite3 "$db" \
        "SELECT COALESCE(SUM(tokens_in + tokens_out), 0) FROM behavior 
         WHERE created_at >= $today_start;" 2>/dev/null)
    
    # 处理空值
    today_tokens=${today_tokens:-0}
    
    if [ "$today_tokens" -gt "$threshold" ]; then
        echo "⚠️ [Threshold] 今日已消耗 ${today_tokens} tokens，超过阈值 ${threshold}" >&2
        echo "[TRIGGER_COMPACT]"
        return 1
    fi
    
    log_debug "今日 token: ${today_tokens}/${threshold}"
    return 0
}

# ---------- 内存安全阀 ----------
# 用法: check_memory_pressure [min_free_mb]
# 返回: 0=安全, 1=压力高/不可用
check_memory_pressure() {
    local min_free_mb="${1:-200}"
    local free_mb=0
    
    # 尝试用 sysctl (macOS 13+)
    local pressure
    pressure=$(sysctl -n vm.memory_pressure_level 2>/dev/null)
    
    if [ -n "$pressure" ]; then
        # sysctl 可用，使用压力级别
        if [ "$pressure" -ge 2 ]; then
            log_warn "🚨 内存压力级别: $pressure (高)"
            return 1
        fi
        log_debug "内存压力级别: $pressure (正常)"
        return 0
    fi
    
    # Fallback: 用 vm_stat 计算可用内存
    local free_pages
    free_pages=$(vm_stat | grep "Pages free" | awk '{print $3}' | tr -d '.')
    
    if [ -z "$free_pages" ]; then
        log_warn "⚠️ 无法获取内存状态，跳过检查"
        return 0
    fi
    
    # 转换为 MB (page size = 4096 bytes)
    free_mb=$((free_pages * 4096 / 1024 / 1024))
    
    if [ $free_mb -lt $min_free_mb ]; then
        log_warn "🚨 内存不足: ${free_mb}MB < ${min_free_mb}MB"
        return 1
    fi
    
    log_debug "内存充足: ${free_mb}MB 可用"
    return 0
}

# 内存不足时终止（用于脚本入口）
require_memory() {
    local min_free_mb="${1:-200}"
    if ! check_memory_pressure "$min_free_mb"; then
        log_error "内存压力过高，取消操作以保护系统"
        exit 1
    fi
}

# ---------- 初始化检查 ----------
# 用法: init_lib
init_lib() {
    # 检查必要目录
    require_dir "$LOCK_DIR" || mkdir -p "$LOCK_DIR"
    require_dir "$LOG_DIR" || mkdir -p "$LOG_DIR"
    
    log_debug "Library initialized"
}

# 自动初始化
init_lib
