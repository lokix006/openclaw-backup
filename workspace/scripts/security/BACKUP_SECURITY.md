# 备份安全配置

## 🔒 敏感信息脱敏规则

### 自动脱敏的字段类型
备份脚本会自动检测并脱敏以下类型的敏感信息：

#### JSON配置文件脱敏
- `secret` - 密钥、秘密
- `token` - 令牌、访问令牌  
- `password` - 密码
- `key` - API密钥、私钥
- `private` - 私有信息
- `webhook` - Webhook URL
- `api_key` - API密钥
- `access_token` - 访问令牌
- `refresh_token` - 刷新令牌
- `client_secret` - 客户端密钥
- `bot_token` - 机器人令牌
- `app_secret` - 应用密钥

### 脱敏示例

**原始配置：**
```json
{
  "feishu": {
    "app_id": "cli_a1234567890",
    "app_secret": "abcd1234efgh5678ijkl",
    "webhook_secret": "v1234567890",
    "bot_token": "t-g987654321fedcba"
  }
}
```

**脱敏后：**
```json
{
  "feishu": {
    "app_id": "cli_a1234567890",
    "app_secret": "***REDACTED***",
    "webhook_secret": "***REDACTED***", 
    "bot_token": "***REDACTED***"
  }
}
```

## 📁 忽略的文件类型

以下文件类型将完全排除在备份之外：

### 环境配置
- `.env` - 环境变量文件
- `.env.*` - 所有环境变量文件变体

### 密钥文件
- `*.pem` - PEM格式密钥
- `*.key` - 私钥文件
- `*.p12` - PKCS#12证书
- `*.pfx` - 个人信息交换文件

### 敏感目录
- `secrets/` - 密钥目录
- `private_keys/` - 私钥目录
- `ssh_keys/` - SSH密钥目录

### 临时文件
- `*.log` - 日志文件
- `*.tmp` - 临时文件
- `node_modules/` - Node.js依赖
- `__pycache__/` - Python缓存

## 🛡️ 安全建议

### 1. 验证脱敏效果
运行备份后，检查生成的配置文件：
```bash
cd ~/.openclaw/backup
cat config/openclaw.json | grep -E "(secret|token|key|password)"
```

### 2. 手动检查敏感信息
定期审查备份内容：
```bash
# 搜索可能的敏感信息
cd ~/.openclaw/backup  
grep -r -i -E "(password|secret|token|key)" . --exclude-dir=.git
```

### 3. 远程仓库安全
- 使用私有仓库
- 定期轮换访问密钥
- 启用两因素认证
- 限制仓库访问权限

### 4. 本地备份安全
- 备份目录权限设为700：`chmod 700 ~/.openclaw/backup`
- 定期检查本地备份完整性
- 考虑加密本地备份

## ⚠️ 注意事项

1. **脱敏不是万能的**：新的敏感字段可能需要手动添加到脱敏规则
2. **配置结构变化**：OpenClaw配置格式变化时需要更新脱敏规则
3. **审查责任**：用户仍需定期审查备份内容确保安全
4. **恢复考虑**：脱敏后的备份需要手动恢复敏感信息才能使用

## 🔧 自定义脱敏规则

如需添加新的敏感字段模式，编辑备份脚本中的数组：

```bash
# 在 backup-git.sh 中找到并修改
local sensitive_patterns=(
    "secret"
    "token"
    # 添加新的模式
    "your_custom_field"
)
```

---

最后更新：2026-03-04