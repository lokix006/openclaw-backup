#!/bin/bash
# 修复版通知发送脚本
# 用途：直接发送巡检通知队列中的内容

set -euo pipefail

readonly NOTIFICATION_QUEUE_FILE="/tmp/openclaw-notification-queue.txt"
readonly USER_ID="ou_570aeb8842a1cbbc0313861d2b5c128f"
readonly LOG_FILE="/var/log/openclaw/notification-fixed.log"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE" 2>/dev/null || echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

main() {
    if [[ ! -f "$NOTIFICATION_QUEUE_FILE" ]]; then
        log "No notification queue found"
        exit 0
    fi
    
    log "Found notification queue, attempting to send..."
    
    # 读取通知内容（只取正文部分，去掉TARGETS行）
    local message_content
    message_content=$(sed '/^TARGETS:/,$d' "$NOTIFICATION_QUEUE_FILE" | sed '/^---$/,$d')
    
    log "Sending notification to user: $USER_ID"
    
    # 使用OpenClaw发送
    if echo "$message_content" | openclaw message send --target "user:$USER_ID" --channel feishu --stdin 2>/dev/null; then
        log "Notification sent successfully"
        # 备份并清理队列文件
        cp "$NOTIFICATION_QUEUE_FILE" "/tmp/openclaw-notification-sent-$(date +%Y%m%d_%H%M).txt"
        rm -f "$NOTIFICATION_QUEUE_FILE"
        exit 0
    else
        log "Failed to send via OpenClaw CLI, notification remains in queue"
        exit 1
    fi
}

main "$@"