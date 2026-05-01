# Quote data (CSV)

Put your **final set** CSV here so the site can import the full catalog.

**Preferred filename:** `final-set.csv`

Alternatives the build script also checks:

- `quotes-website/data/20240118 final set.csv`
- Repo root: `20240118 final set.csv`
- Or set `CSV_PATH=/absolute/path/to/file.csv` when running sync.

**Columns:** The importer (`tools/quotes_csv_to_json.py`) auto-detects columns such as `Quote` / `Author` / `Category` / `Tags`.

Then from `quotes-website/`:

```bash
npm run sync-data
```

This writes `public/data/quotes.json` and `public/data/categories-meta.json`.
