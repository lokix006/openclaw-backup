#!/bin/bash
# 脚本名称：OpenClaw技能风险审计
# 作者：OpenClaw Assistant
# 创建时间：2026-03-04
# 用途：扫描已安装技能的安全风险

set -euo pipefail  # 严格模式

# 常量定义
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OPENCLAW_HOME="${HOME}/.openclaw"
readonly WORKSPACE_DIR="${OPENCLAW_HOME}/workspace"
readonly LOG_FILE="/var/log/openclaw/audit-skills.log"
readonly AUDIT_REPORT="/tmp/openclaw-skills-audit-$(date +%Y%m%d).txt"

# 创建日志目录
sudo mkdir -p "$(dirname "$LOG_FILE")"
sudo touch "$LOG_FILE"
sudo chown "$(whoami):$(whoami)" "$LOG_FILE"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# 报告函数
report() {
    echo "$*" | tee -a "$AUDIT_REPORT"
}

# 初始化审计报告
init_audit_report() {
    cat > "$AUDIT_REPORT" << EOF
OpenClaw 技能安全审计报告
=========================
日期: $(date '+%Y-%m-%d %H:%M:%S')
主机: $(hostname)
用户: $(whoami)
=========================

EOF
}

# 扫描技能目录
scan_skills_directory() {
    local skills_dir="$1"
    local dir_name="$2"
    
    if [[ ! -d "$skills_dir" ]]; then
        return 0
    fi
    
    report "扫描目录: $dir_name"
    report "路径: $skills_dir"
    report "----------------------------------------"
    
    local skill_count=0
    local risk_count=0
    
    # 查找所有技能
    find "$skills_dir" -name "SKILL.md" -type f 2>/dev/null | while read -r skill_file; do
        local skill_path
        skill_path=$(dirname "$skill_file")
        local skill_name
        skill_name=$(basename "$skill_path")
        
        skill_count=$((skill_count + 1))
        
        report "技能: $skill_name"
        
        # 检查技能基本信息
        if [[ -f "$skill_path/_meta.json" ]]; then
            local version
            version=$(grep -o '"version":[[:space:]]*"[^"]*"' "$skill_path/_meta.json" 2>/dev/null | cut -d'"' -f4 || echo "unknown")
            report "  版本: $version"
        fi
        
        # 检查最近修改时间
        local mod_time
        mod_time=$(stat -f%Sm -t'%Y-%m-%d %H:%M:%S' "$skill_file" 2>/dev/null || stat -c%y "$skill_file" 2>/dev/null | cut -d'.' -f1 || echo "unknown")
        report "  修改时间: $mod_time"
        
        # 检查技能大小
        local skill_size
        skill_size=$(du -sh "$skill_path" 2>/dev/null | cut -f1 || echo "unknown")
        report "  大小: $skill_size"
        
        # 风险检查
        check_skill_risks "$skill_path" "$skill_name"
        
        report ""
    done
    
    report "目录 $dir_name 扫描完成"
    report ""
}

# 检查单个技能的风险
check_skill_risks() {
    local skill_path="$1"
    local skill_name="$2"
    
    local risk_found=false
    
    # 检查可执行文件
    if find "$skill_path" -type f -executable 2>/dev/null | grep -q .; then
        report "  ⚠ 风险: 包含可执行文件"
        risk_found=true
    fi
    
    # 检查敏感文件扩展名
    if find "$skill_path" -type f \( -name "*.sh" -o -name "*.py" -o -name "*.js" \) 2>/dev/null | grep -q .; then
        local script_count
        script_count=$(find "$skill_path" -type f \( -name "*.sh" -o -name "*.py" -o -name "*.js" \) 2>/dev/null | wc -l)
        report "  ⚠ 风险: 包含脚本文件 ($script_count 个)"
        risk_found=true
    fi
    
    # 检查网络请求代码
    if grep -r -i "http\|curl\|wget\|fetch\|request" "$skill_path" 2>/dev/null | grep -v ".git" | grep -q .; then
        report "  ⚠ 风险: 包含网络请求代码"
        risk_found=true
    fi
    
    # 检查文件系统操作
    if grep -r -E "(rm |mv |cp |mkdir |rmdir )" "$skill_path" 2>/dev/null | grep -v ".git" | grep -q .; then
        report "  ⚠ 风险: 包含文件系统操作"
        risk_found=true
    fi
    
    # 检查系统命令执行
    if grep -r -E "(exec|spawn|system|shell)" "$skill_path" 2>/dev/null | grep -v ".git" | grep -q .; then
        report "  ⚠ 风险: 包含系统命令执行"
        risk_found=true
    fi
    
    # 检查最近修改（可能是新安装或更新）
    if find "$skill_path" -type f -mtime -7 2>/dev/null | grep -q .; then
        report "  ℹ 信息: 最近7天内有文件修改"
    fi
    
    if [[ "$risk_found" == false ]]; then
        report "  ✓ 未发现明显风险"
    fi
}

# 生成风险统计
generate_risk_summary() {
    report "风险统计摘要"
    report "============"
    
    # 统计风险技能数量
    local total_risks
    total_risks=$(grep -c "⚠ 风险" "$AUDIT_REPORT" || echo "0")
    
    local total_skills
    total_skills=$(grep -c "技能:" "$AUDIT_REPORT" || echo "0")
    
    report "总技能数: $total_skills"
    report "发现风险: $total_risks"
    
    if [[ $total_risks -gt 0 ]]; then
        report ""
        report "风险分布："
        grep "⚠ 风险" "$AUDIT_REPORT" | sort | uniq -c | while read -r count risk; do
            report "  $risk ($count 次)"
        done
    fi
    
    report ""
    report "建议："
    if [[ $total_risks -gt 5 ]]; then
        report "- 发现较多风险技能，建议详细审查"
    elif [[ $total_risks -gt 0 ]]; then
        report "- 发现少量风险技能，建议关注"
    else
        report "- 未发现明显风险，保持监控"
    fi
    
    report ""
    report "审计完成时间: $(date '+%Y-%m-%d %H:%M:%S')"
}

# 主函数
main() {
    log "Starting OpenClaw skills security audit"
    
    # 初始化报告
    init_audit_report
    
    # 扫描工作空间技能
    if [[ -d "$WORKSPACE_DIR/skills" ]]; then
        scan_skills_directory "$WORKSPACE_DIR/skills" "工作空间技能"
    fi
    
    # 扫描全局技能
    local global_skills_dirs=(
        "$HOME/.nvm/versions/node/*/lib/node_modules/openclaw/skills"
        "/usr/local/lib/node_modules/openclaw/skills"
    )
    
    for skills_pattern in "${global_skills_dirs[@]}"; do
        for skills_dir in $skills_pattern; do
            if [[ -d "$skills_dir" ]]; then
                scan_skills_directory "$skills_dir" "全局技能"
                break  # 只扫描找到的第一个
            fi
        done
    done
    
    # 生成风险统计
    generate_risk_summary
    
    log "Skills security audit completed. Report generated: $AUDIT_REPORT"
}

# 执行检查
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi