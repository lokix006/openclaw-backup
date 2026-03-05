#!/bin/bash
# 修复版多目标通知发送脚本
# 作者：OpenClaw Assistant
# 修复时间：2026-03-04

set -euo pipefail

readonly WORKSPACE_DIR="${HOME}/.openclaw/workspace"
readonly TARGETS_FILE="/tmp/openclaw-notification-targets-$(date +%Y%m%d).txt"
readonly LOG_FILE="/var/log/openclaw/notification-sender.log"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE" 2>/dev/null || echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# 发送消息
send_message() {
    local target="$1"
    local message="$2"
    
    log "Sending to target: $target"
    
    # 使用OpenClaw message工具发送
    if timeout 30 openclaw message send \
        --target "$target" \
        --channel feishu \
        --message "$message" 2>&1; then
        log "Successfully sent to $target"
        return 0
    else
        log "Failed to send to $target"
        return 1
    fi
}

main() {
    local notification_file="$1"
    
    if [[ ! -f "$notification_file" ]]; then
        log "Notification file not found: $notification_file"
        exit 1
    fi
    
    if [[ ! -f "$TARGETS_FILE" ]]; then
        log "Targets file not found: $TARGETS_FILE"
        # 使用默认目标
        echo "user:ou_570aeb8842a1cbbc0313861d2b5c128f" > "$TARGETS_FILE"
        echo "chat:oc_b452f345f468823e32023baa4037d2d5" >> "$TARGETS_FILE"
    fi
    
    # 读取消息内容（去掉目标信息和时间戳部分）
    local message_content
    message_content=$(sed '/^TARGETS:/,$d' "$notification_file" | sed '/^---$/,$d')
    
    log "Starting notification sending process"
    
    local success_count=0
    local total_count=0
    
    # 逐行读取目标并发送
    while IFS= read -r target; do
        if [[ -n "$target" && ! "$target" =~ ^[[:space:]]*# ]]; then
            total_count=$((total_count + 1))
            if send_message "$target" "$message_content"; then
                success_count=$((success_count + 1))
            fi
        fi
    done < "$TARGETS_FILE"
    
    log "Notification sending completed: $success_count/$total_count successful"
    
    if [[ $success_count -gt 0 ]]; then
        # 标记为已发送
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Sent to $success_count/$total_count targets" >> "/tmp/openclaw-notification-sent-$(date +%Y%m%d).txt"
        # 清理通知文件
        rm -f "$notification_file"
        exit 0
    else
        log "All targets failed, keeping notification for retry"
        exit 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi