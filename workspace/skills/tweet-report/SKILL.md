---
name: tweet-report
description: >
  Tweet report skill for Lark/Feishu groups: fetches tweet data for tracked keywords,
  generates a dual-sheet Excel file (tweet list + KOL analysis), and sends it to the
  Lark group chat. Also handles keyword list management (add / remove / view).
  ALWAYS use this skill when the user mentions: 推文, tweet报告, KOL分析, openclaw推文,
  clawbot, 热门推文, 推文表格, 添加关键词, 删除关键词, 查看关键词, tweet excel, 推文数据.
  Use it even if the user says something casual like "给我拉一下推文" or "推文列表有哪些关键词".
---

# Tweet Report Skill

---

## 生成推文报告（最重要，先看这里）

**严格按顺序执行以下三步，每一步必须完成后再进入下一步：**

**第一步 — 启动脚本并立即回复用户**：

先用 `exec` 启动脚本：
```
exec(command="python3 $HOME/.openclaw/workspace/skills/tweet-report/scripts/gen_tweet_report.py")
```
脚本可能需要几分钟（API 数据同步），平台会自动后台化。

**不管脚本是否已返回，必须立即用 `message` 回复用户**：
```
message(action=send, channel=feishu, target=<chat_id>, message="好的，已开始获取推文数据，数据就绪后自动发送到群聊 📊")
```

**第二步 — 等脚本跑完**：

用 `process` 轮询，直到脚本退出：
```
process(action=poll, sessionId=<第一步返回的sessionId>)
```

如果脚本输出包含 `❌` 或退出码非 0，说明失败，回复用户"数据获取失败，请稍后重试"后停止。

**第三步 — 发送 Excel**：

脚本成功后，用 `message` 发送文件（`chat_id` 从消息上下文 `peer` 字段获取，格式 `oc_xxx`）：
```
message(action=send, channel=feishu, target=<chat_id>, media="/tmp/openclaw/tweet-report-YYYYMMDD.xlsx")
```
其中 `YYYYMMDD` 用当天日期替换。

**然后停止，不要再做任何操作。**

---

## ⚠️ 严禁行为

- 禁止自己写 Python 脚本（不管是写到 `/tmp` 还是其他地方）
- 禁止用 `web_fetch` 或 `requests` 直接调 API
- 禁止在生成报告时修改关键词
- 禁止向用户解释技术细节（如 API 状态、超时原因）

---

## 关键字管理

关键字存储在 skill 目录内：`$HOME/.openclaw/workspace/skills/tweet-report/tweet_keywords.json`。

**添加 / 删除关键字**（用 bash 原子写回，写后打印确认）：

```bash
KW_FILE="$HOME/.openclaw/workspace/skills/tweet-report/tweet_keywords.json"

# 添加
python3 -c "
import json; f='$KW_FILE'
kws=json.load(open(f)); kws.append('新关键字')
json.dump(kws,open(f,'w'),ensure_ascii=False); print(json.load(open(f)))
"

# 删除
python3 -c "
import json; f='$KW_FILE'
kws=[k for k in json.load(open(f)) if k!='要删除的关键字']
json.dump(kws,open(f,'w'),ensure_ascii=False); print(json.load(open(f)))
"
```

用打印出来的列表告知用户，不要自己猜。
