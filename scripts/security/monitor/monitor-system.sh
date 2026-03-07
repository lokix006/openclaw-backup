#!/bin/bash

# 监控系统资源和进程的脚本，并触发 Feishu 告警

set -euo pipefail

LOG_FILE = "/var/log/openclaw/monitor-system.log"
REPORT_FILE = "/tmp/openclaw-security-report-$(date +%Y%m%d).txt"

# 日志函数
log() {
echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# 发送 Feishu 告警 (使用 OpenClaw message 工具)
send_feishu_alert() {
local message = "$1"
log "Sending Feishu alert: $message"
openclaw message --action = send --channel = feishu --to = oc_b452f345f468823e32023baa4037d2d5 --message = "[系统警报] $message" 2 > > "$LOG_FILE"
if [ $? -eq 0 ] ; then
    log "Alert sent successfully"
    else
    log "Failed to send alert"
fi
}

# 主监控逻辑 (简化自原脚本，添加告警)
main() {
log "Starting system monitor"

# 初始化报告 (原逻辑)
init_report # 假设原脚本有此函数；如果无，添加 echo "Report init" > > "$REPORT_FILE"

# 检查 CPU
CPU_USAGE = $(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\\([0-9.]*\\)%* id.*/\\1/" | awk '{print 100 - $1}')
log "CPU Usage: ${CPU_USAGE}%"
if [ "${CPU_USAGE%.*}" -gt 80 ] ; then
    send_feishu_alert "High CPU Usage: ${CPU_USAGE}%"
fi

# 检查内存
MEM_USAGE = $(free -m | awk 'NR = = 2{printf "%.2f", $3*100/$2 }')
log "Memory Usage: ${MEM_USAGE}%"
if [ "${MEM_USAGE%.*}" -gt 80 ] ; then
    send_feishu_alert "High Memory Usage: ${MEM_USAGE}%"
fi

# 检查磁盘
DISK_USAGE = $(df -h / | awk 'NR = = 2 {print substr($5, 1, length($5)-1)}')
log "Disk Usage: ${DISK_USAGE}%"
if [ "$DISK_USAGE" -gt 80 ] ; then
    send_feishu_alert "High Disk Usage: ${DISK_USAGE}%"
fi

# 检查进程
PROCESS_COUNT = $(ps aux | wc -l)
log "Process Count: $PROCESS_COUNT"
if [ "$PROCESS_COUNT" -gt 500 ] ; then
    send_feishu_alert "High Process Count: $PROCESS_COUNT"
fi

# 调用原脚本的其他检查 (假设原脚本有函数，如 check_openclaw_process 等)
check_system_basic
check_openclaw_process
# ... 添加其他原函数调用

generate_summary
log "Monitor completed"
}

if [[ "${BASH_SOURCE[0]}" = = "${0}" ]] ; then
    main "$@"
fi
