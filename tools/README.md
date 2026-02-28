# Quote import workflow (CSV → JSON)

The app runs **offline** from `assets/data/quotes.json` and `assets/data/categories.json`.

To import your own quotes from a CSV and generate the JSON:

1. Put your CSV anywhere on disk (recommended: `assets/data/quotes.csv`).
2. Make sure the CSV has columns for at least the quote text and a category.
   - Supported header names:
     - Quote: `quote` or `text`
     - Author: `author`
     - Category: `category` (must map to one of: `love`, `motivation`, `wisdom`, `focus`, `inspiration`, `growth`)
     - Optional: `tags`, `created_at`, `is_premium`
3. Run:

```bash
python3 tools/quotes_csv_to_json.py assets/data/quotes.csv
```

Outputs:
- `assets/data/quotes.json` (used by the app)
- `tools/quotes_cleaning_report.md` (flags dropped rows + category counts + basic cleanup notes)

## Build the downloadable SQLite DB (Android premium pack)

Android can download a SQLite DB and query it via the native channel (`new_quotes/premium_db`).

Build the DB from your current JSON:

```bash
python3 tools/build_quotes_db.py
```

Output:
- `tools/out/quotes_premium.db`

Then you must host this file at a public HTTPS URL and update:
- `lib/services/premium_db_service.dart` → `defaultUrl`

