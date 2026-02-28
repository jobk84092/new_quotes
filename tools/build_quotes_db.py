import json
import sqlite3
import sys
from pathlib import Path


def main():
    repo = Path(__file__).resolve().parents[1]
    quotes_json = repo / "assets" / "data" / "quotes.json"
    cats_json = repo / "assets" / "data" / "categories.json"
    out_db = repo / "tools" / "out" / "quotes_premium.db"

    if len(sys.argv) >= 2:
        quotes_json = Path(sys.argv[1]).expanduser().resolve()
    if len(sys.argv) >= 3:
        out_db = Path(sys.argv[2]).expanduser().resolve()

    out_db.parent.mkdir(parents=True, exist_ok=True)

    quotes = json.loads(quotes_json.read_text(encoding="utf-8"))
    categories = json.loads(cats_json.read_text(encoding="utf-8"))

    if not isinstance(quotes, list) or not isinstance(categories, list):
        raise SystemExit("Invalid JSON format (expected lists).")

    if out_db.exists():
        out_db.unlink()

    con = sqlite3.connect(str(out_db))
    con.execute("PRAGMA journal_mode=WAL;")
    con.execute("PRAGMA synchronous=NORMAL;")
    con.execute("PRAGMA temp_store=MEMORY;")

    con.executescript(
        """
        CREATE TABLE categories (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL
        );

        CREATE TABLE quotes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          text TEXT NOT NULL,
          author TEXT NOT NULL,
          category_id TEXT NOT NULL,
          tags TEXT,
          is_premium INTEGER NOT NULL DEFAULT 0,
          created_at TEXT,
          FOREIGN KEY(category_id) REFERENCES categories(id)
        );

        CREATE INDEX idx_quotes_category_id ON quotes(category_id);
        """
    )

    con.executemany(
        "INSERT INTO categories(id, name) VALUES(?, ?)",
        [(str(c.get("id", "")).strip(), str(c.get("name", "")).strip()) for c in categories],
    )

    rows = []
    for q in quotes:
        text = str(q.get("text", "")).strip()
        author = str(q.get("author", "Unknown")).strip() or "Unknown"
        category_id = str(q.get("category", "")).strip()
        tags = q.get("tags", [])
        if isinstance(tags, list):
            tags = ",".join(str(t).strip() for t in tags if str(t).strip())
        else:
            tags = str(tags).strip()
        is_premium = 1 if (q.get("is_premium") is True) else 0
        created_at = str(q.get("created_at", "")).strip()

        if not text or not category_id:
            continue

        rows.append((text, author, category_id, tags, is_premium, created_at))

    con.executemany(
        "INSERT INTO quotes(text, author, category_id, tags, is_premium, created_at) VALUES(?, ?, ?, ?, ?, ?)",
        rows,
    )
    con.commit()
    con.close()

    print(f"Wrote DB: {out_db} ({out_db.stat().st_size} bytes)")
    print(f"Quotes inserted: {len(rows)}")


if __name__ == "__main__":
    main()

