#!/bin/bash
# 脚本名称：直接发送巡检通知
# 作者：OpenClaw Assistant
# 创建时间：2026-03-04
# 用途：检查巡检通知并通过对话发送到飞书

set -euo pipefail

readonly NOTIFICATION_READY_FILE="/tmp/openclaw-audit-notification-ready.txt"
readonly NOTIFICATION_SENT_FLAG="/tmp/openclaw-notification-sent-$(date +%Y%m%d).flag"
readonly LOG_FILE="/var/log/openclaw/notification-direct.log"

# 确保日志目录存在
sudo mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
sudo touch "$LOG_FILE" 2>/dev/null || true
sudo chown "$(whoami):$(whoami)" "$LOG_FILE" 2>/dev/null || true

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE" 2>/dev/null || echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# 主函数
main() {
    # 检查是否已经发送过今天的通知
    if [[ -f "$NOTIFICATION_SENT_FLAG" ]]; then
        exit 0
    fi
    
    # 检查是否有待发送的通知
    if [[ ! -f "$NOTIFICATION_READY_FILE" ]]; then
        exit 0
    fi
    
    log "Found pending audit notification"
    
    # 读取通知文件路径
    local notification_file
    notification_file=$(cat "$NOTIFICATION_READY_FILE")
    
    if [[ ! -f "$notification_file" ]]; then
        log "Notification file not found: $notification_file"
        rm -f "$NOTIFICATION_READY_FILE"
        exit 1
    fi
    
    # 创建会话消息请求
    local session_message="/tmp/openclaw-session-request-$(date +%Y%m%d-%H%M%S).txt"
    
    cat > "$session_message" << EOF
请发送以下巡检报告到飞书：

$(cat "$notification_file")

发送完成后请回复"通知已发送"以确认。
EOF
    
    # 记录请求
    log "Created session message request: $session_message"
    log "Audit notification ready for manual sending"
    
    # 创建发送完成标记（避免重复检查）
    touch "$NOTIFICATION_SENT_FLAG"
    
    # 清理通知文件
    rm -f "$NOTIFICATION_READY_FILE" "$notification_file"
    
    log "Notification process completed"
}

# 执行检查
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi