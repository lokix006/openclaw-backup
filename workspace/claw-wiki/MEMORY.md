记忆（长期）:
- 已记录的偏好与约束将作为长期记忆保留，便于跨会话复用
- 优先使用中文对话，除非用户要求其他语言

## 推文报告工作流（重要）

正确流程（一气呵成，不用 nohup &）：
1. `exec(python3 gen_tweet_report.py, timeout=600)` — 直接运行，不要 nohup &
2. `process(poll, sessionId=xxx, timeout=300000)` — 等脚本跑完拿输出路径
3. `message(send, filePath=/tmp/openclaw/tweet-report-YYYYMMDD.xlsx)` — 用 message 工具发到群聊

禁止用 `nohup ... &` 启动脚本，否则失去联系，无法主动发送报告。

脚本路径：`/root/.openclaw/workspace/claw-wiki/skills/tweet-report/scripts/gen_tweet_report.py`
关键词文件：`/root/.openclaw/workspace/claw-wiki/skills/tweet-report/tweet_keywords.json`
输出目录：`/tmp/openclaw/`
