# AdSense (#4) and ads.txt (#5) — first time only

Use your **real public URL** everywhere below — prefer **`https://www.openourquotes.com/`** once DNS + SSL are live, not `github.io`. If you temporarily use **`https://jobk84092.github.io/new_quotes/`**, that only works while the repo is **public** and **`VITE_SITE_BASE`** is set for **subpath** deployment (not **`/`**). Private repo on Free tier: make repo **public** or use Cloudflare Pages/Netlify.

## 4) Google AdSense (apply + get IDs)

You need a Google account (often the same Gmail you use for developer tools).

1. Open **[google.com/adsense](https://www.google.com/adsense/)** → **Start** / Sign in.
2. When asked for your **website URL**, paste **exactly** what you publish (same as your live Pages URL above), include `https://`.
3. Google may ask you to verify ownership—GitHub-hosted sites often verify via an **HTML meta tag**: AdSense gives you a tag → add it temporarily to **`quotes-website/index.html`** inside `<head>`, push to redeploy → click verify in AdSense.
4. **Wait for review** — can be days. You cannot skip this gate.
5. After approval, **create two ad units** in AdSense (under **Ads** / **Sites** — UI changes regularly):
   - One **responsive display**-style unit (sidebar/desktop) → copy the **ad unit / slot ID** (numbers).
   - One **in-feed**, **fluid**, or **multiplex**-style unit (between content rows) → copy that slot ID.

### Put IDs into GitHub Actions secrets

Repo: **Settings → Secrets and variables → Actions → New repository secret**:

| Name | Value |
|------|--------|
| `VITE_ADSENSE_CLIENT` | `ca-pub-…………` |
| `VITE_ADSENSE_SIDEBAR` | Sidebar slot id |
| `VITE_ADSENSE_IN_ARTICLE` | In-feed / fluid slot id |

Then **Actions** → workflow **Deploy Open Our Quotes site** → **Run workflow** (or push any change).

## 5) ads.txt

1. In AdSense, open **Sites** (or Ads.txt section) → copy the line that starts with **`google.com, pub-…`** (`DIRECT, f08…` at the end).
2. Repo **Settings → Secrets → Actions → New secret** → name **`ADSENSE_ADS_TXT_LINE`** → paste that **whole line**.
3. Re-run **Deploy Open Our Quotes site**.

The deployment workflow writes `ads.txt` to your live site automatically when that secret exists.

Do not click your own ads.
