#!/bin/bash
# 脚本名称：巡检通知发送器（修复版）
# 作者：OpenClaw Assistant  
# 创建时间：2026-03-04
# 修复时间：2026-03-04
# 用途：检查巡检通知队列并实际发送给用户

set -euo pipefail

readonly NOTIFICATION_QUEUE_FILE="/tmp/openclaw-notification-queue.txt"
readonly NOTIFICATION_SENT_FILE="/tmp/openclaw-notification-sent-$(date +%Y%m%d).txt"
readonly LOG_FILE="/var/log/openclaw/notification-sender.log"
readonly USER_ID="ou_570aeb8842a1cbbc0313861d2b5c128f"

# 确保日志目录存在
sudo mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
sudo touch "$LOG_FILE" 2>/dev/null || true
sudo chown "$(whoami):$(whoami)" "$LOG_FILE" 2>/dev/null || true

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE" 2>/dev/null || echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# 发送通知
send_notification() {
    local message_content="$1"
    
    log "Attempting to send notification via OpenClaw"
    
    # 使用OpenClaw CLI发送消息
    if timeout 30 openclaw message send \
        --target "user:$USER_ID" \
        --channel feishu \
        --message "$message_content" 2>&1; then
        log "Notification sent successfully via OpenClaw CLI"
        return 0
    else
        log "OpenClaw CLI failed, trying Python script fallback"
        
        # 备用方案：使用Python脚本
        echo "$message_content" | python3 "$HOME/.openclaw/workspace/scripts/security/send-audit-notification.py" --user-id "$USER_ID" 2>&1
        local exit_code=$?
        
        if [[ $exit_code -eq 0 ]]; then
            log "Notification sent successfully via Python fallback"
            return 0
        else
            log "Both OpenClaw CLI and Python fallback failed"
            return 1
        fi
    fi
}

# 主函数
main() {
    # 检查是否有待发送的通知队列
    if [[ ! -f "$NOTIFICATION_QUEUE_FILE" ]]; then
        # 没有通知队列，静默退出
        exit 0
    fi
    
    # 检查今日是否已经发送过
    if [[ -f "$NOTIFICATION_SENT_FILE" ]]; then
        log "Notification already sent today, skipping"
        exit 0
    fi
    
    log "Found pending notification in queue"
    
    # 读取通知内容
    local message_content
    message_content=$(cat "$NOTIFICATION_QUEUE_FILE")
    
    if [[ -z "$message_content" ]]; then
        log "Notification queue is empty"
        rm -f "$NOTIFICATION_QUEUE_FILE"
        exit 0
    fi
    
    # 发送通知
    if send_notification "$message_content"; then
        log "Notification sent successfully"
        
        # 标记为已发送
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Notification sent successfully" > "$NOTIFICATION_SENT_FILE"
        
        # 清理队列文件
        rm -f "$NOTIFICATION_QUEUE_FILE"
        
        exit 0
    else
        log "Failed to send notification, will retry next run"
        exit 1
    fi
}

# 执行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi