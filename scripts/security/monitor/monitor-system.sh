#!/bin/bash
# 脚本名称：OpenClaw系统安全巡检
# 作者：OpenClaw Assistant
# 创建时间：2026-03-04
# 用途：每日自动安全巡检，检查系统完整性和异常行为

set -euo pipefail  # 严格模式

# 常量定义
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OPENCLAW_HOME="${HOME}/.openclaw"
readonly WORKSPACE_DIR="${OPENCLAW_HOME}/workspace"
readonly LOG_FILE="/var/log/openclaw/monitor-system.log"
readonly REPORT_FILE="/tmp/openclaw-security-report-$(date +%Y%m%d).txt"

# 创建日志目录
sudo mkdir -p "$(dirname "$LOG_FILE")"
sudo touch "$LOG_FILE"
sudo chown "$(whoami):$(whoami)" "$LOG_FILE"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# 错误处理
error_exit() {
    log "ERROR: $1"
    exit 1
}

# 报告函数
report() {
    echo "$*" | tee -a "$REPORT_FILE"
}

# 初始化报告
init_report() {
    cat > "$REPORT_FILE" << EOF
OpenClaw 安全巡检报告
=====================
日期: $(date '+%Y-%m-%d %H:%M:%S')
主机: $(hostname)
用户: $(whoami)
=====================

EOF
}

# 1. 检查系统基础状态
check_system_basic() {
    report "1. 系统基础状态检查"
    report "----------------------"
    
    # 系统负载
    local load_avg
    load_avg=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//')
    report "✓ 系统负载: $load_avg"
    
    # 内存使用
    local memory_usage
    memory_usage=$(free -h | grep Mem | awk '{printf "已用: %s/%s (%.1f%%)", $3, $2, ($3/$2)*100}' 2>/dev/null || echo "获取失败")
    report "✓ 内存使用: $memory_usage"
    
    # 磁盘使用
    report "✓ 磁盘使用:"
    df -h | grep -E '^/dev/' | awk '{printf "  %s: %s/%s (%s)\n", $1, $3, $2, $5}' >> "$REPORT_FILE"
    
    report ""
}

# 2. 检查OpenClaw进程状态
check_openclaw_process() {
    report "2. OpenClaw进程状态"
    report "---------------------"
    
    if pgrep -f openclaw > /dev/null; then
        local process_count
        process_count=$(pgrep -f openclaw | wc -l)
        report "✓ OpenClaw进程运行中 (进程数: $process_count)"
        
        # 显示进程信息
        report "进程详情:"
        pgrep -f openclaw | while read -r pid; do
            local cmd
            cmd=$(ps -p "$pid" -o cmd= 2>/dev/null || echo "进程已退出")
            report "  PID $pid: $cmd"
        done
    else
        report "⚠ WARNING: OpenClaw进程未运行"
    fi
    
    report ""
}

# 3. 检查核心文件完整性
check_file_integrity() {
    report "3. 核心文件完整性检查"
    report "------------------------"
    
    local files_to_check=(
        "$OPENCLAW_HOME/openclaw.json"
        "$OPENCLAW_HOME/config.json"
        "$WORKSPACE_DIR/SOUL.md"
        "$WORKSPACE_DIR/USER.md"
        "$WORKSPACE_DIR/MEMORY.md"
    )
    
    for file in "${files_to_check[@]}"; do
        if [[ -f "$file" ]]; then
            local file_size
            file_size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "unknown")
            local file_time
            file_time=$(stat -f%Sm -t'%Y-%m-%d %H:%M:%S' "$file" 2>/dev/null || stat -c%y "$file" 2>/dev/null | cut -d'.' -f1 || echo "unknown")
            report "✓ $file 存在 (大小: ${file_size}B, 修改时间: $file_time)"
            
            # 检查文件是否被锁定
            if command -v lsattr &> /dev/null; then
                local attr
                attr=$(lsattr "$file" 2>/dev/null | awk '{print $1}' || echo "unknown")
                if [[ "$attr" == *i* ]]; then
                    report "  🔒 文件已设置immutable属性保护"
                fi
            fi
        else
            report "⚠ WARNING: $file 不存在"
        fi
    done
    
    report ""
}

# 4. 检查网络连接
check_network_connections() {
    report "4. 网络连接检查"
    report "------------------"
    
    # 检查监听端口
    local listening_ports
    listening_ports=$(netstat -tln 2>/dev/null | grep LISTEN | wc -l || echo "0")
    report "✓ 监听端口数量: $listening_ports"
    
    # 显示前5个监听端口
    if command -v netstat &> /dev/null; then
        report "主要监听端口:"
        netstat -tln 2>/dev/null | grep LISTEN | head -5 | awk '{print "  " $4}' >> "$REPORT_FILE" || true
    fi
    
    # 检查异常外联连接
    local external_connections
    external_connections=$(netstat -tn 2>/dev/null | grep ESTABLISHED | grep -v '127.0.0.1\|::1' | wc -l || echo "0")
    report "✓ 外部连接数量: $external_connections"
    
    if [[ $external_connections -gt 10 ]]; then
        report "⚠ WARNING: 外部连接数量较多，请检查是否正常"
    fi
    
    report ""
}

# 5. 检查最近的Skills活动并运行安全审计
check_recent_skills() {
    report "5. Skills安全检查"
    report "--------------------"
    
    # 检查skills目录
    local skills_dirs=(
        "$WORKSPACE_DIR/skills"
        "$HOME/.nvm/versions/node/*/lib/node_modules/openclaw/skills"
    )
    
    local skill_count=0
    for skills_dir in "${skills_dirs[@]}"; do
        # 处理通配符
        for dir in $skills_dir; do
            if [[ -d "$dir" ]]; then
                # 查找最近7天修改的skills
                local recent_skills
                recent_skills=$(find "$dir" -name "SKILL.md" -mtime -7 2>/dev/null | wc -l || echo "0")
                if [[ $recent_skills -gt 0 ]]; then
                    report "✓ 发现 $recent_skills 个最近7天内修改的skills"
                    skill_count=$((skill_count + recent_skills))
                    
                    # 显示具体的skills
                    find "$dir" -name "SKILL.md" -mtime -7 2>/dev/null | while read -r skill_file; do
                        local skill_name
                        skill_name=$(dirname "$skill_file" | xargs basename)
                        local mod_time
                        mod_time=$(stat -f%Sm -t'%Y-%m-%d %H:%M' "$skill_file" 2>/dev/null || stat -c%y "$skill_file" 2>/dev/null | cut -d'.' -f1 || echo "unknown")
                        report "  - $skill_name (修改时间: $mod_time)"
                    done
                fi
            fi
        done
    done
    
    if [[ $skill_count -eq 0 ]]; then
        report "✓ 最近7天内无新的skills活动"
    fi
    
    # 运行技能安全审计
    report ""
    report "技能安全审计："
    local audit_script="$WORKSPACE_DIR/scripts/security/audit/audit-skills.sh"
    if [[ -f "$audit_script" ]]; then
        if "$audit_script" >/dev/null 2>&1; then
            local audit_report="/tmp/openclaw-skills-audit-$(date +%Y%m%d).txt"
            if [[ -f "$audit_report" ]]; then
                local risk_count
                risk_count=$(grep -c "⚠ 风险" "$audit_report" 2>/dev/null || echo "0")
                report "✓ 技能审计完成，发现 $risk_count 个风险项"
                if [[ $risk_count -gt 0 ]]; then
                    report "⚠ 建议查看详细报告: $audit_report"
                fi
            else
                report "✓ 技能审计完成"
            fi
        else
            report "⚠ WARNING: 技能审计执行失败"
        fi
    else
        report "ℹ 技能审计脚本不存在，跳过审计"
    fi
    
    report ""
}

# 6. 检查系统日志异常
check_system_logs() {
    report "6. 系统日志异常检查"
    report "---------------------"
    
    # 检查最近的错误日志
    local error_count=0
    
    # 检查系统日志(如果可访问)
    if [[ -f /var/log/syslog ]]; then
        error_count=$(grep -i error /var/log/syslog | grep "$(date '+%b %d')" | wc -l 2>/dev/null || echo "0")
        report "✓ 今日系统错误日志: $error_count 条"
    elif [[ -f /var/log/messages ]]; then
        error_count=$(grep -i error /var/log/messages | grep "$(date '+%b %d')" | wc -l 2>/dev/null || echo "0")
        report "✓ 今日系统错误日志: $error_count 条"
    else
        report "ℹ 无法访问系统日志文件"
    fi
    
    # 检查OpenClaw相关日志
    if [[ -d /var/log/openclaw ]]; then
        local openclaw_logs
        openclaw_logs=$(find /var/log/openclaw -name "*.log" -mtime -1 2>/dev/null | wc -l || echo "0")
        report "✓ OpenClaw日志文件数量: $openclaw_logs"
    fi
    
    if [[ $error_count -gt 50 ]]; then
        report "⚠ WARNING: 今日错误日志数量较多，建议检查"
    fi
    
    report ""
}

# 7. 检查Git备份状态
check_git_backup() {
    report "7. Git备份状态检查"
    report "--------------------"
    
    local backup_dir="$OPENCLAW_HOME/backup"
    
    if [[ -d "$backup_dir/.git" ]]; then
        cd "$backup_dir"
        
        local last_commit
        last_commit=$(git log -1 --format='%cd %s' --date=short 2>/dev/null || echo "无提交记录")
        report "✓ Git备份仓库存在"
        report "✓ 最后备份: $last_commit"
        
        # 检查是否有未提交的更改
        if ! git diff --quiet || ! git diff --staged --quiet; then
            report "⚠ WARNING: 发现未提交的更改，建议运行备份脚本"
        else
            report "✓ 工作区状态: 干净"
        fi
        
        # 检查远程仓库状态
        if git remote | grep -q origin; then
            report "✓ 远程仓库已配置"
        else
            report "ℹ 远程仓库未配置"
        fi
    else
        report "⚠ WARNING: Git备份仓库不存在，建议运行初始化脚本"
    fi
    
    report ""
}

# 8. 检查磁盘空间
check_disk_space() {
    report "8. 磁盘空间检查"
    report "-----------------"
    
    # 检查根目录空间
    local root_usage
    root_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//' || echo "0")
    
    if [[ $root_usage -gt 90 ]]; then
        report "❌ CRITICAL: 根目录磁盘使用率过高 ($root_usage%)"
    elif [[ $root_usage -gt 80 ]]; then
        report "⚠ WARNING: 根目录磁盘使用率较高 ($root_usage%)"
    else
        report "✓ 根目录磁盘使用率正常 ($root_usage%)"
    fi
    
    # 检查OpenClaw目录大小
    if [[ -d "$OPENCLAW_HOME" ]]; then
        local openclaw_size
        openclaw_size=$(du -sh "$OPENCLAW_HOME" 2>/dev/null | cut -f1 || echo "unknown")
        report "✓ OpenClaw目录大小: $openclaw_size"
    fi
    
    report ""
}

# 生成总结
generate_summary() {
    report "安全巡检总结"
    report "============"
    
    # 统计警告和错误
    local warning_count
    local critical_count
    warning_count=$(grep -c "WARNING" "$REPORT_FILE" || echo "0")
    critical_count=$(grep -c "CRITICAL" "$REPORT_FILE" || echo "0")
    
    if [[ $critical_count -gt 0 ]]; then
        report "❌ 发现 $critical_count 个严重问题，需要立即处理"
    elif [[ $warning_count -gt 0 ]]; then
        report "⚠ 发现 $warning_count 个警告，建议关注"
    else
        report "✅ 系统状态良好，无异常发现"
    fi
    
    report ""
    report "报告生成时间: $(date '+%Y-%m-%d %H:%M:%S')"
    report "详细报告位置: $REPORT_FILE"
    report "============"
}

# 主函数
main() {
    log "Starting OpenClaw security audit"
    
    # 初始化报告
    init_report
    
    # 执行各项检查
    check_system_basic
    check_openclaw_process
    check_file_integrity
    check_network_connections
    check_recent_skills
    check_system_logs
    check_git_backup
    check_disk_space
    
    # 生成总结
    generate_summary
    
    # 输出报告摘要到日志
    log "Security audit completed. Report generated: $REPORT_FILE"
    
    # 显示关键信息到终端
    if [[ -t 1 ]]; then  # 如果是交互式终端
        echo ""
        echo "=== 巡检摘要 ==="
        tail -10 "$REPORT_FILE"
    fi
}

# 执行检查
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi