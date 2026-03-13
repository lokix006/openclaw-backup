const https = require("https");
const startDate = new Date(Date.now() - 24 * 3600 * 1000).toISOString();
const EXA_KEY = "709a0d3c-7be2-45a5-bfdb-2ede592a25f6";

async function search(query, options = {}) {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify({
      query,
      numResults: options.num || 6,
      startPublishedDate: startDate,
      contents: {
        highlights: { numSentences: 3, highlightsPerUrl: 2 },
        summary: { query: "Claude Anthropic AI latest news" }
      }
    });
    const req = https.request({
      hostname: "api.exa.ai",
      path: "/search",
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": EXA_KEY,
        "Content-Length": Buffer.byteLength(body)
      }
    }, res => {
      let data = "";
      res.on("data", d => data += d);
      res.on("end", () => {
        try { resolve(JSON.parse(data)); } catch(e) { resolve({ results: [] }); }
      });
    });
    req.on("error", reject);
    req.write(body);
    req.end();
  });
}

async function main() {
  const queries = [
    "Anthropic Claude new model release update 2026",
    "Claude AI announcement feature update",
    "Anthropic security advisory update",
    "Claude API changes benchmark performance",
    "Anthropic Claude 中文 更新 发布",
  ];
  
  const allResults = [];
  for (const q of queries) {
    const res = await search(q);
    if (res.results) {
      for (const r of res.results) {
        allResults.push({
          title: r.title,
          url: r.url,
          date: r.publishedDate || "",
          summary: r.summary || "",
          highlights: (r.highlights || []).slice(0, 2).join(" | ")
        });
      }
    }
  }
  
  // deduplicate by url
  const seen = new Set();
  const deduped = allResults.filter(r => {
    if (!r.url || seen.has(r.url)) return false;
    seen.add(r.url);
    return true;
  });
  
  console.log(JSON.stringify(deduped));
}

main().catch(e => { console.error("ERROR:", e.message); process.exit(1); });
