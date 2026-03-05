#!/bin/bash
# 脚本名称：通知配置解析器
# 作者：OpenClaw Assistant
# 创建时间：2026-03-04  
# 用途：解析YAML通知配置并生成目标列表

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_FILE="$SCRIPT_DIR/notification-config.yaml"
readonly WORKSPACE_DIR="${HOME}/.openclaw/workspace"

# 检查配置文件
check_config_file() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "Error: Configuration file not found: $CONFIG_FILE"
        exit 1
    fi
}

# 检查通知是否启用
is_notification_enabled() {
    if command -v yq &> /dev/null; then
        enabled=$(yq eval '.notification.enabled // true' "$CONFIG_FILE")
        [[ "$enabled" == "true" ]]
    else
        # 简单的grep检查，如果没有yq
        ! grep -q "enabled: false" "$CONFIG_FILE"
    fi
}

# 获取通知级别
get_notification_level() {
    if command -v yq &> /dev/null; then
        yq eval '.notification.level // "info"' "$CONFIG_FILE"
    else
        grep -E "^\s*level:" "$CONFIG_FILE" | awk '{print $2}' | head -1 || echo "info"
    fi
}

# 根据严重程度获取目标列表
get_targets_for_level() {
    local severity="$1"  # info/warning/critical
    local targets_file="/tmp/openclaw-notification-targets-${severity}.txt"
    
    > "$targets_file"  # 清空文件
    
    if command -v yq &> /dev/null; then
        # 使用yq解析YAML
        case "$severity" in
            "info")
                # 所有级别的目标
                yq eval '.notification.targets.primary[]' "$CONFIG_FILE" >> "$targets_file" 2>/dev/null || true
                yq eval '.notification.targets.warning[]' "$CONFIG_FILE" >> "$targets_file" 2>/dev/null || true
                yq eval '.notification.targets.critical[]' "$CONFIG_FILE" >> "$targets_file" 2>/dev/null || true
                ;;
            "warning")
                # warning和critical级别
                yq eval '.notification.targets.warning[]' "$CONFIG_FILE" >> "$targets_file" 2>/dev/null || true
                yq eval '.notification.targets.critical[]' "$CONFIG_FILE" >> "$targets_file" 2>/dev/null || true
                ;;
            "critical")
                # 只有critical级别
                yq eval '.notification.targets.critical[]' "$CONFIG_FILE" >> "$targets_file" 2>/dev/null || true
                ;;
        esac
    else
        # 简单的文本解析（备用方案）
        parse_targets_simple "$severity" > "$targets_file"
    fi
    
    # 去重并输出
    sort "$targets_file" | uniq
}

# 简单的YAML解析（当yq不可用时）
parse_targets_simple() {
    local severity="$1"
    local in_section=false
    local current_target=""
    
    while IFS= read -r line; do
        # 检查是否进入目标配置区域
        if [[ "$line" =~ ^[[:space:]]*targets:[[:space:]]*$ ]]; then
            in_section=true
            continue
        fi
        
        # 检查是否离开配置区域
        if [[ "$in_section" == true && "$line" =~ ^[[:space:]]*[a-zA-Z]+:[[:space:]]*$ && ! "$line" =~ ^[[:space:]]*(primary|warning|critical):[[:space:]]*$ ]]; then
            break
        fi
        
        if [[ "$in_section" == true ]]; then
            # 检查级别匹配
            if [[ "$line" =~ ^[[:space:]]*(primary|warning|critical):[[:space:]]*$ ]]; then
                local level="${BASH_REMATCH[1]}"
                case "$severity" in
                    "info") 
                        [[ "$level" =~ ^(primary|warning|critical)$ ]] && current_target="$level" || current_target=""
                        ;;
                    "warning")
                        [[ "$level" =~ ^(warning|critical)$ ]] && current_target="$level" || current_target=""
                        ;;
                    "critical")
                        [[ "$level" == "critical" ]] && current_target="$level" || current_target=""
                        ;;
                esac
                continue
            fi
            
            # 解析目标信息
            if [[ -n "$current_target" && "$line" =~ ^[[:space:]]*-[[:space:]]*type:[[:space:]]*(.+)$ ]]; then
                local type="${BASH_REMATCH[1]}"
                echo "type: $type"
            elif [[ -n "$current_target" && "$line" =~ ^[[:space:]]*id:[[:space:]]*(.+)$ ]]; then
                local id="${BASH_REMATCH[1]}"
                echo "id: $id"
            elif [[ -n "$current_target" && "$line" =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
                local name="${BASH_REMATCH[1]}"
                echo "name: $name"
                echo "---"  # 目标分隔符
            fi
        fi
    done < "$CONFIG_FILE"
}

# 将配置转换为消息发送格式
convert_to_message_targets() {
    local targets_data="$1"
    local output_file="/tmp/openclaw-message-targets.txt"
    
    > "$output_file"
    
    local current_type=""
    local current_id=""
    local current_name=""
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^type:[[:space:]]*(.+)$ ]]; then
            current_type="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^id:[[:space:]]*(.+)$ ]]; then
            current_id="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^name:[[:space:]]*(.+)$ ]]; then
            current_name="${BASH_REMATCH[1]}"
        elif [[ "$line" == "---" && -n "$current_type" && -n "$current_id" ]]; then
            # 输出消息目标格式
            if [[ "$current_type" == "user" ]]; then
                echo "user:$current_id" >> "$output_file"
            elif [[ "$current_type" == "chat" ]]; then
                echo "chat:$current_id" >> "$output_file"
            fi
            # 重置变量
            current_type=""
            current_id=""
            current_name=""
        fi
    done <<< "$targets_data"
    
    # 去重并输出
    sort "$output_file" | uniq
}

# 主函数
main() {
    local command="${1:-help}"
    
    case "$command" in
        "check")
            check_config_file && echo "Configuration file is valid"
            ;;
        "enabled")
            is_notification_enabled && echo "true" || echo "false"
            ;;
        "level")
            get_notification_level
            ;;
        "targets")
            local severity="${2:-info}"
            targets_data=$(get_targets_for_level "$severity")
            convert_to_message_targets "$targets_data"
            ;;
        "help"|*)
            echo "Usage: $0 {check|enabled|level|targets [info|warning|critical]}"
            echo "Examples:"
            echo "  $0 check          - 检查配置文件有效性"
            echo "  $0 enabled        - 检查通知是否启用"
            echo "  $0 level          - 获取通知级别"
            echo "  $0 targets info   - 获取info级别的目标列表"
            ;;
    esac
}

# 执行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi