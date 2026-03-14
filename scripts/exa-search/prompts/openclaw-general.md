# prompt_id: openclaw-general
# label: 🌐 热点资讯
# model: exa

Prioritize searching Twitter/X, Weibo, and general Chinese social media for the most trending news, community discussions, and social updates related to OpenClaw from the past 72 hours. Focus on user sentiments, project announcements, viral topics, installation/deployment trends, and market buzz rather than deep technical details. If social results are limited, broaden the search to include broader Chinese AI/open-source community coverage.

Finally, summarize the findings into 10 items in Simplified Chinese. For each item include:
- 中文标题（如原标题为英文，请翻译成中文）
- 日期（YYYY-MM-DD）
- 一句话摘要
- 完整原文 URL

Requirements:
- Sort in descending order by date
- Keep it concise and information-dense
- Prefer Chinese output throughout
- If multiple reports describe the same story, merge them into one item and choose the strongest source
- Output as a numbered list only
- Each item must remain a single paragraph in the answer, but must clearly contain: 标题、日期、摘要、URL