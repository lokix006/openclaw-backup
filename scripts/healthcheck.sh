#!/bin/bash
# healthcheck.sh - OpenClaw Server Daily Health Check
# Location: /root/.openclaw/workspace/scripts/healthcheck.sh
# Managed by: main agent

echo "=============================="
echo " 系统巡检报告"
echo " 时间: $(date -u '+%Y-%m-%d %H:%M UTC')"
echo " 主机: $(hostname)"
echo "=============================="

echo ""
echo "=== CPU ==="
top -bn1 | grep "Cpu(s)" | awk '{printf "使用率: %.1f%%\n", $2+$4}'
echo "负载均值: $(cat /proc/loadavg | awk '{print $1, $2, $3}')"
echo "高CPU进程 (Top 3):"
ps aux --sort=-%cpu | awk 'NR>1 && NR<=4 {printf "  %-20s %s%%\n", $11, $3}'

echo ""
echo "=== 内存 ==="
free -h | awk '
  /^Mem:/ {printf "总计: %s | 已用: %s | 可用: %s\n", $2, $3, $7}
  /^Swap:/ {printf "Swap: 总计 %s | 已用: %s\n", $2, $3}
'

echo ""
echo "=== 磁盘 ==="
df -h | awk 'NR==1 || /^\/dev\// {printf "%-20s %6s %6s %6s %5s %s\n", $1,$2,$3,$4,$5,$6}' | grep -v tmpfs

echo ""
echo "=== 系统运行时间 ==="
uptime -p

echo ""
echo "=== OpenClaw 状态 ==="
openclaw status 2>/dev/null | grep -E "Gateway|Agents|Sessions|Channel|Update|Heartbeat" | sed 's/\x1b\[[0-9;]*m//g' | head -15

echo ""
echo "=== OpenClaw 版本 ==="
openclaw --version 2>/dev/null | head -3

echo ""
echo "=== 网络监听端口 ==="
ss -tlnp 2>/dev/null | awk 'NR>1 {print $4}' | sort -u | head -20

echo ""
echo "=== 近期系统错误 (syslog last 100 lines) ==="
journalctl -n 100 --no-pager -p err..alert 2>/dev/null | grep -v "^--" | tail -15 || \
  grep -iE "error|critical|fail" /var/log/syslog 2>/dev/null | tail -15 || \
  echo "无法读取系统日志"

echo ""
echo "=== Docker 容器状态 ==="
if command -v docker &>/dev/null; then
  docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "Docker 无法连接"
else
  echo "Docker 未安装"
fi

echo ""
echo "=============================="
echo " 巡检完成"
echo "=============================="
