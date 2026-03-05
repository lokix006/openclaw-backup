# OpenClaw 多账户Binding问题诊断报告

**诊断时间：** 2026-03-05 02:38  
**问题：** 自定义accountId "feishu-loki" 未正确路由到ikol Agent

---

## 🔍 问题根因分析

### 当前配置检查

**你的当前配置：**
```json
// ~/.openclaw/openclaw.json
"channels": {
  "feishu": {
    "accounts": [
      {
        "accountId": "feishu-loki",  ✅ 自定义账户ID
        "appId": "cli_a90a158106f8deef",
        // ... 其他配置
      }
    ]
  }
},
"bindings": [
  {
    "agentId": "ikol",
    "match": {
      "channel": "feishu", 
      "accountId": "feishu-loki"  ✅ 绑定配置正确
    }
  }
]
```

**实际消息元数据：**
```json
{
  "account_id": "0",  ❌ 实际是 "0" 而不是 "feishu-loki"
  "channel": "feishu"
}
```

### 🎯 问题核心：AccountId不匹配

**根本问题：** OpenClaw内部将你的飞书账户识别为 `"0"` 而不是配置中的 `"feishu-loki"`

---

## 📚 OpenClaw多账户机制解析

### 支持的多账户场景
根据官方文档，OpenClaw确实支持多账户多Agent架构：

```
✅ 支持的模式：
user1 → feishu bot1 (accountId: "account1") → agent1
user2 → feishu bot2 (accountId: "account2") → agent2

✅ Feishu在支持的多账户渠道列表中
✅ accountId是合法的绑定匹配字段
```

### 路由优先级（官方规则）
```
1. peer匹配（精确的DM/群聊ID）
2. parentPeer匹配（线程继承）  
3. guildId + roles（Discord角色路由）
4. guildId（Discord）
5. teamId（Slack）
6. accountId匹配 ← 你的配置在这一级
7. 渠道级匹配（accountId: "*"）
8. 回退到默认agent
```

---

## 🛠️ 具体修复方案

### 问题诊断：为什么accountId是"0"？

**可能原因分析：**

#### 1. **默认账户行为**
OpenClaw可能在单账户配置时自动使用 `"0"` 作为默认accountId

#### 2. **配置迁移问题**  
从单账户配置升级到多账户时，可能存在ID映射问题

#### 3. **飞书插件实现细节**
飞书插件可能有特定的accountId生成逻辑

---

## 🔧 修复方案（按优先级）

### 方案1：配置多个飞书账户（推荐）

**理想配置来支持你的多用户需求：**

```json
{
  "channels": {
    "feishu": {
      "accounts": [
        {
          "accountId": "user1-feishu",
          "appId": "cli_app1_id", 
          "appSecret": "secret1",
          "webhookPath": "/feishu/events/user1"
        },
        {
          "accountId": "user2-feishu",
          "appId": "cli_app2_id",
          "appSecret": "secret2", 
          "webhookPath": "/feishu/events/user2"
        }
      ]
    }
  },
  "bindings": [
    {
      "agentId": "agent1",
      "match": {
        "channel": "feishu",
        "accountId": "user1-feishu"
      }
    },
    {
      "agentId": "agent2", 
      "match": {
        "channel": "feishu",
        "accountId": "user2-feishu"
      }
    }
  ]
}
```

### 方案2：立即修复当前配置

**临时修复 - 匹配实际的accountId：**

```bash
# 1. 备份
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.backup

# 2. 修改binding匹配实际的accountId 
sed -i 's/"accountId": "feishu-loki"/"accountId": "0"/' ~/.openclaw/openclaw.json

# 3. 重启OpenClaw
openclaw gateway restart
```

### 方案3：使用peer级精确路由

**按用户ID路由（最精确）：**

```json
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

## 🎯 多用户架构最佳实践

### 推荐架构设计

**Option A: 一对一映射**
```
User A → Feishu App A → Agent A → Workspace A
User B → Feishu App B → Agent B → Workspace B  
User C → Feishu App C → Agent C → Workspace C
```

**Option B: 用户级路由**
```
User A → Feishu App（共享）→ Agent A（基于user ID路由）
User B → Feishu App（共享）→ Agent B（基于user ID路由）
```

### 配置步骤

**实现多用户支持：**

1. **创建多个飞书应用**（推荐）
   ```bash
   openclaw channels add --channel feishu --account user1 --app-id xxx --app-secret xxx
   openclaw channels add --channel feishu --account user2 --app-id yyy --app-secret yyy
   ```

2. **创建对应的Agent**
   ```bash
   openclaw agents add user1-agent --workspace ~/.openclaw/workspace-user1
   openclaw agents add user2-agent --workspace ~/.openclaw/workspace-user2
   ```

3. **设置精确绑定**
   ```bash
   openclaw agents bind --agent user1-agent --bind feishu:user1
   openclaw agents bind --agent user2-agent --bind feishu:user2
   ```

---

## ⚠️ 当前问题修复

**立即修复建议（方案2）：**
```bash
# 修改配置匹配实际accountId
sed -i 's/"feishu-loki"/"0"/' ~/.openclaw/openclaw.json
openclaw gateway restart
```

**长期架构建议（方案1）：**
为每个用户创建独立的飞书应用和Agent，实现真正的多租户隔离。

---

**你的多用户需求完全可以实现，OpenClaw原生支持这种架构！**