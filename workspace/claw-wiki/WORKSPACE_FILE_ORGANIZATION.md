# OpenClaw 工作区文件组织规则

**创建时间：** 2026-03-04  
**作者：** OpenClaw Assistant  
**用户确认：** 待Loki X确认

---

## 🎯 设计原则

1. **按性质分类** - 不同类型文件放在对应目录
2. **按时间归档** - 临时文件定期清理，重要文件按时间归档  
3. **易于查找** - 清晰的命名规范和目录结构
4. **自动化管理** - 定时清理和归档机制

---

## 📁 目录结构规划

### 根目录（仅核心配置）
```
~/.openclaw/workspace/
├── AGENTS.md          # Agent工作原则
├── SOUL.md            # Agent人格定义
├── USER.md            # 用户信息
├── MEMORY.md          # 长期记忆
├── IDENTITY.md        # Agent身份
├── TOOLS.md           # 本地工具配置
├── HEARTBEAT.md       # 心跳任务配置
├── BOOTSTRAP.md       # 首次启动指导（可选）
└── 本规则文件
```

### 功能目录分类
```
├── reports/           # 📊 分析报告和审查文档
│   ├── 2026-03/       # 按月亨档
│   │   ├── technical-reviews/
│   │   ├── security-audits/
│   │   └── system-analysis/
│   └── archive/       # 旧报告归档
│
├── outputs/           # 🗂️ 临时输出和工作产物
│   ├── temp/          # 临时文件（7天自动清理）
│   ├── drafts/        # 草稿文件
│   └── exports/       # 导出数据
│
├── memory/            # 🧠 记忆文件
│   ├── daily/         # 每日记忆
│   │   └── YYYY-MM-DD.md
│   └── sessions/      # 会话记录（可选）
│
├── scripts/           # 🔧 脚本和自动化
│   ├── security/      # 安全相关
│   ├── backup/        # 备份脚本
│   └── utils/         # 通用工具
│
├── skills/            # 🎯 技能配置
│   └── [skill-name]/
│
└── projects/          # 📋 项目相关文档
    ├── merlin-pms/
    ├── fork12-migration/
    └── [other-projects]/
```

---

## 📝 文件命名规范

### 报告文件
```
格式：[project]-[type]-[date].md
示例：
- merlin-pms-review-20260304.md
- fork12-migration-analysis-20260304.md  
- security-audit-20260304.md
```

### 临时文件
```
格式：temp-[purpose]-[timestamp].md
示例：
- temp-analysis-20260304-1630.md
- temp-draft-20260304-1445.md
```

### 配置文件
```
格式：大写字母，功能明确
示例：
- SECURITY_RULES.md
- BACKUP_CONFIG.md
```

---

## 🔄 自动化管理规则

### 定期清理（建议cron任务）
```bash
# 每周日凌晨2点执行清理
0 2 * * 0 ~/.openclaw/workspace/scripts/maintenance/auto-cleanup.sh

清理规则：
- outputs/temp/ 中7天前的文件
- 重复的分析文件
- 空的或无效的临时文件
```

### 自动归档（建议月度）
```bash
# 每月1号凌晨3点执行归档
0 3 1 * * ~/.openclaw/workspace/scripts/maintenance/auto-archive.sh

归档规则：
- 将上月的reports移动到archive/
- 压缩旧的memory文件
- 生成月度工作总结
```

---

## 🎯 立即整理建议

### 当前散乱文件重新归档
```bash
# 创建目录结构
mkdir -p reports/2026-03/technical-reviews
mkdir -p reports/2026-03/security-audits  
mkdir -p outputs/temp
mkdir -p projects/merlin-pms
mkdir -p projects/fork12-migration

# 归档当前报告文件
mv merlin_pms_review_report.md reports/2026-03/technical-reviews/
mv fork12_migration_review.md reports/2026-03/technical-reviews/
mv feishu_permissions_security_audit.md reports/2026-03/security-audits/
mv complete_feishu_permissions_numbered.md reports/2026-03/security-audits/
mv md_cleanup_log.md reports/2026-03/system-analysis/

# 创建符合规范的文件名
cd reports/2026-03/technical-reviews/
mv merlin_pms_review_report.md merlin-pms-review-20260304.md
mv fork12_migration_review.md fork12-migration-analysis-20260304.md

cd ../security-audits/
mv feishu_permissions_security_audit.md feishu-security-audit-20260304.md
mv complete_feishu_permissions_numbered.md feishu-permissions-list-20260304.md

cd ../system-analysis/
mv md_cleanup_log.md workspace-cleanup-log-20260304.md
```

---

## 🤖 AI行为规范

### 文件创建时的决策树
```
创建新文件时问自己：

1. 这是什么类型的文件？
   - 分析报告 → reports/YYYY-MM/
   - 临时输出 → outputs/temp/
   - 配置文档 → 对应功能目录
   - 项目文档 → projects/[project-name]/

2. 这个文件的生命周期？
   - 临时（<7天） → outputs/temp/
   - 短期（<30天） → outputs/
   - 长期保存 → reports/归档

3. 文件名是否符合规范？
   - 包含项目名/用途/日期
   - 小写字母用短横线分隔
   - 避免空格和特殊字符
```

### 清理责任
- **每次会话结束前**：检查是否有临时文件需要归档
- **每周心跳时**：提醒清理过期临时文件
- **月度回顾时**：整理和归档重要文件

---

## 💡 核心理念

**"一切就绪，井井有条"**
- 每个文件都有明确的位置和用途
- 临时文件不会永久占用空间
- 重要输出能够便于检索
- 维护工作最小化，自动化优先

---

**需要你确认这个规则，然后我立即执行重新整理！**