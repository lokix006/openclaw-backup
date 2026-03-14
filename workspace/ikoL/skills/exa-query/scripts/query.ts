#!/usr/bin/env npx tsx
/**
 * exa-query: lightweight Exa search script for conversational use.
 * Searches Exa and prints JSON results to stdout for LLM to summarize.
 */

import * as fs from 'node:fs';
import * as path from 'node:path';
import { URL } from 'node:url';

const SKILL_DIR = path.resolve(path.dirname(new URL(import.meta.url).pathname), '..');

function loadEnv(file: string) {
  if (!fs.existsSync(file)) return;
  for (const line of fs.readFileSync(file, 'utf8').split(/\r?\n/)) {
    const s = line.trim();
    if (!s || s.startsWith('#') || !s.includes('=')) continue;
    const idx = s.indexOf('=');
    const k = s.slice(0, idx).trim();
    const v = s.slice(idx + 1).trim();
    if (!(k in process.env)) process.env[k] = v;
  }
}

function readFlag(argv: string[], name: string, fallback: string): string {
  const i = argv.indexOf(name);
  if (i >= 0 && argv[i + 1]) return argv[i + 1];
  return fallback;
}

loadEnv(path.join(SKILL_DIR, '.env'));

const argv = process.argv.slice(2);
const query = readFlag(argv, '--query', '');
const numResults = parseInt(readFlag(argv, '--num-results', '5'), 10);
const hoursBack = parseInt(readFlag(argv, '--hours-back', '0'), 10);
const searchType = readFlag(argv, '--type', 'auto');
const apiKey = process.env.EXA_API_KEY || '';

if (!query) {
  console.error('Error: --query is required');
  process.exit(1);
}
if (!apiKey) {
  console.error('Error: EXA_API_KEY not set');
  process.exit(1);
}

const params: Record<string, string | number | boolean> = {
  query,
  num_results: numResults,
  type: searchType,
  use_autoprompt: true,
  contents: JSON.stringify({
    highlights: { numSentences: 3, highlightsPerUrl: 3 },
    summary: { query },
  }),
};

if (hoursBack > 0) {
  const since = new Date(Date.now() - hoursBack * 3600 * 1000).toISOString();
  params.start_published_date = since;
}

const url = new URL('https://api.exa.ai/search');

const body: Record<string, unknown> = {
  query,
  num_results: numResults,
  type: searchType,
  use_autoprompt: true,
  contents: {
    highlights: { numSentences: 3, highlightsPerUrl: 3 },
    summary: { query },
  },
};

if (hoursBack > 0) {
  body.start_published_date = new Date(Date.now() - hoursBack * 3600 * 1000).toISOString();
}

try {
  const resp = await fetch('https://api.exa.ai/search', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
    },
    body: JSON.stringify(body),
  });

  if (!resp.ok) {
    const errText = await resp.text();
    console.error(`Exa API error ${resp.status}: ${errText}`);
    process.exit(1);
  }

  const data: any = await resp.json();
  const results = (data.results || []).map((r: any) => ({
    title: r.title || 'Untitled',
    url: r.url,
    publishedDate: r.publishedDate || r.published_date || '',
    highlights: r.highlights || [],
    summary: r.summary || '',
  }));

  console.log(JSON.stringify({ query, numResults: results.length, results }, null, 2));
} catch (err: any) {
  console.error('Error:', err?.message || err);
  process.exit(1);
}
