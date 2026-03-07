#!/bin/bash
# Daily Health Check for Disk, CPU, Memory, and OpenClaw

TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
REPORT_FILE="/root/healthcheck_report_$TIMESTAMP.txt"

echo "=== Health Check Report - $TIMESTAMP ===" > "$REPORT_FILE"

# Disk Usage
echo -e "\nDisk Usage:" >> "$REPORT_FILE"
df -h | grep '/dev/root' >> "$REPORT_FILE"
DISK_USE=$(df -h | grep '/dev/root' | awk '{print $5}' | tr -d '%')
if [ $DISK_USE -gt 80 ]; then
  echo "ALERT: Disk usage high ($DISK_USE%)!" >> "$REPORT_FILE"
fi

# Memory Usage
echo -e "\nMemory Usage:" >> "$REPORT_FILE"
free -h >> "$REPORT_FILE"
MEM_USE=$(free | grep Mem | awk '{print $3/$2 * 100.0}' | cut -d. -f1)
if [ $MEM_USE -gt 80 ]; then
  echo "ALERT: Memory usage high ($MEM_USE%)!" >> "$REPORT_FILE"
fi

# CPU Snapshot
echo -e "\nCPU/Top Processes:" >> "$REPORT_FILE"
top -bn1 | head -n 10 >> "$REPORT_FILE"
CPU_IDLE=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}')
if [ $(echo "$CPU_IDLE < 20" | bc) -eq 1 ]; then
  echo "ALERT: CPU load high (idle $CPU_IDLE%)!" >> "$REPORT_FILE"
fi

# OpenClaw Health & Risk
echo -e "\nOpenClaw Status:" >> "$REPORT_FILE"
openclaw status --brief >> "$REPORT_FILE"

echo -e "\nOpenClaw Health:" >> "$REPORT_FILE"
openclaw health --json | jq '.status // "OK"' >> "$REPORT_FILE"

echo -e "\nOpenClaw Security Audit:" >> "$REPORT_FILE"
openclaw security audit --deep | grep -i 'risk|warning|error' >> "$REPORT_FILE" || echo "No risks found."

echo -e "\nOpenClaw Update Status:" >> "$REPORT_FILE"
openclaw update status >> "$REPORT_FILE"

# Check for alerts and send notification if any
if grep -q "ALERT" "$REPORT_FILE"; then
  ALERTS=$(grep "ALERT" "$REPORT_FILE" | tr '\n' '; ')
  openclaw message send --target "user:ou_570aeb8842a1cbbc0313861d2b5c128f" --message "Health Alert: $ALERTS See report: $REPORT_FILE"
fi

echo "Report saved to $REPORT_FILE"