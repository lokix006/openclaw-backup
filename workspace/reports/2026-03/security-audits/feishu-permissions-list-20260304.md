# 飞书AI助手完整权限清单（编号版本）

**生成时间：** 2026-03-04  
**权限总数：** 144个已授权权限

---

## 📋 完整权限列表（按功能分组编号）

### 文档系统权限 (docs) - 24项
1. docs:doc                                    # 文档完全访问权限
2. docs:doc:readonly                           # 文档只读访问
3. docs:document:copy                          # 复制文档
4. docs:document:import                        # 导入文档
5. docs:document.comment:create                # 创建文档评论
6. docs:document.comment:read                  # 读取文档评论
7. docs:document.comment:write_only            # 仅写入文档评论
8. docs:document.content:read                  # 读取文档内容
9. docs:document.media:download                # 下载文档媒体文件
10. docs:document.media:upload                 # 上传文档媒体文件
11. docs:document.subscription                 # 文档订阅
12. docs:document.subscription:read            # 读取文档订阅信息
13. docs:event:subscribe                       # 订阅文档事件
14. docs:permission.member                     # 管理文档成员权限
15. docs:permission.member:auth                # 文档成员授权
16. docs:permission.member:create              # 创建文档成员权限
17. docs:permission.member:delete              # 删除文档成员权限
18. docs:permission.member:readonly            # 只读文档成员权限
19. docs:permission.member:retrieve            # 获取文档成员信息
20. docs:permission.member:transfer            # 转移文档成员权限
21. docs:permission.member:update              # 更新文档成员权限
22. docs:permission.setting                   # 文档权限设置
23. docs:permission.setting:read              # 读取文档权限设置
24. docs:permission.setting:write_only        # 仅写入文档权限设置

### 知识库权限 (wiki) - 10项
25. wiki:node:copy                             # 复制知识库节点
26. wiki:node:create                           # 创建知识库节点
27. wiki:node:move                             # 移动知识库节点
28. wiki:node:read                             # 读取知识库节点
29. wiki:node:retrieve                         # 检索知识库节点
30. wiki:node:update                           # 更新知识库节点
31. wiki:space:read                            # 读取知识空间
32. wiki:space:retrieve                        # 检索知识空间
33. wiki:wiki                                  # 知识库完全访问
34. wiki:wiki:readonly                         # 知识库只读访问

### docx文档权限 - 5项
35. docx:document                              # docx文档完全访问
36. docx:document:create                       # 创建docx文档
37. docx:document:readonly                     # docx文档只读
38. docx:document:write_only                   # 仅写入docx文档
39. docx:document.block:convert                # docx文档块转换

### 多维表格权限 (bitable) - 2项
40. bitable:app                                # 多维表格完全访问
41. bitable:app:readonly                       # 多维表格只读访问

### 电子表格权限 - 1项
42. sheets:spreadsheet                         # 电子表格访问

### 云盘权限 (drive) - 11项
43. drive:drive                                # 云盘完全访问
44. drive:drive:readonly                       # 云盘只读访问
45. drive:drive:version                        # 云盘版本管理
46. drive:drive:version:readonly               # 云盘版本只读
47. drive:drive.metadata:readonly              # 云盘元数据只读
48. drive:drive.search:readonly                # 云盘搜索只读
49. drive:export:readonly                      # 云盘导出只读
50. drive:file                                 # 文件访问
51. drive:file:download                        # 文件下载
52. drive:file:readonly                        # 文件只读
53. drive:file:view_record:readonly            # 文件查看记录只读
54. drive:file.meta.sec_label.read_only        # 文件安全标签只读

### 工作空间权限 (space) - 4项
55. space:document:move                        # 移动空间文档
56. space:document:retrieve                    # 检索空间文档
57. space:document:shortcut                    # 空间文档快捷方式
58. space:document.event:read                  # 读取空间文档事件

### 即时消息权限 (im) - 30项
59. im:chat:operate_as_owner                   # 以群主身份操作群聊
60. im:chat:read                               # 读取群聊信息
61. im:chat:readonly                           # 群聊只读访问
62. im:chat:update                             # 更新群聊设置
63. im:chat.announcement:read                  # 读取群公告
64. im:chat.announcement:write_only            # 仅写入群公告
65. im:chat.chat_pins:read                     # 读取群置顶消息
66. im:chat.members:bot_access                 # Bot访问群成员
67. im:chat.members:read                       # 读取群成员
68. im:chat.members:write_only                 # 仅写入群成员
69. im:chat.menu_tree:read                     # 读取群菜单树
70. im:chat.menu_tree:write_only               # 仅写入群菜单树
71. im:chat.moderation:read                    # 读取群审核信息
72. im:chat.tabs:read                          # 读取群标签页
73. im:chat.tabs:write_only                    # 仅写入群标签页
74. im:chat.top_notice:write_only              # 仅写入群顶部通知
75. im:chat.widgets:read                       # 读取群组件
76. im:chat.widgets:write_only                 # 仅写入群组件
77. im:datasync.feed_card.time_sensitive:write # 写入时间敏感信息流卡片
78. im:message                                 # 消息完全访问
79. im:message:readonly                        # 消息只读访问
80. im:message:recall                          # 撤回消息
81. im:message:send_as_bot                     # 以Bot身份发送消息
82. im:message:send_multi_depts                # 向多部门发送消息
83. im:message:send_multi_users                # 向多用户发送消息
84. im:message:send_sys_msg                    # 发送系统消息
85. im:message:update                          # 更新消息
86. im:message.group_at_msg:readonly           # 只读群@消息
87. im:message.group_msg                       # 群消息访问
88. im:message.group_msg:readonly              # 群消息只读
89. im:message.p2p_msg:readonly                # 私聊消息只读
90. im:message.pins:read                       # 读取置顶消息
91. im:message.pins:write_only                 # 仅写入置顶消息
92. im:message.reactions:read                  # 读取消息反应
93. im:message.reactions:write_only            # 仅写入消息反应
94. im:message.urgent                          # 紧急消息
95. im:message.urgent:phone                    # 紧急电话通知
96. im:message.urgent:sms                      # 紧急短信通知
97. im:resource                                # 即时消息资源
98. im:url_preview.update                      # 更新URL预览
99. im:user_agent:read                         # 读取用户代理信息

### 通讯录权限 (contact) - 16项
100. contact:contact.base:readonly             # 通讯录基础信息只读
101. contact:department.base:readonly          # 部门基础信息只读
102. contact:department.organize:readonly      # 组织架构只读
103. contact:functional_role:readonly          # 职能角色只读
104. contact:job_title:readonly                # 职位头衔只读
105. contact:role:readonly                     # 角色信息只读
106. contact:user.assign_info:read             # 用户分配信息读取
107. contact:user.base:readonly                # 用户基础信息只读
108. contact:user.department:readonly          # 用户部门信息只读
109. contact:user.dotted_line_leader_info.read # 用户虚线汇报关系读取
110. contact:user.email:readonly               # 用户邮箱只读
111. contact:user.employee:readonly            # 员工信息只读
112. contact:user.employee_id:readonly         # 员工ID只读
113. contact:user.gender:readonly              # 用户性别只读
114. contact:user.id:readonly                  # 用户ID只读
115. contact:user.user_geo                     # 用户地理位置信息

### 邮箱权限 (mail) - 4项
116. mail:user_mailbox.mail_contact:read       # 读取邮箱联系人
117. mail:user_mailbox.mail_contact:write      # 写入邮箱联系人
118. mail:user_mailbox.mail_contact.mail_address:read # 读取邮箱地址
119. mail:user_mailbox.mail_contact.phone:read # 读取邮箱联系人电话

### AI文档处理权限 (document_ai) - 3项
120. document_ai:business_card:recognize       # 名片识别
121. document_ai:document:chunking             # 文档分块处理
122. document_ai:invoice:recognize             # 发票识别

### 其他权限 - 2项
123. directory:employee.base.email:read       # 员工目录邮箱读取
124. event:ip_list                            # IP列表访问

---

## 🎯 给同事的建议配置

**如果只需要查看技术文档**，建议配置这6个基础权限：
1. docs:doc:readonly
2. docs:document.content:read  
3. wiki:node:read
4. wiki:wiki:readonly
5. docx:document:readonly
6. bitable:app:readonly

这样你同事就能和我一样正常查看公司的技术文档了！