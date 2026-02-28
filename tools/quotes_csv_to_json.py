import csv
import datetime as _dt
import json
import re
import sys
from collections import Counter
from pathlib import Path


ALLOWED_CATEGORIES = {
    "love",
    "motivation",
    "wisdom",
    "focus",
    "inspiration",
    "growth",
}


def guess_category_from_text(text: str) -> str:
    t = _norm_spaces(_strip_control_chars((text or "")).lower())
    if not t:
        return ""
    # Very lightweight keyword guesser; used only when Category/Tag don't map.
    if re.search(r"\blove\b|\bheart\b|\bmarry\b|\brelationship\b|\bromance\b", t):
        return "love"
    if re.search(r"\bfocus\b|\bdiscipline\b|\bhabit\b|\bhabits\b|\bproductiv", t):
        return "focus"
    if re.search(r"\bgrow\b|\bgrowth\b|\bimprove\b|\blearn\b|\bchange\b|\bheal", t):
        return "growth"
    if re.search(r"\binspir", t) or re.search(r"\bhope\b|\bfaith\b|\bdream\b|\bcourage\b|\bfreedom\b", t):
        return "inspiration"
    if re.search(r"\bsuccess\b|\bwork\b|\bgoal\b|\bgoals\b|\bwin\b|\bmotivat", t):
        return "motivation"
    if re.search(r"\bwisdom\b|\blife\b|\btruth\b|\bmind\b|\bphilosoph", t):
        return "wisdom"
    return ""


def _norm_spaces(s: str) -> str:
    return re.sub(r"\s+", " ", s).strip()


def _strip_control_chars(s: str) -> str:
    if not s:
        return s
    # Remove ASCII control chars + C1 controls (often show up as \x9d etc)
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


def clean_quote_text(s: str) -> str:
    s = (s or "").strip()
    if not s:
        return ""

    # Normalize common smart punctuation
    s = (
        s.replace("\u2018", "'")
        .replace("\u2019", "'")
        .replace("\u201c", '"')
        .replace("\u201d", '"')
        .replace("\u2014", "-")
        .replace("\u2026", "...")
    )

    s = _strip_control_chars(s)

    # Fix common CSV artifact: ". nIt" where "\nIt" got mangled.
    s = re.sub(r"([.!?])\s+n([A-Z])", r"\1 \2", s)

    s = _norm_spaces(s)

    # Strip wrapping quotes if the entire string is quoted
    if (len(s) >= 2) and ((s[0] == s[-1]) and s[0] in ("'", '"')):
        s = s[1:-1].strip()

    # Fix isolated " i " -> " I "
    s = re.sub(r"\bi\b", "I", s)

    # Remove space before punctuation
    s = re.sub(r"\s+([,.;:!?])", r"\1", s)

    # Collapse repeated punctuation like "???" -> "?"
    s = re.sub(r"\?{2,}", "?", s)
    s = re.sub(r"!{2,}", "!", s)
    s = re.sub(r"\.{4,}", "...", s)

    # Capitalize first letter if it starts with a letter
    if s and s[0].isalpha():
        s = s[0].upper() + s[1:]

    # Ensure ending punctuation (helps polish UI)
    if s and s[-1] not in (".", "!", "?", '"', "'"):
        s += "."

    return s


def clean_author(s: str) -> str:
    s = _strip_control_chars((s or "").strip())
    s = _norm_spaces(s)
    # Drop leading stray punctuation/control leftovers (e.g. " Abraham Lincoln")
    s = re.sub(r"^[^A-Za-z0-9]+", "", s).strip()
    if not s:
        return "Unknown"
    # Capitalize simple names like "unknown" -> "Unknown"
    if s.lower() == "unknown":
        return "Unknown"
    return s


def normalize_category(raw: str) -> str:
    raw = _strip_control_chars((raw or "")).strip().lower()
    raw = re.sub(r"\s+", "", raw)  # handle "Foc us"
    raw = raw.replace("-", "").replace("_", "").replace("/", "")
    if not raw:
        return ""

    # Keyword-based mapping to our 6 categories.
    # This keeps your dataset usable even if the CSV has many category labels.
    raw_compact = raw
    def has(*keys: str) -> bool:
        return any(k in raw_compact for k in keys)

    if has("love", "romance", "relationship", "relationships", "heart", "marriage", "dating"):
        return "love"
    if has("motivation", "motivational", "success", "hustle", "work", "hardwork", "discipline", "goal", "goals", "achievement", "winning"):
        return "motivation"
    if has("wisdom", "life", "philosophy", "truth", "mind", "mindset", "knowledge", "advice"):
        return "wisdom"
    if has("focus", "productivity", "productive", "attention", "deepwork", "deep", "clarity", "time", "priorities", "priority", "habit", "habits"):
        return "focus"
    if has("inspiration", "inspire", "hope", "freedom", "faith", "courage", "dream", "dreams", "positive", "positivity"):
        return "inspiration"
    if has("growth", "change", "learning", "learn", "progress", "improve", "improvement", "selfimprovement", "heal", "healing"):
        return "growth"

    # If it's already one of our ids, keep it
    if raw_compact in ALLOWED_CATEGORIES:
        return raw_compact
    return raw_compact


def parse_tags(raw: str):
    raw = _strip_control_chars((raw or "")).strip()
    if not raw:
        return []
    # support comma, semicolon, pipe
    parts = re.split(r"[;,|]", raw)
    tags = []
    for p in parts:
        t = _norm_spaces(p).lower()
        if not t:
            continue
        tags.append(t)
    # de-dup preserve order
    seen = set()
    out = []
    for t in tags:
        if t in seen:
            continue
        seen.add(t)
        out.append(t)
    return out


def detect_columns(fieldnames):
    if not fieldnames:
        return None
    cols = {c.strip().lower(): c for c in fieldnames}

    def pick(*candidates):
        for k in candidates:
            if k in cols:
                return cols[k]
        return None

    quote_col = pick("quote", "text", "quotes", "q")
    author_col = pick("author", "by", "name")
    category_col = pick("category", "cat", "category_id", "topic")
    tags_col = pick("tags", "tag", "keywords")
    created_col = pick("created_at", "date", "created", "createdat")
    premium_col = pick("is_premium", "premium", "paid")
    not_premium_col = pick("is_not_premium", "not_premium", "isnotpremium", "free")

    return {
        "quote": quote_col,
        "author": author_col,
        "category": category_col,
        "tags": tags_col,
        "created_at": created_col,
        "is_premium": premium_col,
        "is_not_premium": not_premium_col,
    }


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 tools/quotes_csv_to_json.py <path/to/quotes.csv> [output_json]")
        sys.exit(2)

    csv_path = Path(sys.argv[1]).expanduser().resolve()
    out_path = (
        Path(sys.argv[2]).expanduser().resolve()
        if len(sys.argv) >= 3
        else (Path(__file__).resolve().parents[1] / "assets" / "data" / "quotes.json")
    )
    report_path = Path(__file__).resolve().parent / "quotes_cleaning_report.md"

    if not csv_path.exists():
        print(f"CSV not found: {csv_path}")
        sys.exit(1)

    if csv_path.stat().st_size == 0:
        print(f"CSV is empty: {csv_path}")
        sys.exit(1)

    today = _dt.date.today().isoformat()
    issues = []
    category_counts = Counter()

    rows_out = []
    dropped_empty = 0
    dropped_bad_cat = 0
    suspicious = []
    mapped_by = Counter()

    def open_csv():
        # Prefer utf-8-sig, but your file contains Windows-1252 bytes (e.g. 0x9D),
        # so fall back to cp1252 with replacement.
        try:
            f0 = csv_path.open("r", encoding="utf-8-sig", newline="")
            # force a small read so decode errors surface here
            f0.read(4096)
            f0.seek(0)
            return f0
        except UnicodeDecodeError:
            return csv_path.open("r", encoding="cp1252", errors="replace", newline="")

    with open_csv() as f:
        reader = csv.reader(f)
        try:
            header = next(reader)
        except StopIteration:
            print("CSV is empty (no header row).")
            sys.exit(1)

        cols = detect_columns(header)
        if not cols or not cols["quote"]:
            print(f"Could not detect quote/text column. Found headers: {header}")
            sys.exit(1)

        # Map column names -> index
        header_norm = [(_strip_control_chars(h or "").strip()) for h in header]
        idx = {name: i for i, name in enumerate(header_norm)}

        def safe_idx(col_name: str):
            if not col_name:
                return None
            return idx.get(col_name)

        quote_idx = safe_idx(cols["quote"])
        author_idx = safe_idx(cols.get("author"))
        cat_idx = safe_idx(cols.get("category"))
        tags_idx = safe_idx(cols.get("tags"))
        created_idx = safe_idx(cols.get("created_at"))
        premium_idx = safe_idx(cols.get("is_premium"))
        not_premium_idx = safe_idx(cols.get("is_not_premium"))

        expected_cols = len(header_norm)

        for i, row_list in enumerate(reader, start=2):  # header = 1
            if not row_list:
                continue

            # Repair common malformed rows where the author contains commas but isn't quoted.
            if len(row_list) > expected_cols and author_idx is not None and cat_idx is not None:
                right_count = expected_cols - cat_idx
                if right_count > 0 and len(row_list) >= (author_idx + right_count):
                    left = row_list[:author_idx]
                    mid = row_list[author_idx:-right_count]
                    right = row_list[-right_count:]
                    row_list = left + [",".join(mid)] + right

            if len(row_list) != expected_cols:
                # Can't safely repair; skip.
                issues.append(f"- Row {i}: wrong column count ({len(row_list)} != {expected_cols}) (dropped)")
                dropped_empty += 1
                continue

            def get_at(j):
                if j is None:
                    return ""
                try:
                    return row_list[j]
                except Exception:
                    return ""

            raw_quote = get_at(quote_idx)
            raw_author = get_at(author_idx)
            raw_cat = get_at(cat_idx)
            raw_tags = get_at(tags_idx)
            raw_created = get_at(created_idx)
            raw_premium = get_at(premium_idx)
            raw_not_premium = get_at(not_premium_idx)

            cleaned_quote = clean_quote_text(raw_quote)
            if not cleaned_quote:
                dropped_empty += 1
                continue

            cat = normalize_category(raw_cat)
            if cat in ALLOWED_CATEGORIES:
                mapped_by["category"] += 1
            else:
                # Try Tag column
                tag_guess = normalize_category(raw_tags)
                if tag_guess in ALLOWED_CATEGORIES:
                    cat = tag_guess
                    mapped_by["tag"] += 1
                else:
                    # Try first parsed tag token
                    parsed_tags = parse_tags(raw_tags)
                    token_guess = normalize_category(parsed_tags[0]) if parsed_tags else ""
                    if token_guess in ALLOWED_CATEGORIES:
                        cat = token_guess
                        mapped_by["tag_token"] += 1
                    else:
                        # Guess from quote text
                        text_guess = guess_category_from_text(cleaned_quote)
                        if text_guess in ALLOWED_CATEGORIES:
                            cat = text_guess
                            mapped_by["quote_text"] += 1
                        else:
                            # Default bucket (keeps dataset usable without exploding categories)
                            cat = "wisdom"
                            mapped_by["default_wisdom"] += 1
                            dropped_bad_cat += 1
                            if len(issues) < 100:
                                issues.append(
                                    f"- Row {i}: unknown category '{raw_cat}' / tag '{raw_tags}' → defaulted to 'wisdom'"
                                )

            author = clean_author(raw_author)
            tags = parse_tags(raw_tags)

            created_at = _norm_spaces(_strip_control_chars(raw_created))
            if not created_at:
                created_at = today

            is_premium = str(raw_premium).strip().lower() in ("1", "true", "yes", "y")
            if not is_premium and raw_not_premium != "":
                is_not_premium = str(raw_not_premium).strip().lower() in ("1", "true", "yes", "y")
                is_premium = not is_not_premium

            raw_compact = _norm_spaces(_strip_control_chars(str(raw_quote)))
            if cleaned_quote != raw_compact:
                issues.append(f"- Row {i}: cleaned quote text")

            if len(cleaned_quote) > 220:
                suspicious.append(f"- Row {i}: very long quote ({len(cleaned_quote)} chars)")
            if "??" in cleaned_quote or "!!" in cleaned_quote:
                suspicious.append(f"- Row {i}: repeated punctuation after cleaning")
            if "�" in cleaned_quote or "�" in author:
                suspicious.append(f"- Row {i}: replacement characters present (check source encoding)")

            rows_out.append(
                {
                    "text": cleaned_quote,
                    "author": author,
                    "category": cat,
                    "tags": tags,
                    "is_premium": bool(is_premium),
                    "created_at": created_at,
                }
            )
            category_counts[cat] += 1

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(rows_out, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    report_lines = []
    report_lines.append("# Quotes CSV cleaning report\n")
    report_lines.append(f"- Input CSV: `{csv_path}`")
    report_lines.append(f"- Output JSON: `{out_path}`")
    report_lines.append(f"- Total output quotes: **{len(rows_out)}**")
    report_lines.append(f"- Dropped (empty quote): **{dropped_empty}**")
    report_lines.append(f"- Dropped (unknown category): **{dropped_bad_cat}**")
    report_lines.append("")
    report_lines.append("## Category counts")
    for cat, cnt in category_counts.most_common():
        report_lines.append(f"- **{cat}**: {cnt}")
    report_lines.append("")
    report_lines.append("## Mapping stats")
    total_mapped = sum(mapped_by.values())
    if total_mapped:
        for k, v in mapped_by.most_common():
            report_lines.append(f"- **{k}**: {v}")
    report_lines.append("")
    report_lines.append("## Notes / issues (first 100)")
    if issues:
        report_lines.extend(issues[:100])
    else:
        report_lines.append("- (none)")

    report_lines.append("")
    report_lines.append("## Suspicious rows (first 100)")
    if suspicious:
        report_lines.extend(suspicious[:100])
    else:
        report_lines.append("- (none)")

    report_path.write_text("\n".join(report_lines) + "\n", encoding="utf-8")
    print(f"Wrote {len(rows_out)} quotes to {out_path}")
    print(f"Wrote report to {report_path}")


if __name__ == "__main__":
    main()

