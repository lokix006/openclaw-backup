#!/bin/bash
# 巡检通知触发器
# 作者：OpenClaw Assistant
# 创建时间：2026-03-05
# 用途：将巡检通知添加到发送队列

set -euo pipefail

readonly LOG_FILE="/var/log/openclaw/send-audit-summary.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE" 2>/dev/null || echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

main() {
    log "Checking for pending audit notification"
    
    # 检查是否有待发送的通知
    local notification_path_file="/tmp/openclaw-notification-path.txt"
    
    if [[ ! -f "$notification_path_file" ]]; then
        log "No pending audit notification found"
        exit 0
    fi
    
    local notification_file
    notification_file=$(cat "$notification_path_file")
    
    if [[ ! -f "$notification_file" ]]; then
        log "Notification file not found: $notification_file"
        exit 1
    fi
    
    log "Found pending audit notification: $notification_file"
    
    # 将通知添加到队列
    local queue_file="/tmp/openclaw-notification-queue.txt"
    cp "$notification_file" "$queue_file"
    
    log "Added audit notification to queue: $queue_file"
    
    # 清理路径文件
    rm -f "$notification_path_file"
    
    log "Notification process completed successfully"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi