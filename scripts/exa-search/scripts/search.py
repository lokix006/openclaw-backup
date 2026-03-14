#!/usr/bin/env python3
"""exa-search/scripts/search.py

恢复为“Exa 直接按 prompt 生成中文结果”的版本：
- prompts/*.md 使用头部元数据 + 正文 prompt
- 正文 prompt 直接传给 Exa.answer
- 脚本负责轻量清洗与版式规范化，输出可直接发送的 markdown
- 保留稳定发送链路（由 cron 侧用 CLI 发送）
"""

import argparse
import os
import re
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

try:
    from exa_py import Exa
except ImportError:
    print("[ERROR] exa_py not installed. Run: pip install exa-py", file=sys.stderr)
    sys.exit(1)


HEADER_RE = re.compile(r"^#\s*([a-zA-Z_][a-zA-Z0-9_-]*)\s*:\s*(.*)$")
ITEM_START_RE = re.compile(r"(?m)^\s*(\d+)[\.、]\s+")
DATE_RE = re.compile(r"(20\d{2}[-/](?:0[1-9]|1[0-2])[-/](?:0[1-9]|[12]\d|3[01]))")
URL_RE = re.compile(r"https?://[^\s)]+")
MD_LINK_RE = re.compile(r"\[([^\]]+)\]\((https?://[^)]+)\)")


@dataclass
class Prompt:
    id: str
    label: str
    body: str
    model: str


@dataclass
class AnswerSection:
    prompt: Prompt
    answer: str


def load_env_file(env_path: Path):
    if not env_path.exists():
        return
    for line in env_path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        os.environ.setdefault(k.strip(), v.strip())


def parse_prompt_file(path: Path) -> Prompt:
    raw = path.read_text(encoding="utf-8").strip("\n")
    lines = raw.splitlines()

    meta: dict[str, str] = {}
    body_lines: list[str] = []
    in_header = True
    for line in lines:
        if in_header:
            m = HEADER_RE.match(line.strip())
            if m:
                meta[m.group(1).strip().lower()] = m.group(2).strip()
                continue
            in_header = False
        body_lines.append(line)

    body = "\n".join(body_lines).strip()
    return Prompt(
        id=meta.get("prompt_id", path.stem),
        label=meta.get("label", path.stem),
        body=body,
        model=meta.get("model", "exa"),
    )


def clean_answer(text: str) -> str:
    text = (text or "").strip()
    if not text:
        return "暂无结果"
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


def split_numbered_items(text: str) -> list[tuple[int, str]]:
    matches = list(ITEM_START_RE.finditer(text))
    if not matches:
        return []
    items: list[tuple[int, str]] = []
    for i, m in enumerate(matches):
        start = m.end()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(text)
        num = int(m.group(1))
        body = text[start:end].strip()
        if body:
            items.append((num, body))
    return items


def strip_md_links(text: str) -> str:
    return MD_LINK_RE.sub(lambda m: m.group(1), text)


def extract_urls(text: str) -> list[str]:
    urls = []
    for u in URL_RE.findall(text):
        u = u.rstrip('.,，。；;）)')
        if u not in urls:
            urls.append(u)
    return urls


def normalize_date(text: str) -> str:
    m = DATE_RE.search(text)
    if not m:
        return "N/A"
    return m.group(1).replace('/', '-')


def format_item(num: int, raw: str) -> str:
    if "- 📅" in raw and "- 📝" in raw and "- 🔗" in raw:
        return f"{num}. {raw.strip()}"

    text = " ".join(line.strip() for line in raw.splitlines() if line.strip())
    text = re.sub(r"\s+", " ", text).strip()
    urls = extract_urls(text)
    date = normalize_date(text)

    core = strip_md_links(text)
    core = re.sub(r"\s*\((?:https?://[^)]+|[^)]*https?://[^)]*)\)", "", core)
    core = re.sub(r"\s*（(?:https?://[^）]+|[^）]*https?://[^）]*)）", "", core)
    if date != "N/A":
        core = core.replace(f"（{date}）", "").replace(f"({date})", "")

    title = core
    summary = ""

    if "——" in core:
        title, summary = core.split("——", 1)
    elif "—" in core:
        title, summary = core.split("—", 1)
    elif " - " in core:
        title, summary = core.split(" - ", 1)
    elif "：" in core:
        left, right = core.split("：", 1)
        if len(left) <= 28:
            title, summary = left, right

    title = title.strip(" ：:;；。,. ") or f"条目 {num}"
    summary = summary.strip(" ：:;；。,. ")
    if not summary:
        summary = re.sub(r"^" + re.escape(title) + r"", "", core, count=1).strip(" ：:;；。,. ")
    if not summary:
        summary = "暂无摘要"

    lines = [f"{num}. **{title}**", f"   - 📅 {date}", f"   - 📝 摘要：{summary}"]
    if urls:
        lines.append(f"   - 🔗 原文链接：{urls[0]}")
        for extra in urls[1:]:
            lines.append(f"   - 🔗 补充链接：{extra}")
    else:
        lines.append("   - 🔗 原文链接：N/A")
    return "\n".join(lines)


def normalize_answer_to_markdown(text: str) -> str:
    text = clean_answer(text)
    items = split_numbered_items(text)
    if not items:
        return text
    return "\n\n".join(format_item(num, raw) for num, raw in items)


def run_answer(exa: Exa, prompt: Prompt) -> AnswerSection:
    if not prompt.body:
        return AnswerSection(prompt=prompt, answer="暂无结果")

    resp = exa.answer(prompt.body, text=True, model=prompt.model)
    answer = clean_answer(getattr(resp, "answer", "") or "")
    return AnswerSection(prompt=prompt, answer=answer)


def format_compact(sections: list[AnswerSection]) -> str:
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    lines = [f"=== Exa Answer Results | {now} ===", ""]
    for sec in sections:
        lines.append(f">> [{sec.prompt.label}]")
        lines.append(sec.answer)
        lines.append("")
    lines.append("=== END ===")
    return "\n".join(lines)


def format_markdown(sections: list[AnswerSection]) -> str:
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    lines = [f"📡 **OpenClaw 每日情报（Exa）** | {now}", "", "---", ""]
    for idx, sec in enumerate(sections):
        lines.append(f"**【{sec.prompt.label}】**")
        lines.append("")
        lines.append(normalize_answer_to_markdown(sec.answer))
        lines.append("")
        if idx != len(sections) - 1:
            lines.extend(["---", ""])
    lines.extend(["---", "", "🤖 Powered by Exa Search"])
    return "\n".join(lines)


def main():
    script_dir = Path(__file__).parent
    skill_dir = script_dir.parent

    parser = argparse.ArgumentParser()
    parser.add_argument("--prompts-dir", default=str(skill_dir / "prompts"))
    parser.add_argument("--api-key", default="")
    parser.add_argument("--compact", action="store_true")
    parser.add_argument("--markdown", action="store_true")
    args = parser.parse_args()

    load_env_file(skill_dir / ".env")
    api_key = args.api_key or os.environ.get("EXA_API_KEY", "")
    if not api_key:
        print("[ERROR] No API key. Set EXA_API_KEY in .env or pass --api-key.", file=sys.stderr)
        sys.exit(1)

    prompts_dir = Path(args.prompts_dir)
    if not prompts_dir.exists():
        print(f"[ERROR] prompts dir not found: {prompts_dir}", file=sys.stderr)
        sys.exit(1)

    prompt_files = sorted(p for p in prompts_dir.glob("*.md") if not p.name.startswith("_"))
    if not prompt_files:
        print(f"[ERROR] No .md files found in {prompts_dir}", file=sys.stderr)
        sys.exit(1)

    exa = Exa(api_key)
    sections: list[AnswerSection] = []
    for pf in prompt_files:
        prompt = parse_prompt_file(pf)
        sections.append(run_answer(exa, prompt))

    if args.markdown:
        print(format_markdown(sections))
    else:
        print(format_compact(sections))


if __name__ == "__main__":
    main()
