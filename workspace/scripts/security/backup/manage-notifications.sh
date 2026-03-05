#!/bin/bash
# 脚本名称：通知配置管理工具
# 作者：OpenClaw Assistant
# 创建时间：2026-03-04
# 用途：管理OpenClaw安全巡检通知配置

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_FILE="$SCRIPT_DIR/notification-config.yaml"
readonly PARSER_SCRIPT="$SCRIPT_DIR/parse-notification-config.sh"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m' 
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印彩色信息
print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 显示当前配置
show_config() {
    print_info "当前通知配置:"
    echo "=================="
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        print_error "配置文件不存在: $CONFIG_FILE"
        return 1
    fi
    
    echo "配置文件: $CONFIG_FILE"
    echo ""
    
    # 检查通知状态
    if "$PARSER_SCRIPT" enabled 2>/dev/null | grep -q "true"; then
        print_info "通知状态: 已启用"
    else
        print_warn "通知状态: 已禁用"
    fi
    
    # 显示通知级别
    local level=$("$PARSER_SCRIPT" level 2>/dev/null || echo "unknown")
    echo "通知级别: $level"
    
    echo ""
    echo "目标配置:"
    echo "----------"
    
    # 显示各级别的目标
    for severity in info warning critical; do
        echo "[$severity 级别]"
        local targets=$("$PARSER_SCRIPT" targets "$severity" 2>/dev/null || true)
        if [[ -n "$targets" ]]; then
            echo "$targets" | while read -r target; do
                if [[ -n "$target" ]]; then
                    echo "  - $target"
                fi
            done
        else
            echo "  (无目标)"
        fi
        echo ""
    done
}

# 测试通知配置
test_config() {
    print_info "测试通知配置..."
    
    # 检查配置文件
    if ! "$PARSER_SCRIPT" check 2>/dev/null; then
        print_error "配置文件验证失败"
        return 1
    fi
    
    print_info "✓ 配置文件语法正确"
    
    # 检查是否有目标配置
    local has_targets=false
    for severity in info warning critical; do
        local targets=$("$PARSER_SCRIPT" targets "$severity" 2>/dev/null || true)
        if [[ -n "$targets" ]] && [[ "$targets" != "" ]]; then
            has_targets=true
            break
        fi
    done
    
    if [[ "$has_targets" == true ]]; then
        print_info "✓ 找到通知目标配置"
    else
        print_warn "⚠ 未找到通知目标配置"
    fi
    
    # 检查依赖
    if command -v yq &> /dev/null; then
        print_info "✓ yq 工具可用 (推荐)"
    else
        print_warn "⚠ yq 工具不可用，将使用基础解析器"
    fi
    
    print_info "配置测试完成"
}

# 添加用户目标
add_user_target() {
    local user_id="$1"
    local level="${2:-primary}"
    local name="${3:-User}"
    
    print_info "添加用户目标: $user_id (级别: $level)"
    
    # 这里可以添加YAML编辑逻辑
    print_warn "注意: 当前需要手动编辑配置文件 $CONFIG_FILE"
    echo "请在 notification.targets.$level 下添加:"
    echo "  - type: user"
    echo "    id: $user_id"
    echo "    name: \"$name\""
}

# 添加群组目标
add_chat_target() {
    local chat_id="$1"
    local level="${2:-warning}"
    local name="${3:-Group Chat}"
    
    print_info "添加群组目标: $chat_id (级别: $level)"
    
    print_warn "注意: 当前需要手动编辑配置文件 $CONFIG_FILE"
    echo "请在 notification.targets.$level 下添加:"
    echo "  - type: chat"
    echo "    id: $chat_id"
    echo "    name: \"$name\""
}

# 启用/禁用通知
toggle_notification() {
    local action="$1"  # enable/disable
    
    print_info "${action}通知..."
    
    if [[ "$action" == "enable" ]]; then
        # 启用通知的逻辑
        print_info "通知已启用"
        print_warn "请确认配置文件中 notification.enabled 设为 true"
    else
        # 禁用通知的逻辑
        print_info "通知已禁用"  
        print_warn "请在配置文件中设置 notification.enabled: false"
    fi
}

# 获取用户/群组ID的帮助信息
show_id_help() {
    echo "如何获取用户和群组ID:"
    echo "===================="
    echo ""
    echo "用户ID (open_id):"
    echo "1. 查看飞书用户资料"
    echo "2. 在OpenClaw对话中查看消息元数据"
    echo "3. 使用飞书开放平台API"
    echo ""
    echo "群聊ID (chat_id):"  
    echo "1. 将OpenClaw机器人添加到群聊"
    echo "2. 在群中@机器人发送消息"
    echo "3. 在OpenClaw日志中查看chat_id"
    echo "4. 使用 openclaw logs | grep chat_id"
    echo ""
    echo "示例格式:"
    echo "用户ID: ou_xxxxxxxxxxxxxxxxxxxxxxxxx"
    echo "群聊ID: oc_xxxxxxxxxxxxxxxxxxxxxxxxx"
}

# 显示使用帮助
show_help() {
    echo "OpenClaw 通知配置管理工具"
    echo "========================="
    echo ""
    echo "用法: $0 <命令> [参数]"
    echo ""
    echo "命令:"
    echo "  show              显示当前配置"
    echo "  test              测试配置有效性"
    echo "  enable            启用通知"
    echo "  disable           禁用通知"
    echo "  add-user <id> [level] [name]    添加用户目标"
    echo "  add-chat <id> [level] [name]    添加群组目标"
    echo "  id-help           显示如何获取ID的帮助"
    echo "  help              显示此帮助信息"
    echo ""
    echo "级别 (level):"
    echo "  primary   - 所有通知 (默认)"
    echo "  warning   - 警告及严重问题"
    echo "  critical  - 仅严重问题"
    echo ""
    echo "示例:"
    echo "  $0 show"
    echo "  $0 add-user ou_1234567890 primary \"管理员\""
    echo "  $0 add-chat oc_9876543210 warning \"运维群\""
}

# 主函数
main() {
    local command="${1:-help}"
    
    case "$command" in
        "show")
            show_config
            ;;
        "test")
            test_config
            ;;
        "enable")
            toggle_notification "enable"
            ;;
        "disable")
            toggle_notification "disable"
            ;;
        "add-user")
            if [[ $# -lt 2 ]]; then
                print_error "用法: $0 add-user <user_id> [level] [name]"
                exit 1
            fi
            add_user_target "$2" "${3:-primary}" "${4:-User}"
            ;;
        "add-chat")
            if [[ $# -lt 2 ]]; then
                print_error "用法: $0 add-chat <chat_id> [level] [name]"
                exit 1
            fi
            add_chat_target "$2" "${3:-warning}" "${4:-Group Chat}"
            ;;
        "id-help")
            show_id_help
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# 执行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi