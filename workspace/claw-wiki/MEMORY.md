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

## ClawHub 热门 Skill & 安全通告查询 SOP（重要）

**触发词：** "热门 skill"、"安全通告"、"clawhub 榜单"、"社区 skill"

**正确工具调用顺序（必须按序穷举，不得跳过）：**
1. `exec(clawhub explore, timeout=30)` — 第一优先，CLI 直接拉实时数据，永远可用
2. `web_fetch(https://clawhub.ai/skills)` — 备用，可能因 JS 渲染失败
3. `web_fetch(https://docs.openclaw.ai/security)` — 拉官方安全文档
4. 以上均失败 → 才可以说"暂时无法获取"，并给出手动查看链接

**禁止行为：**
- ❌ web_fetch 失败后直接说"查不了"，不尝试 CLI
- ❌ 没有穷举所有工具就报告无法完成

**群发目标群（feishu-wiki 账号）：**
- MOSS GTM 群：`oc_0b9d0ab99d212ccb1ba606849975aaf5`
- 备用群：`oc_3b6292c9961eaa04c5d9f342fe4ced7e`

**图片分析工具链（当沙箱 read 受限时）：**
1. `exec(python3 /tmp/analyze_final.py)` — 用 kellycloudai API + claude-sonnet-4-6 分析
2. API base URL: `https://www.kellycloudai.com/v1`，可用模型：`gpt-5.4`、`claude-sonnet-4-6-thinking`、`deepseek-v3.2`
3. API Key 环境变量：`KELLYCLOUDAI_API_KEY`
