#!/bin/bash
# daily-system-check.sh - Daily system and OpenClaw health check
# Run as isolated agentTurn, output to Feishu channel

# 1. System basic status
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')
MEM_USAGE=$(free -m | awk '/Mem:/ {printf "%.2f%%", $3/$2 * 100}')
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}')
PROCESSES=$(ps aux | grep '[o]penclaw' | wc -l)  # Check OpenClaw processes
UPDATES=$(apt list --upgradable 2>/dev/null | wc -l)  # For Ubuntu/Debian

# 2. OpenClaw status
OC_VERSION=$(openclaw update status | grep "Current" || echo "Unknown")
OC_STATUS=$(openclaw status | grep "Status" || echo "OK")
OC_LOGS=$(tail -n 50 /var/log/openclaw.log | grep -i error | wc -l)  # Assume log path

# 3. Risk assessment
OPEN_PORTS=$(ss -ltn | wc -l)
DEPS_OUTDATED=$(npm outdated -g | wc -l)

# Thresholds for alerts
ALERT=""
if [ $(echo $CPU_USAGE | cut -d'%' -f1) -gt 80 ]; then ALERT+="High CPU: $CPU_USAGE\n"; fi
if [ $OC_LOGS -gt 0 ]; then ALERT+="Errors in logs: $OC_LOGS\n"; fi
if [ $UPDATES -gt 0 ]; then ALERT+="Pending updates: $UPDATES\n"; fi

# Summary
SUMMARY="Daily Check $(date +%Y-%m-%d %H:%M UTC)
System: CPU $CPU_USAGE, Mem $MEM_USAGE, Disk $DISK_USAGE, Processes $PROCESSES
OpenClaw: Version $OC_VERSION, Status $OC_STATUS, Log errors $OC_LOGS
Risk: Open ports $OPEN_PORTS, Outdated deps $DEPS_OUTDATED
Alerts: $ALERT"

# Announce to Feishu (use message tool; assume channel inferred)
openclaw message send --channel feishu --message "$SUMMARY"  # Adjust if needed

