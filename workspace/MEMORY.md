记忆（长期）:
- 已记录的偏好与约束将作为长期记忆保留，便于跨会话复用

## Agent 当前状态（2026-03-10）

### main
- 系统管理员，仅服务 Loki，通过 Telegram 交互

### ikol (ikoL)
- feishu-loki account，Loki 的飞书个人助理
- deny: gateway, exec
- fs.workspaceOnly: /workspace/ikoL/
- SOUL.md 有群聊安全守则 + 禁止自改配置文件规则

### claw-wiki (GTM Agent)
- feishu-wiki account (cli_a92577172bb85ed2，已于今日换绑新 bot)
- deny: gateway, exec, nodes, sessions_spawn/send/history/list, subagents
- fs.workspaceOnly: /workspace/claw-wiki/
- groupAllowFrom: oc_0b9d0ab99d212ccb1ba606849975aaf5, oc_3b6292c9961eaa04c5d9f342fe4ced7e
- SOUL.md 有禁止自改配置文件规则
- tweet-report skill 在 /workspace/claw-wiki/skills/tweet-report/

## 当前 Cron Jobs

| ID | 名称 | Agent | 频率 | 目标 |
|----|------|-------|------|------|
| 6dc015c5 | Daily System Inspection | main | 每天 02:00 LA | feishu ou_570aeb8842a1cbbc0313861d2b5c128f |
| 55bee3f1 | Agent Security Audit | main | 每 30 分钟 | Telegram 告警给 Loki |
| 85aeeb8d | OpenClaw Daily Brief (Group) | ikol | 每 8 小时 | feishu chat oc_97666fe6bdc0ff8c62f55ddd27670575 |
| 31ca3fe4 | OpenClaw Daily Brief (GTM Agent) | claw-wiki | 每 8 小时 | feishu chat oc_3b6292c9961eaa04c5d9f342fe4ced7e |
| 2f9aa65b | Repo Monitor | main | 每 5 分钟 | 检测仓库更新，发 feishu 通知 |

## 重要路径

- healthcheck.sh: /root/.openclaw/workspace/scripts/healthcheck.sh
- repo-monitor: /root/.openclaw/workspace/ikoL/projects/repo-monitor/
  - repos.csv: 监控列表，notify_user_ids 用分号分隔多人
  - 已测试：commit 触发后飞书通知正常发送
- tweet-report skill: /root/.openclaw/workspace/claw-wiki/skills/tweet-report/
- audit-state.json: /root/.openclaw/workspace/audit-state.json

## 待办 / 未完成

- repo-monitor 转化为 ikol 专属 skill（已讨论方案：读=直接，写/触发=cron委托main）
- feishu-wiki bitable 权限待开通（bitable:app scope 未授权）

## Loki 偏好

- 直接给结论和操作，不需要铺垫
- 给选项时偏向得到推荐
- 安全和权限有意识，会主动问边界
- 确认方向后让 agent 执行，不喜欢被反复确认打断
