#!/bin/bash
# 简化的通知目标获取脚本

CONFIG_FILE="scripts/security/notification-config.yaml"

get_targets() {
    local severity="$1"
    local result=""
    
    case "$severity" in
        "info")
            # 获取primary目标
            result=$(awk '
            /primary:/{flag=1; next}
            /warning:|critical:/{flag=0}
            flag && /- type: user/ {getline; if(/id:/) print "user:" $2}
            flag && /- type: chat/ {getline; if(/id:/) print "chat:" $2}
            ' "$CONFIG_FILE")
            ;;
        "warning")  
            # 获取warning和critical (暂时使用primary)
            result=$(awk '
            /primary:/{flag=1; next}
            /warning:|critical:/{flag=0}
            flag && /- type: user/ {getline; if(/id:/) print "user:" $2}
            flag && /- type: chat/ {getline; if(/id:/) print "chat:" $2}
            ' "$CONFIG_FILE")
            ;;
        "critical")
            # 只获取critical (暂时使用primary)
            result=$(awk '
            /primary:/{flag=1; next}
            /warning:|critical:/{flag=0}
            flag && /- type: user/ {getline; if(/id:/) print "user:" $2}
            flag && /- type: chat/ {getline; if(/id:/) print "chat:" $2}
            ' "$CONFIG_FILE")
            ;;
    esac
    
    # 如果没有找到目标，使用默认
    if [[ -z "$result" ]]; then
        echo "user:ou_570aeb8842a1cbbc0313861d2b5c128f"
    else
        echo "$result"
    fi
}

# 获取指定级别的目标
get_targets "${1:-info}"