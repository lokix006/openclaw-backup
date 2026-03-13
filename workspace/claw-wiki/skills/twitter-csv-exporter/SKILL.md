---
name: twitter-csv-exporter-third-party
description: >
  Fetch Twitter/X tweets using a third-party API (apidance.pro) and export to CSV with engagement metrics.
  Use this skill whenever the user wants to collect, search, or gather tweets and export them to a file.
  English triggers: "export tweets from @username", "get tweets with #hashtag", "search tweets about keyword",
  "fetch viral tweets with high likes", "collect tweets by date range", "get tweet replies", "save tweets to CSV",
  "spreadsheet with tweets", "tweets with mentions".
  中文触发词：搜推文、抓推文、导出推文、推文 CSV、推文表格、获取推文、@某人的推文、某话题推文、推文数据、twitter数据。
  This does NOT post, like, retweet, follow, DM, delete, or modify tweets - only fetches and exports.
---

# Twitter/X CSV Exporter Skill

## 执行推文导出

**按顺序执行以下四步：**

**第一步 — 确认参数**：

从用户消息中提取：
- **搜索词**：关键词、`from:用户名`、`#话题` 等（见下方搜索词参考表）
- **输出文件**：`/tmp/openclaw/<搜索词>.csv`（统一放到 `/tmp/openclaw/`，便于后续发送步骤引用）
- **条数限制**：默认 `--limit 50`，用户有特别要求时调整

> API key 已内置，无需用户提供。

**第二步 — 运行 Bun 脚本**：

脚本会自动处理分页、生成带完整抬头（26列）的 CSV、UTF-8 BOM 编码和 ISO 日期格式。直接用 curl 抓取原始 JSON 再手写 CSV 会导致列缺失和没有抬头，所以始终通过脚本导出。

先确保输出目录存在，再运行脚本（将 `<搜索词>` 替换为实际值）：

```
exec(command="set -a && source /root/.openclaw/workspace/claw-wiki/skills/twitter-csv-exporter/.env && set +a && mkdir -p /tmp/openclaw && /root/.bun/bin/bun run /root/.openclaw/workspace/claw-wiki/skills/twitter-csv-exporter/scripts/fetch-tweets.ts --query \"<搜索词>\" --api-key \"$APIDANCE_API_KEY\" --output \"/tmp/openclaw/<搜索词>.csv\" --limit 50")
```

如果返回 401，说明 API key 失效，请联系管理员更新 `.env` 文件。

**第三步 — 发送 CSV 到群聊**（Lark/Feishu 群聊上下文）：

脚本成功后，通过 message 工具发送文件——用户在群里发起的请求期待在群里拿到结果，只回复文字等于没完成任务：

```
message(action=send, channel=feishu, target=<chat_id>, media="/tmp/openclaw/<搜索词>.csv")
```

`chat_id` 从消息上下文 `conversation_label` 字段获取（格式 `oc_xxx`）

**第四步 — 回复确认**：

告知用户文件名和导出行数。

---

## 参数参考

| 参数 | 缩写 | 说明 | 默认值 |
|------|------|------|--------|
| `--query` | `-q` | 搜索词（必填） | - |
| `--api-key` | `-k` | API key（从 .env 自动注入） | - |
| `--output` | `-o` | 输出文件路径 | `/tmp/openclaw/<搜索词>.csv` |
| `--sort` | | `Latest` 或 `Top` | `Latest` |
| `--limit` | `-l` | 最多抓取条数（0=不限） | `0` |
| `--max-pages` | | 最多请求页数（每页约20条） | `10` |
| `--following` | | 检查作者是否关注指定账号（逗号分隔） | - |
| `--include-nested` | | 抓取推文回复时包含嵌套回复 | `false` |

### 搜索词参考

| 用户请求 | 搜索词 |
|----------|--------|
| 关键词推文 | `Claude AI` |
| 用户的推文 | `from:elonmusk` |
| 话题标签 | `#bitcoin` |
| 指定日期后 | `bitcoin since:2024-01-01` |
| 指定日期范围 | `bitcoin since:2024-01-01 until:2024-12-31` |
| 热门推文 | `bitcoin min_faves:100` |
| 带图片 | `bitcoin filter:images` |
| 中文内容 | 直接用中文关键词，不加 `lang:` |

---

## API 参考（仅供调试）

**Base URL**: `https://api.apidance.pro`

**Authentication**: 所有请求须包含 `apikey` header（冒号后无空格：`apikey:KEY`）

| 操作 | 端点 |
|------|------|
| 搜索推文 | `GET /sapi/Search?q=<query>&sort_by=Latest\|Top&cursor=<cursor>` |
| 推文详情（含回复） | `GET /sapi/TweetDetail?tweet_id=<id>&cursor=<cursor>` |
| 关注关系 | `GET /1.1/friendships/show.json?source_id=<id>&target_screen_name=<handle>` |

关注关系：返回值中 `relationship.source.following` 为 `true` 表示正在关注。

---

## Notes

- 使用第三方 API（apidance.pro），非 Twitter 官方 API
- API key 存储在 `.env` 文件中，自动注入，无需用户输入
- API 按次计费，建议加 `--limit 50` 控制用量
- 部分字段可能为 null（取决于推文类型）
