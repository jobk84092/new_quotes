# Open Our Quotes (web)

Production domain: **`openourquotes.com`** (`www` recommended for primary URL). Full **Porkbun + GitHub Pages** checklist: **[OPENOURQUOTES_GITHUB_PAGES.md](OPENOURQUOTES_GITHUB_PAGES.md)**.

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

## What is “the GitHub thing”?

**Visitors don’t have to care about GitHub.**

- GitHub holds your **code** and runs the **automatic build/deploy** pipeline.
- The **`something.github.io/...`** address is only a **default**. It is not your product name unless you choose to use it.

With **`openourquotes.com`** on GitHub Pages, visitors hit your brand URL only; **`github.io`** stays behind the curtain.

## Own your brand: buy a domain and look professional

1. **Pick and buy** a domain at any registrar (**Cloudflare**, **Porkbun**, **Namecheap**, Squarespace/Google-style registrars, etc.). Prefer **easy renewal pricing** over a cheap year-one promo. Short beats clever: **`.com`** / **`.co`** still feel most mainstream for this kind of site.

2. Add **`www.openourquotes.com`** (or apex **`openourquotes.com`**) under **Pages → Custom domain**. Point DNS at Porkbun per **[OPENOURQUOTES_GITHUB_PAGES.md](OPENOURQUOTES_GITHUB_PAGES.md)**.

3. Wait for DNS and HTTPS (GitHub issues a **free certificate**).

4. **Important:** Tell the site build to serve from **`/`**, not **`/new_quotes/`**:
   - **Settings → Secrets and variables → Actions → Variables**.
   - New variable **`VITE_SITE_BASE`** = **`/`**.
   - Re-run workflow **Deploy Open Our Quotes site** (or push a tiny commit).

5. Put **`https://www.openourquotes.com/`** everywhere in **Google AdSense** (see **[ADSENSE_FIRST_TIME.md](ADSENSE_FIRST_TIME.md)**).

Same **static folder** (`quotes-website/dist`) can ship from **Cloudflare Pages** or **Netlify** if you prefer—they’re equally professional; DNS just points elsewhere.

## Ship today — GitHub Pages + AdSense

1. Push to `main`; workflow **Deploy Open Our Quotes site** runs (or **Actions → Run workflow**).
2. Repo **Settings → Pages → Build and deployment:** set source to **GitHub Actions** once.
3. After **`VITE_SITE_BASE=/`** + DNS propagation, verify **`https://www.openourquotes.com/`** and **`privacy.html`**. Fallback before DNS: **`https://jobk84092.github.io/new_quotes/`** (only if repo is **public** and `VITE_SITE_BASE` unset for subpath builds).

**Private repo:** On the GitHub Free plan, **Pages is not enabled for private repositories.** Make this repo **public** (repo **Settings → General → Danger zone**) **or** host `quotes-website/dist` elsewhere (Cloudflare Pages, Netlify, etc.)—same assets, drag-and-drop **`dist`** works.

**AdSense (`ads.txt`, secrets, review):** step-by-step checklist with screenshots-style instructions is in **[ADSENSE_FIRST_TIME.md](ADSENSE_FIRST_TIME.md)** (includes optional secret **`ADSENSE_ADS_TXT_LINE`** instead of committing `ads.txt` by hand).

## Monetization (Google AdSense)

IDs come from **`VITE_ADSENSE_*` in `.env.local`** locally and **matching GitHub Actions secrets** in CI (see [.env.example](.env.example)). Leaving them blank keeps neutral “Advertisement” placeholders.

1. **[AdSense](https://www.google.com/adsense/)** → add site → verify → create **two** display units (sidebar rectangle + **in-feed / fluid / in-article** style for feeds).
2. Paste `ca-pub-…` and both slot IDs into `.env.local` or secrets → rebuild (`npm run build` locally, or push to trigger Actions).

**Policy:** Use only Google’s official `adsbygoogle` snippet; never click your own ads.

**Extras:** Sponsor or affiliate links below the sidebar are fine if clearly disclosed.

## Credit

Design is inspired by classic quotes sites (e.g. serif pull quotes + topic hubs); not affiliated with BrainyQuote.
