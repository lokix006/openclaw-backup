#!/bin/bash
# OpenClaw工作区自动清理脚本
# 作者：OpenClaw Assistant
# 创建时间：2026-03-04
# 用途：定期清理临时文件和过期内容

set -euo pipefail

readonly WORKSPACE_DIR="${HOME}/.openclaw/workspace"
readonly LOG_FILE="/var/log/openclaw/maintenance-cleanup.log"

# 确保日志目录存在
sudo mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
sudo touch "$LOG_FILE" 2>/dev/null || true

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE" 2>/dev/null || echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# 清理临时文件
cleanup_temp_files() {
    log "开始清理临时文件..."
    
    local temp_dir="$WORKSPACE_DIR/outputs/temp"
    if [[ -d "$temp_dir" ]]; then
        # 删除7天前的文件
        local deleted_count=0
        while IFS= read -r -d '' file; do
            log "删除过期文件: $(basename "$file")"
            rm -f "$file"
            ((deleted_count++))
        done < <(find "$temp_dir" -type f -name "*.md" -mtime +7 -print0 2>/dev/null)
        
        log "清理完成，删除了 $deleted_count 个临时文件"
    fi
}

# 清理重复文件
cleanup_duplicate_files() {
    log "检查重复文件..."
    
    # 检查根目录是否有应该归档的报告文件
    cd "$WORKSPACE_DIR"
    local moved_count=0
    
    for file in *review*.md *analysis*.md *audit*.md *report*.md; do
        if [[ -f "$file" && "$file" != "WORKSPACE_FILE_ORGANIZATION.md" ]]; then
            log "发现未归档文件: $file，移动到outputs/temp/"
            mv "$file" "outputs/temp/temp-$(basename "$file" .md)-$(date +%Y%m%d_%H%M).md"
            ((moved_count++))
        fi
    done
    
    if [[ $moved_count -gt 0 ]]; then
        log "移动了 $moved_count 个文件到temp目录"
    fi
}

# 清理空目录
cleanup_empty_dirs() {
    log "清理空目录..."
    
    find "$WORKSPACE_DIR" -type d -empty -not -path "*/.*" 2>/dev/null | while read -r dir; do
        log "删除空目录: $dir"
        rmdir "$dir" 2>/dev/null || true
    done
}

# 清理系统临时文件
cleanup_system_temp() {
    log "清理系统临时文件..."
    
    # 清理/tmp/下的OpenClaw相关旧文件（3天前）
    find /tmp -name "openclaw-*" -type f -mtime +3 2>/dev/null | while read -r file; do
        log "删除系统临时文件: $(basename "$file")"
        rm -f "$file"
    done
}

# 生成清理报告
generate_cleanup_report() {
    local report_file="$WORKSPACE_DIR/outputs/temp/cleanup-report-$(date +%Y%m%d_%H%M).md"
    
    cat > "$report_file" << EOF
# 自动清理报告

**执行时间：** $(date '+%Y-%m-%d %H:%M:%S')

## 清理统计
- 工作区大小：$(du -sh "$WORKSPACE_DIR" | cut -f1)
- 临时文件目录：$(du -sh "$WORKSPACE_DIR/outputs/temp" 2>/dev/null | cut -f1 || echo "0B")
- 系统临时文件：$(find /tmp -name "openclaw-*" -type f | wc -l) 个

## 清理规则执行
✅ 删除7天前的temp文件
✅ 检查并移动未归档的报告文件
✅ 清理空目录
✅ 清理系统临时文件

详细日志：$LOG_FILE
EOF

    log "清理报告生成：$report_file"
}

# 主函数
main() {
    log "===================="
    log "开始自动清理任务"
    
    cleanup_temp_files
    cleanup_duplicate_files  
    cleanup_empty_dirs
    cleanup_system_temp
    generate_cleanup_report
    
    log "自动清理任务完成"
    log "===================="
}

# 执行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi