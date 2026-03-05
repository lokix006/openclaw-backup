# OpenClaw Binding配置问题诊断报告

**诊断时间：** 2026-03-05 02:32  
**问题描述：** 飞书消息未按预期路由到ikoL Agent

---

## 🔍 问题根因分析

### 核心问题：accountId不匹配

**配置期望：**
```json
"bindings": [
  {
    "agentId": "ikol", 
    "match": {
      "channel": "feishu",
      "accountId": "feishu-loki"  ← 期望匹配这个
    }
  }
]
```

**实际情况：**
```
当前消息的 account_id: "0"    ← 实际是这个
预期匹配的 accountId: "feishu-loki"

结果：不匹配 → 路由到默认的main Agent
```

---

## 🛠️ 具体修复方案

### 方案1: 修正accountId匹配（推荐）

```json
// 修改 ~/.openclaw/openclaw.json
"bindings": [
  {
    "agentId": "ikol",
    "match": {
      "channel": "feishu",
      "accountId": "0"        // 改为实际的账户ID
    }
  }
]
```

### 方案2: 移除accountId限制

```json
// 如果只有一个飞书账户，可以不指定accountId
"bindings": [
  {
    "agentId": "ikol", 
    "match": {
      "channel": "feishu"     // 所有飞书消息都路由到ikol
    }
  }
]
```

### 方案3: 按peer类型路由（更精细）

```json
// 按用户ID或群聊ID进行更精确的路由
"bindings": [
  {
    "agentId": "ikol",
    "match": {
      "channel": "feishu",
      "peer": {
        "kind": "user", 
        "id": "ou_570aeb8842a1cbbc0313861d2b5c128f"
      }
    }
  }
]
```

---

## 🔧 立即修复步骤

### Step 1: 备份当前配置
```bash
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.backup-$(date +%Y%m%d_%H%M)
```

### Step 2: 修改binding配置（选择一个方案）

**推荐方案1 - 修正accountId：**
```bash
# 修改accountId从 "feishu-loki" 到 "0"
sed -i 's/"accountId": "feishu-loki"/"accountId": "0"/' ~/.openclaw/openclaw.json
```

**或者方案2 - 移除accountId：**
```bash
# 移除accountId限制，只匹配channel
# 需要手动编辑JSON，移除accountId字段
```

### Step 3: 重启OpenClaw服务
```bash
# 重启OpenClaw以应用新配置
openclaw gateway restart
# 或者如果是daemon mode:
# systemctl restart openclaw
```

### Step 4: 测试验证
```bash
# 发送测试消息，检查是否路由到ikol Agent
# 查看新的会话是否显示为 agent:ikol:feishu:...
```

---

## ⚠️ 注意事项

1. **配置生效需要重启** - binding更改需要重启OpenClaw
2. **会话继承** - 现有会话可能仍然使用main Agent
3. **权限差异** - ikol Agent可能有不同的工具权限集
4. **工作空间切换** - ikol将使用 `/root/.openclaw/workspace/ikoL/` 作为工作目录

---

## 💡 验证修复的方法

修复后，新的飞书消息会话应该显示为：
```
Sessions表中：
agent:ikol:feishu:direct:ou_570...  ← 应该是ikol而不是main
```

这时ikol Agent将：
- 使用 `/root/.openclaw/workspace/ikoL/SOUL.md` 等配置
- 有独立的记忆和工作空间
- 可能有不同的响应风格和权限

---

**建议选择方案1（修正accountId为"0"），这是最简单的修复方法。**