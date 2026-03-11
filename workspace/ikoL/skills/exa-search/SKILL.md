---
name: exa-search
description: >
  Exa API 多主题批量搜索 skill。加载 prompts/ 目录下所有 .md 文件，
  执行搜索并输出聚合结果。支持紧凑文本输出与 Feishu-friendly markdown 直出。
---

# Exa Search Skill

## 目录结构

```
exa-search/
├── SKILL.md
├── .env
├── scripts/
│   └── search.py
└── prompts/
    ├── _TEMPLATE.md
    ├── openclaw-general.md
    └── openclaw-tech.md
```

## Prompt 文件头字段

```markdown
# prompt_id: openclaw-general
# label: OpenClaw 热点资讯
# queries: q1 | q2 | q3
# domains: twitter.com,x.com,github.com
# type: neural
# num_results: 10
# hours_back: 48
# max_characters: 1200
# max_items: 10
```

说明：
- `queries`: 最多 3 个
- `hours_back`: 精确滚动窗口，优先于 `days_back`
- `max_items`: 每个 prompt 最终输出的条数上限（去重和排序后截断）

## 调用方式

### 1) 调试原始结果（title/url/date）
```bash
/root/exa-test/bin/python3 /root/.openclaw/workspace/ikoL/skills/exa-search/scripts/search.py --compact
```

### 2) 直接输出飞书可发送 markdown
```bash
/root/exa-test/bin/python3 /root/.openclaw/workspace/ikoL/skills/exa-search/scripts/search.py --markdown
```

## 设计建议

生产环境 cron job 推荐直接使用 `--markdown`，避免二次 LLM 整理造成超时或 failover 问题。
