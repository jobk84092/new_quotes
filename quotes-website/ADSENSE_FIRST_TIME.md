# Google AdSense + ads.txt — checklist for Open Our Quotes

**Live site:** `https://www.openourquotes.com/`  
**Privacy:** `https://www.openourquotes.com/privacy.html`

**AdSense publisher for this website (new):** `ca-pub-9907830179614621` — same value in **`quotes-website/index.html`** (loader script) and GitHub secret **`VITE_ADSENSE_CLIENT`**. This is **only** for the **web** property; do not mix it up with **AdMob / Flutter** publisher IDs elsewhere in the repo.

---

## Before you apply

1. **HTTPS** — Browser address bar should show a **normal secure lock** for `www.openourquotes.com` (no certificate warnings). If Chrome still says **Not Secure**, finish TLS first (**Pages → Custom domain / Enforce HTTPS**) or AdSense may reject the site.
2. **Repo public** — GitHub Free needs a **public** repo for Pages from Actions (or upgrade plan).
3. **Original content + policy** — You already ship real quotes + **privacy.html**; keep both reachable.

---

## Step A — Apply to AdSense

1. Go to **[Google AdSense](https://www.google.com/adsense/)** → sign in → **Get started**.
2. **Site URL:** `https://www.openourquotes.com/` (include `https://`, trailing slash optional).
3. **Verify ownership** when prompted:
   - **AdSense code snippet** (`adsbygoogle.js?client=ca-pub-…`) — this repo keeps **one** loader in **`quotes-website/index.html`** `<head>`. The **`ca-pub-…`** there **must match** your GitHub secret **`VITE_ADSENSE_CLIENT`** when you add ads (same publisher account).
   - Or use **meta tag** / **ads.txt** if Google shows those instead — paste into **`index.html`** or the **`ADSENSE_ADS_TXT_LINE`** secret per Google’s instructions.
   - Deploy (**Actions → Deploy Open Our Quotes site**), open **`https://www.openourquotes.com/`**, then click **Verify** in AdSense.

Alternative verification: **DNS TXT** at Porkbun (Google shows instructions).

4. **Review** — Often **several days**. You cannot skip review.

---

## Step B — After approval: create ad units + wire secrets

Google’s UI moves around; you want **two units** that match how the app is coded:

| Placement | Suggested AdSense type | Maps to secret |
|-----------|------------------------|----------------|
| Sidebar | Responsive display | `VITE_ADSENSE_SIDEBAR` |
| Between content rows | In-feed / fluid / multiplex (responsive between items) | `VITE_ADSENSE_IN_ARTICLE` |

From each unit, note:

- **Publisher ID** — looks like `ca-pub-xxxxxxxxxxxxxxxx`
- **Slot / ad unit ID** — numeric **slot** id per unit

---

## Step C — GitHub Actions secrets (required for live ads)

**Repo → Settings → Secrets and variables → Actions → Secrets → New repository secret**

| Secret name | Value |
|-------------|--------|
| `VITE_ADSENSE_CLIENT` | Full publisher id, e.g. `ca-pub-xxxxxxxxxxxxxxxx` |
| `VITE_ADSENSE_SIDEBAR` | Sidebar unit **slot** id (numbers only is fine if that’s what AdSense shows) |
| `VITE_ADSENSE_IN_ARTICLE` | In-article / fluid unit **slot** id |

Then **Actions → Deploy Open Our Quotes site → Run workflow**.

Secrets are injected at **build** time (`npm run build`). Changing secrets **without** redeploy does not update the live bundle.

---

## Step D — ads.txt (strongly recommended)

1. In AdSense, find the **`ads.txt`** line for your publisher (starts with `google.com, pub-…`).
2. **Settings → Secrets → Actions → New secret**
   - Name: **`ADSENSE_ADS_TXT_LINE`**
   - Value: **paste the entire line** (single line, same as AdSense shows).
3. **Run workflow** again.

The deploy writes **`ads.txt`** into **`dist/`**, so it is served at:

**`https://www.openourquotes.com/ads.txt`**

---

## Step E — Confirm it worked

- Visit the site — sidebar / in-feed areas show **real ads** (or empty/ad placeholders until inventory fills).
- **`https://www.openourquotes.com/ads.txt`** returns **200** with your line.

---

## Policies & realism

- **Do not click your own ads** or ask others to click — policy violations risk permanent bans.
- **RPM** starts low until traffic grows; search/social help more than tweaking placement endlessly.
- **EU / UK visitors:** Google may later prompt for **consent mode / CMP** for ads personalization — follow AdSense notices when they appear.

---

## Troubleshooting

| Issue | What to check |
|-------|----------------|
| Build succeeds but no ads | Secrets missing or typo in secret **names** (must match exactly). Redeploy after adding secrets. |
| Blank boxes | Ad blockers; wait for review completion; some regions have lower fill. |
| ads.txt “Not found” | `ADSENSE_ADS_TXT_LINE` secret unset or workflow not rerun; confirm file **after** deploy at `/ads.txt`. |

For DNS/Pages/HTTPS, see **[OPENOURQUOTES_GITHUB_PAGES.md](OPENOURQUOTES_GITHUB_PAGES.md)**.
