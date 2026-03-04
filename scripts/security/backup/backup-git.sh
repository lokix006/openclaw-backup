#!/bin/bash
# 脚本名称：OpenClaw Git备份系统
# 作者：OpenClaw Assistant
# 创建时间：2026-03-04
# 用途：自动备份OpenClaw工作空间和配置文件到Git仓库

set -euo pipefail  # 严格模式

# 常量定义
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OPENCLAW_HOME="${HOME}/.openclaw"
readonly WORKSPACE_DIR="${OPENCLAW_HOME}/workspace"
readonly BACKUP_DIR="${OPENCLAW_HOME}/backup"
readonly LOG_FILE="/var/log/openclaw/backup-git.log"

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

# 检查Git是否安装
check_git() {
    if ! command -v git &> /dev/null; then
        error_exit "Git is not installed. Please install git first."
    fi
}

# 初始化备份仓库
init_backup_repo() {
    local backup_dir="$1"
    
    if [[ ! -d "$backup_dir/.git" ]]; then
        log "Initializing backup repository at $backup_dir"
        mkdir -p "$backup_dir"
        cd "$backup_dir"
        git init
        
        # 创建.gitignore
        cat > .gitignore << 'EOF'
# OpenClaw 备份忽略文件
*.log
*.tmp
.DS_Store
node_modules/
__pycache__/
*.pyc
.env
secrets/
EOF
        
        # 初始提交
        git add .gitignore
        git commit -m "Initial commit: Setup OpenClaw backup repository"
        log "Backup repository initialized"
    else
        log "Backup repository already exists"
    fi
}

# 复制文件到备份目录
copy_files() {
    local backup_dir="$1"
    
    log "Copying files to backup directory"
    
    # 创建备份目录结构
    mkdir -p "$backup_dir"/{workspace,config,scripts}
    
    # 备份工作空间（如果存在）
    if [[ -d "$WORKSPACE_DIR" ]]; then
        log "Backing up workspace"
        rsync -av --delete --exclude='.git' "$WORKSPACE_DIR/" "$backup_dir/workspace/" || log "Warning: Failed to backup workspace"
    fi
    
    # 备份配置文件
    log "Backing up configuration files"
    if [[ -f "$OPENCLAW_HOME/openclaw.json" ]]; then
        cp "$OPENCLAW_HOME/openclaw.json" "$backup_dir/config/" || log "Warning: Failed to backup openclaw.json"
    fi
    
    if [[ -f "$OPENCLAW_HOME/config.json" ]]; then
        cp "$OPENCLAW_HOME/config.json" "$backup_dir/config/" || log "Warning: Failed to backup config.json"
    fi
    
    # 备份脚本目录
    if [[ -d "$WORKSPACE_DIR/scripts" ]]; then
        log "Backing up scripts"
        rsync -av --delete --exclude='.git' "$WORKSPACE_DIR/scripts/" "$backup_dir/scripts/" || log "Warning: Failed to backup scripts"
    fi
}

# 提交更改
commit_changes() {
    local backup_dir="$1"
    local commit_msg="$2"
    
    cd "$backup_dir"
    
    # 先添加所有文件
    log "Adding files to git"
    git add .
    
    # 检查是否有更改
    if git diff --staged --quiet; then
        log "No changes to commit"
        return 0
    fi
    
    log "Committing changes"
    git commit -m "$commit_msg" || log "Warning: Failed to commit changes"
}

# 推送到远程仓库（如果配置了）
push_to_remote() {
    local backup_dir="$1"
    
    cd "$backup_dir"
    
    # 检查是否配置了远程仓库
    if git remote | grep -q origin; then
        log "Pushing to remote repository"
        git push origin main 2>/dev/null || git push origin master 2>/dev/null || log "Warning: Failed to push to remote"
    else
        log "No remote repository configured, skipping push"
    fi
}

# 清理旧的备份（保留最近30次提交）
cleanup_old_backups() {
    local backup_dir="$1"
    
    cd "$backup_dir"
    
    # 获取提交数量
    local commit_count
    commit_count=$(git rev-list --count HEAD 2>/dev/null || echo "0")
    
    if [[ $commit_count -gt 30 ]]; then
        log "Cleaning up old backups (keeping last 30 commits)"
        # 这里可以添加清理逻辑，暂时只记录日志
        log "Current commit count: $commit_count"
    fi
}

# 生成备份报告
generate_report() {
    local backup_dir="$1"
    
    cd "$backup_dir"
    
    log "=== Backup Report ==="
    log "Backup directory: $backup_dir"
    log "Last commit: $(git log -1 --format='%h %s' 2>/dev/null || echo 'No commits')"
    log "Repository size: $(du -sh . 2>/dev/null | cut -f1 || echo 'Unknown')"
    log "Total commits: $(git rev-list --count HEAD 2>/dev/null || echo '0')"
    
    if git remote | grep -q origin; then
        log "Remote repository: $(git remote get-url origin 2>/dev/null || echo 'Not configured')"
    else
        log "Remote repository: Not configured"
    fi
    log "==================="
}

# 主函数
main() {
    log "Starting OpenClaw backup process"
    
    # 检查依赖
    check_git
    
    # 初始化备份仓库
    init_backup_repo "$BACKUP_DIR"
    
    # 复制文件
    copy_files "$BACKUP_DIR"
    
    # 提交更改
    local commit_msg="Automated backup: $(date '+%Y-%m-%d %H:%M:%S')"
    commit_changes "$BACKUP_DIR" "$commit_msg"
    
    # 推送到远程
    push_to_remote "$BACKUP_DIR"
    
    # 清理旧备份
    cleanup_old_backups "$BACKUP_DIR"
    
    # 生成报告
    generate_report "$BACKUP_DIR"
    
    log "Backup process completed successfully"
}

# 执行检查
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi