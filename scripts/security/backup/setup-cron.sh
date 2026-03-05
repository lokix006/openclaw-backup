#!/bin/bash
# 脚本名称：设置OpenClaw安全定时任务
# 作者：OpenClaw Assistant
# 创建时间：2026-03-04
# 用途：自动设置备份和巡检的定时任务

set -euo pipefail

readonly WORKSPACE_DIR="${HOME}/.openclaw/workspace"

# 获取脚本绝对路径
readonly BACKUP_SCRIPT="$(realpath "$WORKSPACE_DIR/scripts/security/backup/backup-git.sh")"
readonly MONITOR_SCRIPT="$(realpath "$WORKSPACE_DIR/scripts/security/monitor/monitor-system.sh")"
readonly NOTIFICATION_PROCESSOR="$(realpath "$WORKSPACE_DIR/scripts/security/notification-sender.sh")"

# 检查脚本是否存在
if [[ ! -f "$BACKUP_SCRIPT" ]]; then
    echo "错误：备份脚本不存在 $BACKUP_SCRIPT"
    exit 1
fi

if [[ ! -f "$MONITOR_SCRIPT" ]]; then
    echo "错误：监控脚本不存在 $MONITOR_SCRIPT"
    exit 1
fi

if [[ ! -f "$NOTIFICATION_PROCESSOR" ]]; then
    echo "错误：通知处理脚本不存在 $NOTIFICATION_PROCESSOR"
    exit 1
fi

# 添加cron任务
echo "设置定时任务..."

# 创建新的crontab内容
{
    # 保留现有的cron任务（如果有）
    crontab -l 2>/dev/null | grep -v "$BACKUP_SCRIPT" | grep -v "$MONITOR_SCRIPT" | grep -v "$NOTIFICATION_PROCESSOR" || true
    
    # 添加新的任务
    echo "0 2 * * * $BACKUP_SCRIPT >/dev/null 2>&1"
    echo "0 9 * * * $MONITOR_SCRIPT >/dev/null 2>&1"
    echo "5 9 * * * $NOTIFICATION_PROCESSOR >/dev/null 2>&1"
} | crontab -

# 显示当前cron任务
echo "当前cron任务："
crontab -l

echo "定时任务设置完成！"
echo "- 备份任务：每天凌晨2点"
echo "- 巡检任务：每天早上9点"
echo "- 通知处理：每天早上9:05"