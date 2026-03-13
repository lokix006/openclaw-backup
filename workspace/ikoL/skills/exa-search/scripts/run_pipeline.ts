#!/usr/bin/env -S npx tsx
import fs from 'node:fs';
import path from 'node:path';
import { URL } from 'node:url';
import { generateText } from 'ai';
import { createOpenRouter } from '@openrouter/ai-sdk-provider';

const exaMod: any = await import('@exalabs/ai-sdk');
const webSearch = exaMod.webSearch;

type SearchResult = {
  bucket: string;
  bucketTitle: string;
  query: string;
  title: string;
  url: string;
  publishedDate: string;
  highlights: string[];
  summary: string;
  textPreview: string;
  keep?: boolean;
  score?: number;
  reasons?: string[];
  evidence?: string;
  themeKey?: string;
  themeLabel?: string;
  themeHits?: number;
};

type Cluster = {
  themeKey: string;
  themeLabel: string;
  clusterPriority: number;
  itemCount: number;
  representative: SearchResult;
  members: SearchResult[];
};

type ProfileConfig = {
  id: 'tech' | 'social';
  title: string;
  targetItems: number;
  buckets: any[];
  positive: string[];
  negative: string[];
  communityMust: string[];
  docPathAllow: string[];
  themeRules: { key: string; label: string; kws: string[] }[];
  themeOrder: Record<string, number>;
  systemPrompt: string[];
};

const argv = process.argv.slice(2);
const DEBUG = argv.includes('--debug');
const PROFILE_ID = (readFlag('--profile', 'tech') as 'tech' | 'social');
const HOURS_BACK = Number(readFlag('--hours-back', '48'));
const TARGET_ITEMS_FLAG = readFlag('--max-items', '');
const startPublishedDate = new Date(Date.now() - HOURS_BACK * 3600 * 1000).toISOString();

const SCRIPT_DIR = path.dirname(new URL(import.meta.url).pathname);
const SKILL_DIR = path.resolve(SCRIPT_DIR, '..');
const DEFAULT_OUT_DIR = path.join(SKILL_DIR, 'out', PROFILE_ID === 'tech' ? 'latest' : `${PROFILE_ID}-latest`);
const OUT_DIR = readFlag('--out-dir', DEFAULT_OUT_DIR);

fs.mkdirSync(OUT_DIR, { recursive: true });
loadEnv(path.join(SKILL_DIR, '.env'));

function readFlag(name: string, fallback: string) {
  const i = argv.indexOf(name);
  if (i >= 0 && argv[i + 1]) return argv[i + 1];
  return fallback;
}

function loadEnv(file: string) {
  if (!fs.existsSync(file)) return;
  const lines = fs.readFileSync(file, 'utf8').split(/\r?\n/);
  for (const line of lines) {
    const s = line.trim();
    if (!s || s.startsWith('#') || !s.includes('=')) continue;
    const idx = s.indexOf('=');
    const k = s.slice(0, idx).trim();
    const v = s.slice(idx + 1).trim();
    if (!(k in process.env)) process.env[k] = v;
  }
}

function loadOpenRouterKey(): string {
  if (process.env.OPENROUTER_API_KEY) return process.env.OPENROUTER_API_KEY;
  const p = '/root/.openclaw/agents/main/agent/auth-profiles.json';
  if (!fs.existsSync(p)) return '';
  const obj = JSON.parse(fs.readFileSync(p, 'utf8'));
  return obj?.profiles?.['openrouter:default']?.key || '';
}

function requireEnv(name: string): string {
  const v = process.env[name] || '';
  if (!v) throw new Error(`Missing env: ${name}`);
  return v;
}

function lc(s: unknown) {
  return String(s || '').toLowerCase();
}

function clip(s: string, n = 240) {
  const t = String(s || '').replace(/\s+/g, ' ').trim();
  return t.length <= n ? t : t.slice(0, n - 1) + '…';
}

function safePath(urlStr: string) {
  try {
    return new URL(urlStr).pathname.toLowerCase();
  } catch {
    return '';
  }
}

function compactEvidence(item: SearchResult) {
  const parts = [item.title, item.summary, ...(item.highlights || []), item.textPreview].filter(Boolean);
  return clip(parts.join(' | '), 280);
}

const TECH_PROFILE: ProfileConfig = {
  id: 'tech',
  title: '📡 **OpenClaw 技术简报**',
  targetItems: 10,
  buckets: [
    {
      key: 'github',
      title: 'GitHub bucket',
      config: {
        apiKey: requireEnv('EXA_API_KEY'),
        type: 'fast',
        numResults: 8,
        includeDomains: ['github.com'],
        contents: {
          highlights: { numSentences: 3, highlightsPerUrl: 3 },
          text: { maxCharacters: 1000, includeHtmlTags: false },
          summary: { query: 'technical update, issue, pull request, release, bug fix, performance optimization' },
        },
        startPublishedDate,
        includeText: ['OpenClaw'],
      },
      queries: [
        'site:github.com/openclaw/openclaw OpenClaw pull request OR PR',
        'site:github.com/openclaw/openclaw OpenClaw issue OR bug OR regression',
        'site:github.com/openclaw/openclaw OpenClaw release OR changelog OR performance',
      ],
    },
    {
      key: 'docs',
      title: 'Docs bucket',
      config: {
        apiKey: requireEnv('EXA_API_KEY'),
        type: 'fast',
        numResults: 6,
        includeDomains: ['docs.openclaw.ai'],
        contents: {
          highlights: { numSentences: 3, highlightsPerUrl: 3 },
          text: { maxCharacters: 900, includeHtmlTags: false },
          summary: { query: 'API documentation, architecture, release notes, changelog' },
        },
        startPublishedDate,
        includeText: ['OpenClaw'],
      },
      queries: [
        'site:docs.openclaw.ai OpenClaw changelog',
        'site:docs.openclaw.ai OpenClaw API',
        'site:docs.openclaw.ai OpenClaw architecture',
      ],
    },
    {
      key: 'community',
      title: 'Community bucket',
      config: {
        apiKey: requireEnv('EXA_API_KEY'),
        type: 'fast',
        numResults: 8,
        includeDomains: ['x.com', 'twitter.com', 'v2ex.com'],
        contents: {
          highlights: { numSentences: 3, highlightsPerUrl: 3 },
          text: { maxCharacters: 900, includeHtmlTags: false },
          summary: { query: 'technical discussion, architecture analysis, API docs, benchmark, performance optimization' },
        },
        startPublishedDate,
        includeText: ['OpenClaw'],
      },
      queries: [
        'site:x.com OpenClaw GitHub OR issue OR release OR benchmark',
        'site:twitter.com OpenClaw GitHub OR issue OR release OR benchmark',
        'site:v2ex.com OpenClaw architecture OR API OR performance OR issue',
      ],
    },
  ],
  positive: [
    'bug', 'regression', 'fix', 'issue', 'pull request', 'pr', 'commit', 'release', 'changelog',
    'performance', 'benchmark', 'api', 'architecture', 'webhook', 'plugin', 'security', 'timeout',
    'cron', 'stream', 'session', 'workspace', 'oauth', 'tls', 'schema', 'config', 'docs', 'doc',
    '问题', '修复', '回归', '性能', '架构', '接口', '文档', '版本', '规则', '插件', 'webhook', '安全', '超时'
  ],
  negative: [
    '火了', '看法', '安利', '不用服务器', '从零构建', 'build your own', '本地大模型优先版',
    'marketing', 'viral', 'trend', 'pet', 'animal', 'claw machine', '教程', '学习用', '分享创造'
  ],
  communityMust: [
    'bug', 'issue', 'api', 'release', 'benchmark', 'performance', 'webhook', 'plugin',
    'architecture', 'docs', 'pull request', 'pr', 'github', '版本', '规则', '接口', '文档', '性能', '架构', '插件', 'webhook', '问题', '修复'
  ],
  docPathAllow: ['changelog', 'release', 'api', 'reference', 'docs', 'troubleshooting'],
  themeRules: [
    { key: 'cron-regression', label: 'Cron / 调度回归', kws: ['cron', 'scheduler', 'queueahead', 'isolated session', 'force-run', 'manual cron'] },
    { key: 'runtime-timeouts', label: '运行时 / 超时 / 回复失败', kws: ['websocket 1006', 'timed out', 'empty payload', 'fallback appears unreliable', 'models status --probe', 'web_fetch hang', 'exec and web_fetch hang'] },
    { key: 'security-secrets-auth', label: '安全 / Secret / Auth', kws: ['secretref', 'provider auth env', 'api key', 'oauth', 'plaintext', 'credentials', 'auth env', 'secret'] },
    { key: 'workspace-routing', label: 'Workspace / 配置 / 路由', kws: ['workspace', 'sessions_spawn', 'unknown config keys', 'control ui', 'path', 'routing', 'config'] },
    { key: 'channels-streaming', label: '渠道集成 / 流式交互', kws: ['mattermost', 'discord', 'streaming', 'tls fingerprint', 'exec approvals'] },
    { key: 'cli-backup-update', label: 'CLI / 备份 / 更新', kws: ['backup create', 'self-update', 'file lock', 'update command', 'tmp file'] },
    { key: 'community-ecosystem', label: '社区技术讨论 / 生态兼容', kws: ['v2ex', 'wecom', 'kimicode', 'plugin version', 'api provider', 'webhook'] },
  ],
  themeOrder: {
    'cron-regression': 100,
    'runtime-timeouts': 95,
    'security-secrets-auth': 90,
    'workspace-routing': 80,
    'channels-streaming': 70,
    'cli-backup-update': 60,
    'community-ecosystem': 40,
    'misc': 10,
  },
  systemPrompt: [
    '你是 OpenClaw 技术简报编辑器。',
    '只允许使用给定候选证据，不要补充外部事实，不要臆测。',
    '候选条目可能存在主题重合，请合并重复点，优先保留信息密度高、技术价值高、时间新的内容。',
  ],
};

const SOCIAL_PROFILE: ProfileConfig = {
  id: 'social',
  title: '🌐 **OpenClaw 社区热度简报**',
  targetItems: 10,
  buckets: [
    {
      key: 'social-core',
      title: 'Social core bucket',
      config: {
        apiKey: requireEnv('EXA_API_KEY'),
        type: 'fast',
        numResults: 8,
        includeDomains: ['x.com', 'twitter.com', 'weibo.com'],
        contents: {
          highlights: { numSentences: 3, highlightsPerUrl: 3 },
          text: { maxCharacters: 900, includeHtmlTags: false },
          summary: { query: 'community discussion, announcement, sentiment, release reaction, market buzz' },
        },
        startPublishedDate,
        includeText: ['OpenClaw'],
      },
      queries: [
        'site:x.com OpenClaw announcement OR discussion OR release',
        'site:twitter.com OpenClaw announcement OR discussion OR reaction',
        'site:weibo.com OpenClaw 社区 OR 发布 OR 讨论',
      ],
    },
    {
      key: 'cn-community',
      title: 'Chinese community bucket',
      config: {
        apiKey: requireEnv('EXA_API_KEY'),
        type: 'fast',
        numResults: 8,
        includeDomains: ['v2ex.com', 'juejin.cn', 'sspai.com', '36kr.com'],
        contents: {
          highlights: { numSentences: 3, highlightsPerUrl: 3 },
          text: { maxCharacters: 900, includeHtmlTags: false },
          summary: { query: 'community buzz, user sentiment, adoption, plugin ecosystem, Chinese discussion' },
        },
        startPublishedDate,
        includeText: ['OpenClaw'],
      },
      queries: [
        'site:v2ex.com OpenClaw 讨论 OR 社区 OR 插件 OR 生态',
        'site:juejin.cn OpenClaw 发布 OR 社区 OR 使用体验',
        'site:sspai.com OR site:36kr.com OpenClaw AI 开源 社区',
      ],
    },
    {
      key: 'bigtech-practice',
      title: 'BigTech practice bucket',
      config: {
        apiKey: requireEnv('EXA_API_KEY'),
        type: 'fast',
        numResults: 8,
        includeDomains: ['juejin.cn', '36kr.com', 'infoq.cn', 'v2ex.com', 'x.com', 'twitter.com', 'weibo.com'],
        contents: {
          highlights: { numSentences: 3, highlightsPerUrl: 3 },
          text: { maxCharacters: 900, includeHtmlTags: false },
          summary: { query: 'big tech practice, enterprise adoption, enterprise workflow, AI company usage, cloud deployment, enterprise integration' },
        },
        startPublishedDate,
        includeText: ['OpenClaw'],
      },
      queries: [
        'OpenClaw 阿里 OR 腾讯 OR 字节 OR 百度 OR 京东 OR 美团 OR 小米 OR 快手 OR B站 实践 OR 接入 OR 部署',
        'OpenClaw 企业微信 OR 钉钉 OR 飞书 OR 阿里云 OR 腾讯云 OR 火山引擎 OR 千问 OR 豆包 接入',
        'OpenClaw OpenAI OR Anthropic OR Google OR xAI OR Meta practice OR workflow OR deployment',
      ],
    },
    {
      key: 'broader-news',
      title: 'Broader news bucket',
      config: {
        apiKey: requireEnv('EXA_API_KEY'),
        type: 'fast',
        numResults: 6,
        includeDomains: ['36kr.com', 'infoq.cn', 'huxiu.com', 'geekpark.net'],
        contents: {
          highlights: { numSentences: 3, highlightsPerUrl: 3 },
          text: { maxCharacters: 900, includeHtmlTags: false },
          summary: { query: 'AI open source community buzz, user reaction, project announcement' },
        },
        startPublishedDate,
        includeText: ['OpenClaw'],
      },
      queries: [
        'OpenClaw AI open source community news',
        'OpenClaw project announcement AI community',
        'OpenClaw social buzz open source AI',
      ],
    },
  ],
  positive: [
    'announcement', 'release', 'launch', 'discussion', 'community', 'sentiment', 'buzz', 'reaction', 'adoption', 'plugin', 'ecosystem',
    '发布', '讨论', '社区', '热度', '反馈', '反应', '生态', '插件', '传播', '体验', '用户', '兼容', '接入', '市场', '热议',
    '实践', '落地', '案例', '部署', '企业微信', '钉钉', '飞书', '阿里云', '腾讯云', '火山引擎', '豆包', '千问', '企业应用'
  ],
  negative: [
    'bug', 'regression', 'pull request', 'pr', 'issue', 'benchmark', 'api docs', 'performance optimization',
    '宠物', '动物', 'claw machine', 'pet', 'animal', '营销软文', '纯转载', '教程搬运', '低质量搬运', '手把手', '完全指南', '最全教程', '从零开始'
  ],
  communityMust: [
    'announcement', 'release', 'discussion', 'community', 'sentiment', 'buzz', 'plugin', 'ecosystem',
    '发布', '讨论', '社区', '热度', '反馈', '生态', '插件', '用户', '体验', '传播', '实践', '接入', '部署', '案例', '企业微信', '钉钉', '飞书'
  ],
  docPathAllow: ['blog', 'news', 'announcement', 'release'],
  themeRules: [
    { key: 'project-announcements', label: '项目发布 / 动态', kws: ['announcement', 'release', 'launch', '发布', '更新', '上线'] },
    { key: 'community-buzz', label: '社区热度 / 舆情', kws: ['热度', 'buzz', 'sentiment', 'reaction', 'community discussion', '热议', '反馈'] },
    { key: 'bigtech-practice', label: '大厂 / AI 大厂实践应用', kws: ['阿里', '腾讯', '字节', '百度', '京东', '美团', '小米', '快手', '阿里云', '腾讯云', '火山引擎', '千问', '豆包', '企业微信', '钉钉', '飞书', '实践', '部署', '接入', 'workflow', 'enterprise'] },
    { key: 'user-feedback', label: '用户反馈 / 使用体验', kws: ['体验', 'feedback', 'adoption', '接入', '用户', '部署', '使用'] },
    { key: 'ecosystem-compatibility', label: '生态扩展 / 兼容', kws: ['plugin', 'ecosystem', '兼容', 'wecom', 'kimicode', 'api provider', 'webhook'] },
    { key: 'broader-ai-buzz', label: 'AI 圈传播 / 市场 buzz', kws: ['market buzz', 'ai community', 'open source community', '传播', '市场', '开源社区'] },
    { key: 'cn-community', label: '中文社区讨论', kws: ['v2ex', 'juejin', 'sspai', '36kr', '中文社区'] },
  ],
  themeOrder: {
    'project-announcements': 100,
    'bigtech-practice': 98,
    'community-buzz': 95,
    'user-feedback': 85,
    'ecosystem-compatibility': 80,
    'cn-community': 70,
    'broader-ai-buzz': 60,
    'misc': 10,
  },
  systemPrompt: [
    '你是 OpenClaw 社区热度简报编辑器。',
    '只允许使用给定候选证据，不要补充外部事实，不要臆测。',
    '优先保留社区讨论热度、项目发布、用户反馈、生态扩展与传播动向，不要把纯技术 issue/PR 当作主内容。',
    '额外优先关注互联网大厂、AI 大厂、云厂商、企业协作平台对 OpenClaw 的实践应用、接入案例、部署案例与工作流落地。',
    '尽量减少纯教程稿、纯媒体转述和低信息密度热文。',
  ],
};

const PROFILE = PROFILE_ID === 'social' ? SOCIAL_PROFILE : TECH_PROFILE;
const TARGET_ITEMS = Number(TARGET_ITEMS_FLAG || PROFILE.targetItems);

function inferTheme(item: SearchResult) {
  const hay = lc([item.title, item.evidence, item.summary, item.textPreview].join(' '));
  let best = { key: 'misc', label: '其他条目', hits: 0 };
  for (const rule of PROFILE.themeRules) {
    let hits = 0;
    for (const kw of rule.kws) if (hay.includes(lc(kw))) hits += 1;
    if (hits > best.hits) best = { key: rule.key, label: rule.label, hits };
  }
  return best;
}

function themePriority(themeKey: string) {
  return PROFILE.themeOrder[themeKey] || 0;
}

function scoreItem(item: SearchResult) {
  const title = String(item.title || '');
  const url = String(item.url || '');
  const hay = lc([title, item.summary, item.textPreview, ...(item.highlights || [])].join(' \n '));
  const reasons: string[] = [];
  let score = 0;
  let keep = true;

  if (PROFILE.id === 'tech') {
    if (item.bucket === 'github') score += 45;
    if (item.bucket === 'community') score += 18;
    if (item.bucket === 'docs') score += 8;
    if (/github\.com\/openclaw\/openclaw\/(pull|issues)\//.test(url)) { score += 35; reasons.push('repo-issue-pr'); }
    if (/github\.com\/openclaw\/openclaw\//.test(url)) { score += 15; reasons.push('repo-match'); }
  } else {
    if (item.bucket === 'social-core') score += 38;
    if (item.bucket === 'cn-community') score += 28;
    if (item.bucket === 'broader-news') score += 16;
    if (/x\.com|twitter\.com|weibo\.com/.test(url)) { score += 18; reasons.push('social-source'); }
    if (/v2ex\.com|juejin\.cn|sspai\.com|36kr\.com/.test(url)) { score += 14; reasons.push('cn-community-source'); }
  }

  for (const kw of PROFILE.positive) if (hay.includes(lc(kw))) { score += 6; reasons.push(`+${kw}`); }
  for (const kw of PROFILE.negative) if (hay.includes(lc(kw))) { score -= 18; reasons.push(`-${kw}`); }

  const mustHit = PROFILE.communityMust.some((kw) => hay.includes(lc(kw)));
  if ((item.bucket === 'community' || item.bucket === 'cn-community' || item.bucket === 'social-core' || item.bucket === 'broader-news') && !mustHit) {
    keep = false; reasons.push('community-no-required-signal');
  }

  if (item.bucket === 'docs') {
    const pathname = safePath(url);
    const ok = PROFILE.docPathAllow.some((kw) => pathname.includes(kw));
    if (!ok) { keep = false; reasons.push('docs-path-not-allowed'); }
  }

  if (PROFILE.id === 'tech') {
    if (title.includes('gemini improved and running well')) { keep = false; reasons.push('low-signal-pr'); }
    if (/v2ex\.com/.test(url) && /看法|火了|不用服务器|从零构建|build your own|本地大模型优先版|1 分钟一个 feature|feature/i.test(title)) {
      keep = false; reasons.push('generic-community-topic');
    }
  } else {
    if (/github\.com\/openclaw\/openclaw\/(pull|issues)\//.test(url) && !/announcement|release|发布|更新/i.test(hay)) {
      keep = false; reasons.push('too-technical-for-social');
    }
  }

  if (!item.url) { keep = false; reasons.push('missing-url'); }
  return { keep, score, reasons };
}

async function runBuckets() {
  const raw: any = { generatedAt: new Date().toISOString(), profile: PROFILE.id, hoursBack: HOURS_BACK, startPublishedDate, buckets: [] };
  const items: SearchResult[] = [];

  for (const bucket of PROFILE.buckets) {
    const searchTool = webSearch(bucket.config);
    const bucketDebug: any = { key: bucket.key, title: bucket.title, queries: [] };
    for (const q of bucket.queries) {
      try {
        const res: any = await searchTool.execute({ query: q });
        const results = res?.results || [];
        const mapped: SearchResult[] = results.map((r: any) => ({
          bucket: bucket.key,
          bucketTitle: bucket.title,
          query: q,
          title: r.title,
          url: r.url,
          publishedDate: r.publishedDate || r.published_date || '',
          highlights: r.highlights || [],
          summary: r.summary || '',
          textPreview: clip(r.text || '', 500),
        }));
        bucketDebug.queries.push({ query: q, count: mapped.length, results: mapped });
        items.push(...mapped);
      } catch (e: any) {
        bucketDebug.queries.push({ query: q, error: String(e?.message || e || 'unknown error') });
      }
    }
    raw.buckets.push(bucketDebug);
  }

  writeJson('01-raw.json', raw);
  return items;
}

function filterItems(items: SearchResult[]) {
  const dedup = new Map<string, SearchResult>();
  for (const item of items) {
    const scored = scoreItem(item);
    const enriched: SearchResult = { ...item, keep: scored.keep, score: scored.score, reasons: scored.reasons, evidence: compactEvidence(item) };
    const prev = dedup.get(item.url);
    if (!prev || (enriched.score || 0) > (prev.score || 0)) dedup.set(item.url, enriched);
  }
  const all = [...dedup.values()];
  const kept = all.filter((x) => x.keep).sort((a, b) => ((b.score || 0) - (a.score || 0)) || String(b.publishedDate || '').localeCompare(String(a.publishedDate || '')));
  const dropped = all.filter((x) => !x.keep).sort((a, b) => (b.score || 0) - (a.score || 0));
  const out = { generatedAt: new Date().toISOString(), profile: PROFILE.id, rawCount: items.length, uniqueCount: all.length, keptCount: kept.length, droppedCount: dropped.length, kept, dropped };
  writeJson('02-filtered.json', out);
  return out;
}

function clusterItems(kept: SearchResult[]) {
  for (const item of kept) {
    const theme = inferTheme(item);
    item.themeKey = theme.key;
    item.themeLabel = theme.label;
    item.themeHits = theme.hits;
  }
  const groups = new Map<string, SearchResult[]>();
  for (const item of kept) {
    if (!groups.has(item.themeKey!)) groups.set(item.themeKey!, []);
    groups.get(item.themeKey!)!.push(item);
  }
  const clusters: Cluster[] = [...groups.entries()].map(([key, arr]) => {
    const itemsSorted = arr.sort((a, b) => ((b.score || 0) - (a.score || 0)) || String(b.publishedDate || '').localeCompare(String(a.publishedDate || '')));
    const rep = itemsSorted[0];
    return {
      themeKey: key,
      themeLabel: rep.themeLabel!,
      clusterPriority: themePriority(key),
      itemCount: itemsSorted.length,
      representative: rep,
      members: itemsSorted,
    };
  }).sort((a, b) => (b.clusterPriority - a.clusterPriority) || (b.itemCount - a.itemCount));
  const out = { generatedAt: new Date().toISOString(), profile: PROFILE.id, totalClusters: clusters.length, clusters };
  writeJson('03-clustered.json', out);
  return out;
}

function buildContextV3(clusters: Cluster[]) {
  const selectedClusters = clusters.slice(0, 6);
  const candidateItems: SearchResult[] = [];
  for (const cluster of selectedClusters) {
    const cap = cluster.themeKey === 'community-ecosystem' || cluster.themeKey === 'broader-ai-buzz' ? 1 : 2;
    candidateItems.push(...cluster.members.slice(0, cap));
  }
  const items = candidateItems
    .sort((a, b) => String(b.publishedDate || '').localeCompare(String(a.publishedDate || '')) || ((b.score || 0) - (a.score || 0)))
    .slice(0, 12);

  const lines = items.map((x, i) => [
    `Item#${i + 1}`,
    `theme=${x.themeLabel}`,
    `date=${x.publishedDate || 'N/A'}`,
    `title=${x.title}`,
    `url=${x.url}`,
    `evidence=${x.evidence}`,
  ].join(' | '));

  const out = { generatedAt: new Date().toISOString(), profile: PROFILE.id, clusterCount: selectedClusters.length, itemCount: items.length, items, lines };
  writeJson('04-context-v3.json', out);
  fs.writeFileSync(path.join(OUT_DIR, '04-context-v3.txt'), lines.join('\n\n') + '\n');
  return out;
}

type FinalBriefItem = {
  title: string;
  date: string;
  abstract: string;
  url: string;
};

function extractJsonPayload(text: string): any {
  const raw = String(text || '').trim();
  try {
    return JSON.parse(raw);
  } catch {}

  const fenced = raw.match(/```json\s*([\s\S]*?)\s*```/i) || raw.match(/```\s*([\s\S]*?)\s*```/i);
  if (fenced) {
    try {
      return JSON.parse(fenced[1].trim());
    } catch {}
  }

  const first = raw.indexOf('{');
  const last = raw.lastIndexOf('}');
  if (first >= 0 && last > first) {
    const sliced = raw.slice(first, last + 1);
    return JSON.parse(sliced);
  }

  throw new Error('LLM did not return valid JSON');
}

function normalizeDate(value: string) {
  const s = String(value || '').trim();
  const m = s.match(/20\d{2}[-/](0[1-9]|1[0-2])[-/](0[1-9]|[12]\d|3[01])/);
  return m ? m[0].replace(/\//g, '-') : 'N/A';
}

function cleanTitle(value: string) {
  let s = String(value || '').trim();
  s = s.replace(/^\d+[\.、]\s*/, '');
  s = s.replace(/^[-*]\s*/, '');
  s = s.replace(/^\*\*(.*?)\*\*$/, '$1');
  s = s.replace(/^标题[:：]\s*/, '');
  return s || '未命名条目';
}

function cleanAbstract(value: string) {
  let s = String(value || '').trim();
  s = s.replace(/^摘要[:：]\s*/, '');
  return clip(s, 120);
}

function cleanUrl(value: string) {
  const s = String(value || '').trim();
  const m = s.match(/https?:\/\/\S+/);
  return m ? m[0].replace(/[).,，。；;]+$/, '') : 'N/A';
}

function normalizeFinalItems(payload: any) {
  const arr = Array.isArray(payload?.items) ? payload.items : [];
  const items: FinalBriefItem[] = [];
  for (const row of arr) {
    const item: FinalBriefItem = {
      title: cleanTitle(row?.title || row?.titleZh || row?.headline || ''),
      date: normalizeDate(row?.date || ''),
      abstract: cleanAbstract(row?.abstract || row?.summary || ''),
      url: cleanUrl(row?.url || row?.source || row?.link || ''),
    };
    if (item.title && item.url !== 'N/A') items.push(item);
  }
  return items.slice(0, TARGET_ITEMS);
}

function renderFinalMarkdown(items: FinalBriefItem[]) {
  const today = new Date().toISOString().slice(0, 10);
  const lines: string[] = [`${PROFILE.title} | ${today}`, ''];
  items.forEach((item, idx) => {
    if (idx > 0) lines.push('---', '');
    lines.push(`${idx + 1}. **${item.title}**`);
    lines.push(`- 📅 ${item.date}`);
    lines.push(`- 📝 ${item.abstract}`);
    lines.push(`- 🔗 ${item.url}`);
    lines.push('');
  });
  return lines.join('\n').trimEnd() + '\n';
}

async function summarizeWithLLM(contextV3: ReturnType<typeof buildContextV3>, openrouterKey: string) {
  const openrouter = createOpenRouter({ apiKey: openrouterKey });
  const prompt = [
    ...PROFILE.systemPrompt,
    `目标：从候选证据中整理最多 ${TARGET_ITEMS} 条中文简报（如果高质量候选不足，可少于 ${TARGET_ITEMS} 条，绝不编造）。`,
    '你必须只返回 JSON，不要返回 markdown，不要返回解释，不要使用代码块。',
    '返回格式严格如下：',
    '{"items":[{"title":"中文标题","date":"YYYY-MM-DD","abstract":"一句话摘要","url":"https://..."}]}',
    '要求：',
    '1. title 必须是自然、简洁的简体中文；如果原始标题是英文，必须翻译成中文。必要时可保留少量关键英文术语、版本号、Issue/PR 编号。',
    '2. abstract 必须是简洁中文一句话，不要重复 title。',
    '3. url 必须是完整原文 URL。',
    '4. 结果按日期从新到旧排序。',
    '5. 只输出 JSON。',
    '',
    '候选证据如下：',
    ...contextV3.lines,
  ].join('\n');

  const { text, usage } = await generateText({
    model: openrouter('x-ai/grok-4-fast'),
    prompt,
    temperature: 0.1,
    maxOutputTokens: 1200,
  });

  const payload = extractJsonPayload(text);
  const items = normalizeFinalItems(payload);
  if (!items.length) throw new Error('No valid items parsed from LLM JSON output');

  const markdown = renderFinalMarkdown(items);
  const out = { generatedAt: new Date().toISOString(), profile: PROFILE.id, usage, promptChars: prompt.length, rawText: text, parsed: payload, items, markdown };
  writeJson('05-final-report.json', out);
  fs.writeFileSync(path.join(OUT_DIR, '05-final-report.md'), markdown);
  return out;
}

function writeJson(name: string, obj: any) {
  fs.writeFileSync(path.join(OUT_DIR, name), JSON.stringify(obj, null, 2));
}

function writeSummaryMarkdown(stats: { raw: number; kept: number; clusters: number; ctxItems: number; usage?: any }) {
  const lines = [
    '# Exa pipeline summary',
    '',
    `- profile: ${PROFILE.id}`,
    `- hoursBack: ${HOURS_BACK}`,
    `- targetItems: ${TARGET_ITEMS}`,
    `- rawResults: ${stats.raw}`,
    `- keptCandidates: ${stats.kept}`,
    `- clusters: ${stats.clusters}`,
    `- llmContextItems: ${stats.ctxItems}`,
    stats.usage ? `- totalTokens: ${stats.usage.totalTokens || 'N/A'}` : '',
    stats.usage ? `- inputTokens: ${stats.usage.inputTokens || 'N/A'}` : '',
    stats.usage ? `- outputTokens: ${stats.usage.outputTokens || 'N/A'}` : '',
    '',
    '## Artifacts',
    '',
    '- 01-raw.json',
    '- 02-filtered.json',
    '- 03-clustered.json',
    '- 04-context-v3.json',
    '- 04-context-v3.txt',
    '- 05-final-report.json',
    '- 05-final-report.md',
  ].filter(Boolean);
  fs.writeFileSync(path.join(OUT_DIR, 'README.md'), lines.join('\n') + '\n');
}

const openrouterKey = loadOpenRouterKey();
if (!openrouterKey) throw new Error('Missing OpenRouter key');

const rawItems = await runBuckets();
const filtered = filterItems(rawItems);
const clustered = clusterItems(filtered.kept);
const contextV3 = buildContextV3(clustered.clusters);
const final = await summarizeWithLLM(contextV3, openrouterKey);
writeSummaryMarkdown({ raw: rawItems.length, kept: filtered.keptCount, clusters: clustered.totalClusters, ctxItems: contextV3.itemCount, usage: final.usage });

if (DEBUG) {
  console.log(JSON.stringify({
    profile: PROFILE.id,
    outDir: OUT_DIR,
    raw: rawItems.length,
    kept: filtered.keptCount,
    clusters: clustered.totalClusters,
    ctxItems: contextV3.itemCount,
    tokens: final.usage || {},
  }, null, 2));
}

console.log(path.join(OUT_DIR, '05-final-report.md'));
