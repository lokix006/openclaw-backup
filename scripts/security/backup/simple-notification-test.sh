#!/bin/bash
# 简化的通知配置测试

CONFIG_FILE="scripts/security/notification-config.yaml"

echo "测试通知配置解析..."

# 直接解析primary目标
echo "Primary targets:"
grep -A 10 "primary:" "$CONFIG_FILE" | grep -E "id:|type:" | paste - - | while read -r line; do
    type_line=$(echo "$line" | awk '{print $2}')
    id_line=$(echo "$line" | awk '{print $4}')
    if [[ "$type_line" == "user" ]]; then
        echo "user:$id_line"
    elif [[ "$type_line" == "chat" ]]; then
        echo "chat:$id_line"
    fi
done

echo ""
echo "Configuration file content:"
head -20 "$CONFIG_FILE"