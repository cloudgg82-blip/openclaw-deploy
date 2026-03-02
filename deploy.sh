#!/bin/bash
#===============================================================================
# OpenClaw 部署脚本
# 从 Git 仓库部署到新终端
#===============================================================================

set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
LOGIN_FILE="$REPO_DIR/.deployed"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

#-------------------------------------------------------------------------------
# 检查系统
#-------------------------------------------------------------------------------
check_system() {
    local os="$(uname)"
    
    if [[ "$os" == "Darwin" ]]; then
        SYSTEM="macos"
    elif [[ "$os" == "Linux" ]]; then
        SYSTEM="linux"
        # 检测 Linux 发行版
        if [[ -f /etc/debian_version ]]; then
            LINUX_FAMILY="debian"
        elif [[ -f /etc/redhat-release ]]; then
            LINUX_FAMILY="redhat"
        elif [[ -f /etc/arch-release ]]; then
            LINUX_FAMILY="arch"
        else
            LINUX_FAMILY="unknown"
        fi
    else
        log_error "不支持的操作系统: $os"
        log_info "仅支持: macOS, Linux"
        exit 1
    fi
    
    log_info "检测到操作系统: $SYSTEM ${LINUX_FAMILY:-}"
    
    # 检查 Node.js
    if ! command -v node &> /dev/null; then
        log_warn "Node.js 未安装，尝试安装..."
        install_nodejs
    fi
    
    local NODE_VERSION=$(node -v | sed 's/v//' | cut -d. -f1)
    if [[ $NODE_VERSION -lt 20 ]]; then
        log_error "Node.js 版本需要 >= 20"
        exit 1
    fi
}

#-------------------------------------------------------------------------------
# 安装 Node.js
#-------------------------------------------------------------------------------
install_nodejs() {
    if [[ "$SYSTEM" == "macos" ]]; then
        if command -v brew &> /dev/null; then
            brew install node
        else
            log_error "Homebrew 未安装，请先安装 Homebrew"
            exit 1
        fi
    elif [[ "$SYSTEM" == "linux" ]]; then
        # 使用 NodeSource 安装 Node.js 20
        if [[ "$LINUX_FAMILY" == "debian" ]] || [[ "$LINUX_FAMILY" == "ubuntu" ]]; then
            curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
            apt-get install -y nodejs
        elif [[ "$LINUX_FAMILY" == "redhat" ]] || [[ "$LINUX_FAMILY" == "centos" ]]; then
            curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
            yum install -y nodejs
        else
            # 尝试使用包管理器
            if command -v apt-get &> /dev/null; then
                apt-get update && apt-get install -y nodejs npm
            elif command -v yum &> /dev/null; then
                yum install -y nodejs npm
            elif command -v pacman &> /dev/null; then
                pacman -S --noconfirm nodejs npm
            else
                log_error "无法自动安装 Node.js，请手动安装"
                exit 1
            fi
        fi
    fi
}

#-------------------------------------------------------------------------------
# 安装 OpenClaw
#-------------------------------------------------------------------------------
install_openclaw() {
    if command -v openclaw &> /dev/null; then
        log_info "OpenClaw 已安装"
        return
    fi
    
    log_info "安装 OpenClaw..."
    npm install -g openclaw
}

#-------------------------------------------------------------------------------
# 同步配置
#-------------------------------------------------------------------------------
sync_config() {
    log_info "同步配置..."
    
    mkdir -p "$HOME/.openclaw"
    mkdir -p "$HOME/.openclaw/scripts"
    
    # 配置文件
    if [[ -d "$REPO_DIR/configs" ]]; then
        cp -r "$REPO_DIR/configs/"* "$HOME/.openclaw/"
    fi
    
    # 脚本
    if [[ -d "$REPO_DIR/scripts" ]]; then
        cp -r "$REPO_DIR/scripts/"* "$HOME/.openclaw/scripts/"
        chmod +x "$HOME/.openclaw/scripts/"*.sh 2>/dev/null || true
    fi
    
    # Beads
    if [[ -d "$REPO_DIR/.beads" ]]; then
        mkdir -p "$HOME/.openclaw/workspace/.beads"
        cp -r "$REPO_DIR/.beads/"* "$HOME/.openclaw/workspace/.beads/"
    fi
    
    # Cron
    if [[ -f "$REPO_DIR/configs/cron/jobs.json" ]]; then
        mkdir -p "$HOME/.openclaw/cron"
        cp "$REPO_DIR/configs/cron/jobs.json" "$HOME/.openclaw/cron/"
    fi
}

#-------------------------------------------------------------------------------
# 启动服务
#-------------------------------------------------------------------------------
start_service() {
    log_info "启动服务..."
    
    # 停止旧服务
    openclaw gateway stop 2>/dev/null || true
    sleep 1
    
    # 启动新服务
    openclaw gateway start
    sleep 2
    
    # 验证
    if openclaw status &> /dev/null; then
        log_info "部署成功！"
        touch "$LOGIN_FILE"
    else
        log_error "部署失败，请检查配置"
        exit 1
    fi
}

#-------------------------------------------------------------------------------
# 首次部署
#-------------------------------------------------------------------------------
first_deploy() {
    check_system
    install_openclaw
    sync_config
    start_service
    
    log_info "=========================================="
    log_info "  首次部署完成！"
    log_info "=========================================="
    log_info ""
    log_info "请手动配置："
    log_info "  1. 编辑 configs/openclaw.json 添加 API Key"
    log_info "  2. 配置渠道凭证 (飞书/Telegram)"
    log_info "  3. 运行 openclaw status 查看状态"
}

#-------------------------------------------------------------------------------
# 增量更新
#-------------------------------------------------------------------------------
update_deploy() {
    log_info "执行增量更新..."
    
    # 检查是否已部署
    if [[ ! -f "$LOGIN_FILE" ]]; then
        log_warn "未检测到首次部署，执行首次部署..."
        first_deploy
        return
    fi
    
    # 更新配置
    sync_config
    
    # 重启服务
    log_info "重启服务..."
    openclaw gateway restart
    
    log_info "更新完成！"
}

#-------------------------------------------------------------------------------
# 主入口
#-------------------------------------------------------------------------------
case "${1:-deploy}" in
    deploy)
        first_deploy
        ;;
    update)
        update_deploy
        ;;
    *)
        echo "用法: $0 {deploy|update}"
        exit 1
        ;;
esac
