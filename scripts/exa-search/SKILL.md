---
name: exa-search
description: >
  OpenClaw 技术简报生成 skill（Exa + OpenRouter）。
  使用“bucket 搜索 → 规则过滤 → 主题聚类 → 精简上下文 → LLM 成文”的链路，
  在保证数据质量的同时控制 LLM 输入体积。
---

# Exa Search Skill

## 当前正式链路

该 skill 的正式实现已切换为 **TypeScript pipeline**：

1. **Exa 搜索**
2. **程序化 bucket 分层**（GitHub / docs / community）
3. **程序化 filter**（去重、降噪、低信号剔除）
4. **程序化 cluster**（主题聚合）
5. **程序化压缩为 final context**
6. **LLM 只负责最后中文成文**

这个设计的目标是：
- 先把“数据质量”收敛，再做成文
- 让 LLM 只吃精简上下文，避免把大量原始搜索结果直接塞给模型
- 保持最终输出适合 Feishu / Telegram 投递

## 目录结构

```text
exa-search/
├── SKILL.md
├── .env
├── package.json
├── prompts/
│   ├── _TEMPLATE.md
│   ├── openclaw-general.md
│   └── openclaw-tech.md
├── scripts/
│   ├── run_pipeline.ts      # 正式版：当前推荐使用
│   └── search.py            # 旧版实验脚本，保留参考
└── out/
    └── latest/
        ├── 01-raw.json
        ├── 02-filtered.json
        ├── 03-clustered.json
        ├── 04-context-v3.json
        ├── 04-context-v3.txt
        ├── 05-final-report.json
        ├── 05-final-report.md
        └── README.md
```

## 依赖

在 skill 目录执行：

```bash
cd /root/.openclaw/workspace/ikoL/skills/exa-search
npm install --legacy-peer-deps
```

依赖包括：
- `@exalabs/ai-sdk`
- `@openrouter/ai-sdk-provider`
- `ai`
- `tsx`
- `zod`

## 凭证来源

### 必需
- `EXA_API_KEY`
  - 来源：`/root/.openclaw/workspace/ikoL/skills/exa-search/.env`

### 自动读取
- `OPENROUTER_API_KEY`
  - 优先读环境变量
  - 若不存在，则自动从：
    - `/root/.openclaw/agents/main/agent/auth-profiles.json`
    - 中的 `openrouter:default` 读取

## 运行方式

### 1) 正式生成最终简报

```bash
cd /root/.openclaw/workspace/ikoL/skills/exa-search
npx tsx scripts/run_pipeline.ts
```

默认输出最终 markdown 文件路径，例如：

```text
/root/.openclaw/workspace/ikoL/skills/exa-search/out/latest/05-final-report.md
```

### 2) 调试模式

```bash
cd /root/.openclaw/workspace/ikoL/skills/exa-search
npx tsx scripts/run_pipeline.ts --debug
```

### 3) 指定 profile / 回溯时间 / 条目数 / 输出目录

```bash
cd /root/.openclaw/workspace/ikoL/skills/exa-search
npx tsx scripts/run_pipeline.ts --profile tech --hours-back 48 --max-items 10 --out-dir ./out/latest
```

### 4) 社区热度版（非技术）

```bash
cd /root/.openclaw/workspace/ikoL/skills/exa-search
npx tsx scripts/run_pipeline.ts --profile social --hours-back 48 --max-items 10 --out-dir ./out/social-latest
```

## Profile 说明

### `--profile tech`
- 面向技术动态
- 主源：GitHub / docs / X / V2EX
- 重点：PR / issue / regression / API / performance / architecture
- 输出标题：`📡 OpenClaw 技术简报`

### `--profile social`
- 面向社区热度 / 非技术动态
- 主源：X / Twitter / Weibo / V2EX / 掘金 / 少数派 / 36kr 等中文社区与媒体
- 重点：项目发布、社区讨论、用户反馈、生态扩展、市场 buzz
- 输出标题：`🌐 OpenClaw 社区热度简报`

## 产物说明

### `01-raw.json`
原始 bucket 搜索结果（按 query 分组）

### `02-filtered.json`
去重和规则过滤后的候选集合

### `03-clustered.json`
主题聚类后的结果

### `04-context-v3.txt`
喂给 LLM 的最小上下文（推荐重点查看）

### `05-final-report.md`
最终简报，适合直接投递

## 当前推荐

- **生产使用**：`scripts/run_pipeline.ts`
- **旧版 search.py**：仅保留参考，不再作为主链路
- **后续接 cron**：cron 只负责执行本脚本并发送 `05-final-report.md`，不要再让 cron 内部模型临场组织整条链
