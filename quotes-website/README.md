# Daily Quotations (web)

A **BrainyQuote-inspired** quotes site: serif typography, topics, search, **quote of the day**, sharing to **X, Facebook, LinkedIn, WhatsApp, Reddit**, **PNG image download**, and calm **AdSense-ready** slots.

## Data pipeline

The importer uses your **final set** CSV (same column mapping as `tools/quotes_csv_to_json.py`).

1. Preferred: `quotes-website/data/final-set.csv`
2. Also checked: repo root `20240118 final set.csv`, or set `CSV_PATH=/path/to/file.csv`
3. Run:

```bash
npm install
npm run sync-data
```

This generates optimized static assets under `public/data/`:

| Output | Purpose |
|--------|---------|
| `t/{topic}/{n}.json` | Topic shards (~500 quotes each) for fast browsing |
| `locate.json` | Quote id → shard position (for deep links) |
| `qotd-year.json` | Quote of the day (366 entries, UTC calendar) |
| `search-index.json.gz` | Full-text search (~6 MB gzip — downloaded on first search only) |
| `categories-meta.json` / `topic-manifest.json` | Navigation & counts |

If no CSV is found, the script falls back to `../assets/data/quotes.json` (your Flutter sample set).

## Dev

```bash
npm run dev
```

## Production build

```bash
npm run build
```

Static output is in `dist/`.

**Site base path (`VITE_SITE_BASE`):**

- Omit or `.env.local` empty → `./` (good for Netlify apex + `vite preview`).
- **`/your-repo/`** when the URL is `https://<you>.github.io/your-repo/`.
- **`/`** for a custom domain at site root only.

Put `VITE_SITE_BASE=…` in `.env.local` (see [.env.example](.env.example)) or export it before `npm run build`.

## Ship today — GitHub Pages + AdSense

1. Push to `main`; workflow **Deploy Daily Quotations site** runs automatically, or open **Actions → Run workflow**.
2. Repo **Settings → Pages → Build and deployment:** set source to **GitHub Actions** once.
3. Visit your live URL: `https://<you>.github.io/<repo>/` (use your GitHub username + repo name). Check **Privacy**: `https://<you>.github.io/<repo>/privacy.html`.

**AdSense (`ads.txt`, secrets, review):** step-by-step checklist with screenshots-style instructions is in **[ADSENSE_FIRST_TIME.md](ADSENSE_FIRST_TIME.md)** (includes optional secret **`ADSENSE_ADS_TXT_LINE`** instead of committing `ads.txt` by hand).

(Optional) Repo **variable `VITE_SITE_BASE`** overrides the deploy base—for example **`/`** if Pages uses a custom apex domain.

## Monetization (Google AdSense)

IDs come from **`VITE_ADSENSE_*` in `.env.local`** locally and **matching GitHub Actions secrets** in CI (see [.env.example](.env.example)). Leaving them blank keeps neutral “Advertisement” placeholders.

1. **[AdSense](https://www.google.com/adsense/)** → add site → verify → create **two** display units (sidebar rectangle + **in-feed / fluid / in-article** style for feeds).
2. Paste `ca-pub-…` and both slot IDs into `.env.local` or secrets → rebuild (`npm run build` locally, or push to trigger Actions).

**Policy:** Use only Google’s official `adsbygoogle` snippet; never click your own ads.

**Extras:** Sponsor or affiliate links below the sidebar are fine if clearly disclosed.

## Credit

Design is inspired by classic quotes sites (e.g. serif pull quotes + topic hubs); not affiliated with BrainyQuote.
