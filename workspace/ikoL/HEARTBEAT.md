# HEARTBEAT.md

## 检查项

- [ ] 检查 repo-monitor 通知队列
  - 读取 `projects/repo-monitor/pending_notifications.json`
  - 若有待发通知，用 message 工具发送给对应 Feishu 用户
  - 发送成功后清空队列文件（写入空数组 `[]`）
