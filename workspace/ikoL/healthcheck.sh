#!/bin/bash
# Daily Health Check for Disk, CPU, Memory, and OpenClaw
# Improved version: Organizes reports in workspace/reports/healthcheck/YYYY-MM, adds error handling, sends full report summary to Feishu if alerts found.

set -e  # Exit on errors

# Set up directories and timestamp
WORKSPACE="/root/.openclaw/workspace"
REPORT_DIR="$WORKSPACE/reports/healthcheck/$(date +%Y-%m)"
mkdir -p "$REPORT_DIR"  # Ensure directory exists

TIMESTAMP=$(date +"%Y-%m-%d_%H%M%S")
REPORT_FILE="$REPORT_DIR/healthcheck_report_$TIMESTAMP.txt"
LOG_FILE="$REPORT_DIR/healthcheck_log_$TIMESTAMP.txt"  # For script logs/errors

# Redirect script output to log for debugging
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=== Health Check Report - $(date +"%Y-%m-%d %H:%M:%S") ===" > "$REPORT_FILE"

# Disk Usage
echo -e "\nDisk Usage:" >> "$REPORT_FILE"
df -h | grep '/dev/root' >> "$REPORT_FILE" || echo "No /dev/root found (non-standard disk setup)." >> "$REPORT_FILE"
DISK_USE=$(df -h | grep '/dev/root' | awk '{print $5}' | tr -d '%' || echo "0")
if [ "$DISK_USE" -gt 80 ]; then
  echo "ALERT: Disk usage high ($DISK_USE%)!" >> "$REPORT_FILE"
fi

# Memory Usage
echo -e "\nMemory Usage:" >> "$REPORT_FILE"
free -h >> "$REPORT_FILE"
MEM_USE=$(free | grep Mem | awk '{print $3/$2 * 100.0}' | cut -d. -f1 || echo "0")
if [ "$MEM_USE" -gt 80 ]; then
  echo "ALERT: Memory usage high ($MEM_USE%)!" >> "$REPORT_FILE"
fi

# CPU Snapshot
echo -e "\nCPU/Top Processes:" >> "$REPORT_FILE"
top -bn1 | head -n 10 >> "$REPORT_FILE"
CPU_IDLE=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}' | cut -d. -f1 || echo "100")
if [ "$CPU_IDLE" -lt 20 ]; then
  echo "ALERT: CPU load high (idle $CPU_IDLE%)!" >> "$REPORT_FILE"
fi

# OpenClaw Health & Risk
echo -e "\nOpenClaw Status:" >> "$REPORT_FILE"
openclaw status --brief >> "$REPORT_FILE" || echo "Error running openclaw status." >> "$REPORT_FILE"

echo -e "\nOpenClaw Health:" >> "$REPORT_FILE"
openclaw health --json | jq '.status // "OK"' >> "$REPORT_FILE" || echo "Error running openclaw health." >> "$REPORT_FILE"

echo -e "\nOpenClaw Security Audit:" >> "$REPORT_FILE"
openclaw security audit --deep | grep -i 'risk|warning|error' >> "$REPORT_FILE" || echo "No risks found." >> "$REPORT_FILE"

echo -e "\nOpenClaw Update Status:" >> "$REPORT_FILE"
openclaw update status >> "$REPORT_FILE" || echo "Error running openclaw update status." >> "$REPORT_FILE"

# Check for alerts and send notification if any
if grep -q "ALERT" "$REPORT_FILE"; then
  ALERTS=$(grep "ALERT" "$REPORT_FILE" | tr '\n' '; ')
  SUMMARY=$(cat "$REPORT_FILE" | head -n 20)  # First 20 lines as summary
  openclaw message send --target "user:ou_570aeb8842a1cbbc0313861d2b5c128f" --message "Health Alert: $ALERTS\n\nReport Summary:\n$SUMMARY\nFull report at: $REPORT_FILE" || echo "Failed to send Feishu message." >> "$LOG_FILE"
else
  echo "No alerts found." >> "$LOG_FILE"
fi

# Optional: Auto-cleanup old reports (older than 30 days)
find "$WORKSPACE/reports/healthcheck" -type f -mtime +30 -delete

echo "Report saved to $REPORT_FILE"