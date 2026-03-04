#!/bin/bash
# 检查审计日志中的越权行为
SUSPICIOUS=$(grep -iE "unauthorized|denied|../|breakout" ../logs/access.log 2>/dev/null)
if [ -n "$SUSPICIOUS" ]; then
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] [ALERT] 触发越界告警! 详情: $SUSPICIOUS" >> ../logs/audit.log
else
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] [OK] 隔离边界完整，未发现越权异常。" >> ../logs/audit.log
fi
