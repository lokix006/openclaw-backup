# 飞书权限安全审计报告

**审计时间：** 2026-03-04  
**权限总数：** 155个已授权权限  
**风险级别：** 中高风险（需要关注）

## 🔴 高风险敏感权限

### 1. 即时消息系统权限
```
im:message                    # 发送/接收消息（完全访问）
im:message:send_as_bot       # 以Bot身份发送消息
im:message:send_multi_users  # 群发消息给多用户
im:message:send_multi_depts  # 跨部门群发消息
im:message:send_sys_msg      # 发送系统消息
im:message:update            # 修改已发送消息
im:message:recall            # 撤回消息
im:message.urgent            # 发送紧急消息
im:message.urgent:phone      # 紧急电话通知
im:message.urgent:sms        # 紧急短信通知
```

**风险分析：** 能够以Bot身份在飞书内发送任意消息，包括紧急通知和系统消息。可能被滥用进行垃圾消息推送或冒充。

### 2. 通讯录和员工信息权限
```
contact:user.email:readonly         # 读取员工邮箱
contact:user.phone:readonly         # 读取员工电话
contact:user.base:readonly          # 读取员工基础信息
contact:user.employee:readonly      # 读取员工详细信息
contact:user.employee_id:readonly   # 读取员工ID
contact:user.gender:readonly        # 读取员工性别
contact:user.user_geo              # 员工地理位置信息
contact:user.assign_info:read      # 员工分配信息
contact:user.dotted_line_leader_info.read # 虚线汇报关系
contact:department.organize:readonly # 组织架构信息
contact:department.base:readonly     # 部门基础信息
contact:contact                      # 通讯录完全访问
contact:contact:update_department_id # 修改部门归属
contact:contact:update_user_id       # 修改用户ID
directory:employee.base.email:read  # 员工目录邮箱读取
```

**风险分析：** 几乎可以访问公司所有员工的个人信息，包括联系方式、组织关系、地理位置等敏感数据。

### 3. 群聊管理权限
```
im:chat:operate_as_owner       # 以群主身份操作群聊
im:chat:update                 # 修改群设置
im:chat.members:write_only     # 添加/移除群成员
im:chat.members:bot_access     # Bot访问群成员
im:chat.announcement:write_only # 修改群公告
im:chat.top_notice:write_only  # 置顶群通知
im:chat.widgets:write_only     # 修改群组件
im:chat.menu_tree:write_only   # 修改群菜单
im:chat.tabs:write_only        # 修改群标签页
```

**风险分析：** 对群聊有近乎群主级别的管理权限，可以修改群设置、管理成员、发布公告等。

### 4. 文档和数据权限
```
docs:doc                           # 文档完全访问
docs:permission.member            # 管理文档协作者
docs:permission.member:create     # 添加协作者
docs:permission.member:update     # 修改协作者权限
docs:permission.member:delete     # 删除协作者
docs:permission.member:transfer   # 转移文档所有权
docs:permission.setting          # 修改文档权限设置
docs:permission.setting:write_only # 写入权限设置
space:document:delete             # 删除文档
space:document:move               # 移动文档
bitable:app                       # 多维表格完全访问
```

**风险分析：** 对文档系统有完全访问权限，可以读取、修改、删除任何可访问的文档，并能管理文档的协作权限。

### 5. 邮箱系统权限
```
mail:user_mailbox.mail_contact:read      # 读取邮箱联系人
mail:user_mailbox.mail_contact:write     # 修改邮箱联系人
mail:user_mailbox.mail_contact.phone:read # 读取邮箱联系人电话
mail:user_mailbox.mail_contact.mail_address:read # 读取邮箱地址
```

**风险分析：** 可以访问和修改用户的邮箱联系人信息。

## 🟡 中风险权限

### 数据处理和AI权限
```
document_ai:document:chunking      # 文档AI分块处理
document_ai:invoice:recognize      # 发票识别
document_ai:business_card:recognize # 名片识别
document_ai:jp_driving_license     # 日本驾照识别
```

### 系统配置权限
```
application:application.contacts_range:write # 修改应用联系人范围
contact:user.subscription_ids:write         # 修改用户订阅ID
event:ip_list                               # 访问IP列表
```

## ✅ 合理的文档读写权限

以下权限对于文档操作是必要和合理的：

### 文档基础操作
```
docs:document.content:read     # 读取文档内容 ✅
docx:document:readonly         # 只读docx文档 ✅
docx:document:write_only       # 写入docx文档 ✅
docx:document:create           # 创建新文档 ✅
docs:document:copy             # 复制文档 ✅
docs:document:export           # 导出文档 ✅
docs:document.media:upload     # 上传媒体文件 ✅
docs:document.media:download   # 下载媒体文件 ✅
```

### 知识库操作
```
wiki:wiki:readonly             # 只读知识库 ✅
wiki:node:read                 # 读取wiki节点 ✅
wiki:node:create               # 创建wiki页面 ✅ 
wiki:node:update               # 更新wiki页面 ✅
wiki:node:retrieve             # 检索wiki信息 ✅
wiki:space:read                # 读取知识空间 ✅
```

### 云盘操作
```
drive:drive:readonly           # 只读云盘访问 ✅
drive:file:readonly            # 只读文件访问 ✅
drive:file:download            # 下载文件 ✅
drive:drive.metadata:readonly  # 读取文件元数据 ✅
```

## ⚠️ 安全建议

### 1. 立即关注的敏感权限
建议审查或限制以下权限：
- `im:message.urgent:phone/sms` - 紧急通知权限应该被严格控制
- `contact:user.user_geo` - 员工地理位置信息不应该被AI访问
- `im:chat:operate_as_owner` - 群主级权限过于宽泛
- `docs:permission.member:transfer` - 文档所有权转移权限

### 2. 权限最小化原则
```yaml
# 建议的权限配置（最小必要原则）
essential_permissions:
  - docs:doc:readonly          # 只读文档
  - wiki:node:read            # 只读知识库
  - bitable:app:readonly      # 只读多维表格
  - contact:user.base:readonly # 基础员工信息（仅姓名/部门）
  
optional_permissions:
  - docs:document.comment:create # 评论权限（如需互动）
  - wiki:node:create           # 创建知识页面（如需记录）
```

### 3. 监控和审计机制
建议实施：
- 权限使用日志记录
- 敏感操作需要人工确认
- 定期权限审计和清理
- 异常使用行为告警

## 🎯 总结

**当前权限状态：偏向过度授权**

虽然文档读写权限是合理的，但同时拥有了大量敏感的通讯录、消息发送、群聊管理权限。建议：

1. **保留必要的文档操作权限**
2. **收回不必要的敏感权限**（员工隐私信息、紧急通知、群主权限等）
3. **建立权限使用监控机制**
4. **定期进行权限审计和调整**

**核心原则：** 权限最小化 + 操作可审计 + 异常可告警