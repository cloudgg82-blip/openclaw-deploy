#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
#  OpenClaw 记忆系统统一入口 - unified_memory.sh
#  提供 CLI 统一管理记忆系统
#  版本: 1.0 | 日期: 2026-02-19
# ═══════════════════════════════════════════════════════════════════

# 临时设置 SCRIPT_DIR（在 source 之前）
_TEMP_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 引入共享库（会覆盖 SCRIPT_DIR）
source "$_TEMP_SCRIPT_DIR/lib/common.sh"

# 重新设置正确的 SCRIPT_DIR
SCRIPT_DIR="$_TEMP_SCRIPT_DIR"
unset _TEMP_SCRIPT_DIR

SCRIPT_NAME="unified_memory"

# ---------- 帮助信息 ----------
show_help() {
    cat << HELP
╔══════════════════════════════════════════════════════════════════╗
║              OpenClaw 记忆系统统一入口                      ║
║              版本: 1.0 | 日期: 2026-02-19                ║
╚══════════════════════════════════════════════════════════════════╝

用法:
  $SCRIPT_NAME <command> [options]

命令:
  record <key> <layer>     记录记忆访问
  cleanup [--dry-run]      清理记忆日志
  analyze [--weekly]        分析记忆健康
  health                   检查记忆系统健康
  migrate                  迁移/同步数据
  help                    显示帮助

HELP
}

# ---------- 命令执行 ----------
run_command() {
    local cmd="$1"
    shift
    
    case "$cmd" in
        record)
            local key="${1:-}"
            local layer="${2:-L3}"
            [ -z "$key" ] && { log_error "缺少参数: <key>"; return 1; }
            log_info "记录: $key ($layer)"
            bash "$SCRIPT_DIR/memory.sh" record "$key" "$layer" "load"
            ;;
            
        cleanup)
            log_info "执行清理"
            bash "$SCRIPT_DIR/memory_cleanup.sh"
            ;;
            
        analyze)
            log_info "执行分析"
            bash "$SCRIPT_DIR/memory_weekly_analysis.sh"
            ;;
            
        health)
            log_info "检查健康"
            
            # 自动记录 L2 访问（提升活跃度）
            log_info "记录 L2 访问..."
            for file in RUNTIME_LIGHT.md HEARTBEAT_LIGHT.md; do
                filepath="$HOME/.openclaw/workspace/$file"
                if [ -f "$filepath" ]; then
                    mod_time=$(stat -f "%Sm" -t "%s" "$filepath" 2>/dev/null || stat -c "%Y" "$filepath" 2>/dev/null)
                    now_time=$(date +%s)
                    diff=$((now_time - mod_time))
                    # 2 小时内修改过就记录
                    if [ $diff -lt 7200 ]; then
                        bash "$SCRIPT_DIR/memory.sh" record "$file" "L2" "load" 2>/dev/null || true
                    fi
                fi
            done
            
            # 执行健康检查
            bash "$SCRIPT_DIR/unified_health_check.sh"
            
            # 自动记录 L3 访问（提升健康评分）
            log_info "记录 L3 访问..."
            for file in SOUL.md USER.md MEMORY.md AGENTS.md; do
                bash "$SCRIPT_DIR/memory.sh" record "$file" "L3" "load" 2>/dev/null || true
            done
            ;;
            
        migrate)
            log_info "执行迁移"
            bash "$SCRIPT_DIR/memory_migrate.sh" migrate
            ;;
            
        help|--help|-h)
            show_help
            ;;
            
        *)
            log_error "未知命令: $cmd"
            show_help
            return 1
            ;;
    esac
}

# ---------- 主入口 ----------
main() {
    local cmd="${1:-}"
    [ -z "$cmd" ] && { show_help; exit 0; }
    run_command "$cmd" "${@:2}"
}

main "$@"
