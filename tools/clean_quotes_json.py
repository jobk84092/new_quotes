import json
import re
import sys
from collections import Counter
from pathlib import Path


def norm_spaces(s: str) -> str:
    return re.sub(r"\s+", " ", (s or "")).strip()


def strip_controls(s: str) -> str:
    if not s:
        return ""
    out = []
    for ch in s:
        o = ord(ch)
        if ch in ("\n", "\t"):
            out.append(ch)
            continue
        if o < 32:
            continue
        if 0x7F <= o <= 0x9F:
            continue
        out.append(ch)
    return "".join(out)


def clean_text(s: str) -> str:
    s = strip_controls((s or "").strip())
    if not s:
        return ""
    s = (
        s.replace("\u2018", "'")
        .replace("\u2019", "'")
        .replace("\u201c", '"')
        .replace("\u201d", '"')
        .replace("\u2014", "-")
        .replace("\u2026", "...")
    )
    # Fix common artifact: " nIt" from broken newline
    s = re.sub(r"([.!?])\s+n([A-Z])", r"\1 \2", s)
    s = norm_spaces(s)
    # Strip wrapping quotes if the whole string is quoted
    if len(s) >= 2 and s[0] == s[-1] and s[0] in ("'", '"'):
        s = s[1:-1].strip()
    # Remove space before punctuation
    s = re.sub(r"\s+([,.;:!?])", r"\1", s)
    # Collapse repeated punctuation
    s = re.sub(r"\?{2,}", "?", s)
    s = re.sub(r"!{2,}", "!", s)
    s = re.sub(r"\.{4,}", "...", s)
    # Fix isolated i -> I
    s = re.sub(r"\bi\b", "I", s)
    # Ensure punctuation ending (helps UX)
    if s and s[-1] not in (".", "!", "?", '"', "'"):
        s += "."
    # Capitalize first letter if it starts with a letter
    if s and s[0].isalpha():
        s = s[0].upper() + s[1:]
    return s


def clean_author(s: str) -> str:
    s = norm_spaces(strip_controls((s or "").strip()))
    s = re.sub(r"^[^A-Za-z0-9]+", "", s).strip()
    if not s:
        return "Unknown"
    if s.lower() == "unknown":
        return "Unknown"
    return s


def main():
    repo = Path(__file__).resolve().parents[1]
    quotes_path = repo / "assets" / "data" / "quotes.json"
    out_path = quotes_path
    report_path = repo / "tools" / "quotes_quality_report.md"

    if len(sys.argv) >= 2:
        quotes_path = Path(sys.argv[1]).expanduser().resolve()
    if len(sys.argv) >= 3:
        out_path = Path(sys.argv[2]).expanduser().resolve()

    quotes = json.loads(quotes_path.read_text(encoding="utf-8"))
    if not isinstance(quotes, list):
        raise SystemExit("quotes.json must be a JSON list")

    before = len(quotes)
    removed_empty = 0
    removed_bad = 0
    removed_replacement = 0
    changed = 0
    duplicates = 0
    repl_char = 0
    sample_replacement = []

    seen = set()
    out = []
    cat_counts = Counter()

    for q in quotes:
        if not isinstance(q, dict):
            removed_bad += 1
            continue

        text0 = str(q.get("text", "")).strip()
        author0 = str(q.get("author", "")).strip()
        cat = str(q.get("category", "")).strip().lower()

        text = clean_text(text0)
        author = clean_author(author0)

        if not text:
            removed_empty += 1
            continue

        if "�" in text or "�" in author:
            repl_char += 1
            if len(sample_replacement) < 20:
                sample_replacement.append((author, text[:160]))
            removed_replacement += 1
            continue

        key = (text.lower(), author.lower(), cat)
        if key in seen:
            duplicates += 1
            continue
        seen.add(key)

        if text != text0 or author != author0:
            changed += 1

        q2 = dict(q)
        q2["text"] = text
        q2["author"] = author
        q2["category"] = cat
        out.append(q2)
        cat_counts[cat] += 1

    out_path.write_text(json.dumps(out, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    lines = []
    lines.append("# Quotes quality report\n")
    lines.append(f"- Input: `{quotes_path}`")
    lines.append(f"- Output: `{out_path}`")
    lines.append(f"- Quotes before: **{before}**")
    lines.append(f"- Quotes after: **{len(out)}**")
    lines.append("")
    lines.append("## Cleanup stats")
    lines.append(f"- **Changed (text/author normalized)**: {changed}")
    lines.append(f"- **Removed (empty text)**: {removed_empty}")
    lines.append(f"- **Removed (bad rows)**: {removed_bad}")
    lines.append(f"- **Removed (replacement character �)**: {removed_replacement}")
    lines.append(f"- **Removed (exact duplicates)**: {duplicates}")
    lines.append(f"- **Quotes containing replacement characters (�) (detected)**: {repl_char}")
    if sample_replacement:
        lines.append("")
        lines.append("## Sample removed (�) quotes")
        for a, t in sample_replacement:
            lines.append(f"- **{a or 'Unknown'}**: {t}")
    lines.append("")
    lines.append("## Category counts (after)")
    for k, v in cat_counts.most_common():
        lines.append(f"- **{k}**: {v}")
    report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print(f"Wrote cleaned quotes: {len(out)}")
    print(f"Wrote report: {report_path}")


if __name__ == "__main__":
    main()

