---
name: exa-query
description: >
  轻量级 Exa 即时搜索 skill。用户用自然语言描述想搜什么，直接调 Exa Search API，LLM 总结结果并回复。
  适合即时查询，不做 pipeline 处理，不输出文件。
  触发词：帮我搜、搜一下、查一下、Exa 搜、用 Exa 搜、搜索、找一下最新的、有没有关于。
  中文触发词：帮我搜、查一下、搜一下、找最新、Exa查、即时搜索。
  不适合用于：定时简报、大批量抓取、需要 CSV 导出的场景（那些用 exa-search 或 twitter-csv-exporter）。
---

# Exa Query Skill

## 定位

**即时对话式搜索**，用于用户临时发起的一次性查询。

- ✅ 用户随口问"帮我搜一下 xxx 最新动态"
- ✅ 临时验证某个话题有没有近期内容
- ✅ 快速获取某关键词的搜索摘要
- ❌ 不是日报生成（用 exa-search）
- ❌ 不是大批量推文抓取（用 twitter-csv-exporter）

---

## 执行步骤

**第一步 — 从用户消息提取参数**

从自然语言中解析：

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `query` | 搜索关键词或语义描述 | 必须有 |
| `num_results` | 返回条数 | 5 |
| `hours_back` | 时间范围（小时），0 表示不限 | 0 |
| `type` | `auto`、`keyword`、`neural`、`fast` | `auto` |

示例：
- "帮我搜 OpenClaw 最近的技术动态" → `query="OpenClaw technical updates"`, `hours_back=72`
- "找一下 Claude 3.5 发布的消息" → `query="Claude 3.5 release"`, `type="neural"`
- "最近一周关于 AI agent 的热门内容" → `query="AI agent"`, `hours_back=168`

**第二步 — 运行搜索脚本**

```
exec(command="set -a && source /root/.openclaw/workspace/ikoL/skills/exa-query/.env && set +a && npx tsx /root/.openclaw/workspace/ikoL/skills/exa-query/scripts/query.ts --query \"<query>\" --num-results <num_results> --hours-back <hours_back> --type <type>", timeout=60)
```

脚本直接把搜索结果以 JSON 打到 stdout。

**第三步 — LLM 直接总结回复**

读取脚本输出，基于结果用中文直接回复用户。

### 默认输出格式

如果用户没有指定格式，使用以下默认模板：

```
📡 [主题] 简报 | YYYY-MM-DD

**1. [条目标题]**
- 📅 YYYY-MM-DD
- 📝 [一句话中文摘要]
- 🔗 [来源 URL]

---

**2. ...**

📌 **总结：** [2-3句整体概括，点出关键趋势或值得关注的点]
```

要求：
- 标题使用加粗，每条用 `---` 分隔
- 摘要为一句话，不重复标题内容
- 按日期降序排列（最新在前）
- 末尾附 📌 总结段落

### 用户可覆盖默认格式

如果用户在请求中明确指定了格式要求（如"用表格"、"简洁点"、"给我 JSON"、"不要分隔线"等），**优先遵循用户指定的格式**，忽略默认模板。

如果结果为空，如实告知用户没有找到相关内容。

**不需要写文件，不需要发 Feishu 消息，直接在对话中回复即可。**

---

## 凭证

- `EXA_API_KEY`：读自 `/root/.openclaw/workspace/ikoL/skills/exa-query/.env`
