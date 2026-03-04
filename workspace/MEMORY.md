记忆（长期）:
- 后续所有信息查询/获取信息默认使用 AWS CLI profile：test-readonly，区域 ap-southeast-1
- 以只读查询为主，写入/修改操作需再次确认
- 已记录的偏好与约束将作为长期记忆保留，便于跨会话复用

当前会话记忆（短期）:
- 已确认的查询偏好：默认使用 test-readonly profile 查询 AWS EC2 等资源信息；区域为 ap-southeast-1；写操作需确认
- 如需更改偏好，请明确提出新的 profile/区域或查询约束。

如有需要，我也可以定期将重要发现写入 MEMORY.md 以供回顾。