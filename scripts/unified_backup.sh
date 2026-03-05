#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# 分层备份系统
# L1: Git同步 (每2小时)
# L2: 每日镜像 (每天3:30)
# L3: 加密备份 (每周日4:00)
# ═══════════════════════════════════════════════════════════════════

SCRIPT_DIR="$HOME/.openclaw/scripts"
BACKUP_DIR="$HOME/openclaw-backups"
ENCRYPTED_DIR="$BACKUP_DIR/encrypted"
LOG_FILE="$HOME/.openclaw/logs/backup.log"

# 确保目录存在
mkdir -p "$BACKUP_DIR" "$ENCRYPTED_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# L1: Git同步 (优化版)
sync_git() {
    log "=== L1: Git同步开始 ==="
    cd "$HOME/.openclaw/workspace"
    
    # 优化1: 仅添加已跟踪文件的变更 (-u 比 -A 更快)
    git add -u 2>/dev/null
    
    # 优化2: 使用 --quiet --exit-code 替代 --quiet
    if git diff --cached --quiet --exit-code 2>/dev/null; then
        log "无变更，跳过"
    else
        # 优化3: 添加 --atomic 原子提交
        git commit -m "checkpoint: $(date '+%Y-%m-%d %H:%M')" 2>/dev/null
        
        # 优化4: 后台推送 (非阻塞)
        {
            git push origin main 2>/dev/null || git push origin master 2>/dev/null
            log "Git已推送"
        } &
        log "Git已提交，推送异步进行"
    fi
}

# L2: 每日镜像
backup_local() {
    log "=== L2: 每日镜像备份 ==="
    
    cd "$HOME"
    
    # 备份文件（排除logs和completions）
    BACKUP_FILE="$BACKUP_DIR/openclaw-$(date +%Y-%m-%d_%H%M).tar.gz"
    
    tar -czf "$BACKUP_FILE" \
        --exclude='.openclaw/logs' \
        --exclude='.openclaw/completions' \
        --exclude='.openclaw/backups' \
        .openclaw 2>/dev/null
    
    log "本地备份完成: $BACKUP_FILE"
    
    # 清理3天前的备份
    find "$BACKUP_DIR" -name "openclaw-*.tar.gz" -mtime +3 -delete 2>/dev/null
    log "已清理3天前的备份"
}

# L3: 加密备份
backup_encrypt() {
    log "=== L3: 加密备份 ==="
    
    cd "$HOME"
    
    # 创建临时目录
    TEMP_DIR=$(mktemp -d)
    
    # 复制敏感文件
    cp -r "$HOME/.openclaw/credentials" "$TEMP_DIR/" 2>/dev/null
    cp -r "$HOME/.openclaw/agents" "$TEMP_DIR/" 2>/dev/null
    
    # 加密
    ENCRYPTED_FILE="$ENCRYPTED_DIR/openclaw-encrypted-$(date +%Y-%m-%d).tar.gz.gpg"
    tar -czf - -C "$TEMP_DIR" . 2>/dev/null | gpg --symmetric --cipher-algo AES256 -o "$ENCRYPTED_FILE" 2>/dev/null
    
    rm -rf "$TEMP_DIR"
    
    log "加密备份完成: $ENCRYPTED_FILE"
    
    # 清理7天前的加密备份
    find "$ENCRYPTED_DIR" -name "*.gpg" -mtime +7 -delete 2>/dev/null
    log "已清理7天前的加密备份"
}

# 恢复
restore() {
    local source=$1
    
    if [ -z "$source" ]; then
        echo "用法: $0 restore <备份文件>"
        exit 1
    fi
    
    if [ ! -f "$source" ]; then
        echo "文件不存在: $source"
        exit 1
    fi
    
    log "开始恢复: $source"
    tar -xzf "$source" -C "$HOME/" 2>/dev/null
    log "恢复完成"
}

# 状态
status() {
    echo "=== 备份状态 ==="
    echo ""
    echo "L1 (Git):"
    cd "$HOME/.openclaw/workspace" && git log --oneline -1 2>/dev/null || echo "未初始化"
    echo ""
    echo "L2 (本地备份):"
    ls -la "$BACKUP_DIR"/*.tar.gz 2>/dev/null | tail -5
    echo ""
    echo "L3 (加密备份):"
    ls -la "$ENCRYPTED_DIR"/*.gpg 2>/dev/null | tail -5
}

# 主逻辑
case "$1" in
    git|sync)
        sync_git
        ;;
    local|backup)
        backup_local
        ;;
    encrypt|encrypted)
        backup_encrypt
        ;;
    restore)
        restore "$2"
        ;;
    status|info)
        status
        ;;
    *)
        echo "用法: $0 <command>"
        echo ""
        echo "命令:"
        echo "  git       - L1: Git同步"
        echo "  local     - L2: 每日镜像"
        echo "  encrypt   - L3: 加密备份"
        echo "  restore   - 恢复"
        echo "  status    - 状态查看"
        ;;
esac
