# OpenClaw 脚本规范

## 📁 目录结构
```
scripts/
├── README.md              # 本规范文档
├── security/               # 安全相关脚本
│   ├── backup/            # 备份脚本
│   ├── audit/             # 审计脚本
│   └── monitor/           # 监控脚本
├── utils/                 # 工具脚本
└── config/               # 配置文件
```

## 📝 命名规范

### Shell脚本命名
- **格式**：`功能-子功能.sh`
- **示例**：`backup-git.sh`, `audit-skills.sh`, `monitor-system.sh`
- **要求**：全小写，单词用横线分隔

### Python脚本命名
- **格式**：`功能_子功能.py`
- **示例**：`backup_git.py`, `audit_skills.py`, `monitor_system.py`
- **要求**：全小写，单词用下划线分隔

### 配置文件命名
- **格式**：`功能.conf` 或 `功能.yaml`
- **示例**：`backup.conf`, `monitor.yaml`

## 🔧 脚本规范

### Shell脚本模板
```bash
#!/bin/bash
# 脚本名称：功能描述
# 作者：OpenClaw Assistant
# 创建时间：$(date +%Y-%m-%d)
# 用途：具体功能说明

set -euo pipefail  # 严格模式

# 常量定义
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="/var/log/openclaw/$(basename "$0" .sh).log"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# 错误处理
error_exit() {
    log "ERROR: $1"
    exit 1
}

# 主函数
main() {
    log "Starting $(basename "$0")"
    # 脚本逻辑
    log "Completed $(basename "$0")"
}

# 执行检查
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

### Python脚本模板
```python
#!/usr/bin/env python3
"""
脚本名称：功能描述
作者：OpenClaw Assistant
创建时间：$(date +%Y-%m-%d)
用途：具体功能说明
"""

import os
import sys
import logging
from datetime import datetime
from pathlib import Path

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(f'/var/log/openclaw/{Path(__file__).stem}.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

def main():
    """主函数"""
    logger.info(f"Starting {Path(__file__).name}")
    try:
        # 脚本逻辑
        pass
    except Exception as e:
        logger.error(f"Script failed: {e}")
        sys.exit(1)
    logger.info(f"Completed {Path(__file__).name}")

if __name__ == "__main__":
    main()
```

## 🛡️ 安全要求

1. **权限控制**：脚本文件权限设为 755，敏感配置文件设为 600
2. **输入验证**：所有外部输入必须验证和清理
3. **日志记录**：重要操作必须记录日志
4. **错误处理**：必须有适当的错误处理机制
5. **依赖检查**：运行前检查必要的依赖和权限

## 📋 代码质量

### Shell脚本
- 使用 `shellcheck` 检查语法
- 使用 `set -euo pipefail` 严格模式
- 变量使用双引号包围
- 使用 `readonly` 声明常量

### Python脚本
- 使用 `pylint` 或 `flake8` 检查代码质量
- 遵循 PEP 8 代码风格
- 使用类型提示（Python 3.6+）
- 添加适当的文档字符串

## 🔄 版本控制

- 所有脚本纳入Git版本控制
- 重要修改必须有commit说明
- 使用语义化版本号标记重要更新

## 📞 联系方式

如有问题或建议，请通过对话向OpenClaw Assistant反馈。

---
最后更新：$(date +%Y-%m-%d)