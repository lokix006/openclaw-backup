#!/bin/bash
# 脚本名称：检查并发送巡检通知
# 作者：OpenClaw Assistant
# 创建时间：2026-03-04
# 用途：检查是否有待发送的巡检通知并发送到飞书

set -euo pipefail

readonly WORKSPACE_DIR="${HOME}/.openclaw/workspace"
readonly NOTIFICATION_READY_FILE="/tmp/openclaw-audit-notification-ready.txt"
readonly LOG_FILE="/var/log/openclaw/notification-sender.log"

# 确保日志目录存在
sudo mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
sudo touch "$LOG_FILE" 2>/dev/null || true
sudo chown "$(whoami):$(whoami)" "$LOG_FILE" 2>/dev/null || true

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE" 2>/dev/null || echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# 检查OpenClaw是否可用
check_openclaw_available() {
    if ! command -v openclaw &> /dev/null; then
        return 1
    fi
    
    # 简单检查OpenClaw状态
    if openclaw status &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# 发送通知
send_notification() {
    local notification_file="$1"
    local user_id="ou_570aeb8842a1cbbc0313861d2b5c128f"
    
    if [[ ! -f "$notification_file" ]]; then
        log "Notification file not found: $notification_file"
        return 1
    fi
    
    local message_content
    message_content=$(cat "$notification_file")
    
    log "Preparing to send audit notification"
    
    # 使用OpenClaw命令行发送消息
    if openclaw message send --target "user:$user_id" --channel feishu --message "$message_content"; then
        log "Audit notification sent successfully"
        rm -f "$notification_file" "$NOTIFICATION_READY_FILE"
        return 0
    else
        log "Failed to send audit notification"
        return 1
    fi
}

# 主函数
main() {
    # 检查是否有待发送的通知
    if [[ ! -f "$NOTIFICATION_READY_FILE" ]]; then
        # 没有通知要发送，静默退出
        exit 0
    fi
    
    log "Found pending audit notification"
    
    # 检查OpenClaw是否可用
    if ! check_openclaw_available; then
        log "OpenClaw not available, will retry later"
        exit 0
    fi
    
    # 读取通知文件路径
    local notification_file
    notification_file=$(cat "$NOTIFICATION_READY_FILE")
    
    # 发送通知
    if send_notification "$notification_file"; then
        log "Notification process completed successfully"
    else
        log "Notification process failed"
        exit 1
    fi
}

# 执行检查
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi