#!/bin/bash
# 引入公共库
source ~/.openclaw/scripts/lib/common.sh
# 安全体检脚本 - 每日定时执行

LOG_FILE="$HOME/.openclaw/logs/security_audit.log"

echo "=== 安全体检 $(date +%Y-%m-%d\ %H:%M:%S) ===" > "$LOG_FILE"

# 执行深度安全审计
RESULT=$(openclaw security audit --deep 2>&1)

echo "$RESULT" >> "$LOG_FILE"

# 提取关键信息
CRITICAL=$(echo "$RESULT" | grep -c "critical" | head -1)
WARN=$(echo "$RESULT" | grep -c "WARN")

# 发送到飞书
if [ "$WARN" -gt 0 ]; then
    MSG="🔒 安全体检报告

⏰ 时间: $(date +%Y-%m-%d\ %H:%M:%S)
⚠️ 警告: $WARN 项

详情: 查看日志 ~/.openclaw/logs/security_audit.log"
else
    MSG="🔒 安全体检报告

⏰ 时间: $(date +%Y-%m-%d\ %H:%M:%S)
✅ 状态: 正常

无安全问题"
fi

# 调用飞书通知
~/.openclaw/scripts/feishu_alert.sh "安全体检" "$MSG" 2>/dev/null

log_info " 体检完成并已发送通知"
