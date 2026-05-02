# openourquotes.com + GitHub Pages (Porkbun)

Your domain lives at **Porkbun**; hosting is **free** on **GitHub Pages**, built automatically from Actions.

---

## Prerequisites

1. **Pages requires a public repo** on the Free GitHub plan (or Team/Enterprise for private). Repo: **`jobk84092/new_quotes`** → consider **Settings → General → Change visibility → Public**.
2. **Settings → Pages → Build and deployment** → Source: **GitHub Actions**.
3. **Actions variable `VITE_SITE_BASE` (optional)** — the deploy workflow now defaults to **`./`**, which works for **both** `https://www.openourquotes.com/` and `https://<user>.github.io/<repo>/` without setting anything. Only add a variable if you need an explicit **`/`** or **`/new_quotes/`**-style base.

---

## Step A — GitHub: add domain first

1. Open **https://github.com/jobk84092/new_quotes/settings/pages**
2. **Custom domain** → **`www.openourquotes.com`** (recommended) → **Save**.  
   (You can use apex only instead; **`www`** is slightly easier first.)

GitHub warns until DNS propagates—that’s OK.

---

## Step B — Porkbun DNS

1. Porkbun → **openourquotes.com** → **DNS Records** → **Edit**.
2. **Delete every `www` record** that is **not** the GitHub CNAME — especially Porkbun **parking** targets like **`uixie.porkbun.com`**. Leaving that in place causes GitHub **`InvalidCNAMEError`** (`www` must resolve to **`jobk84092.github.io`**, not Porkbun).
3. **Delete incorrect apex (`@`) records** — remove **`A`** rows that are **not** GitHub’s four IPs below (temporary registrar/parking IPs will break apex + alternate-name checks).

### Correct records (minimal set)

**Apex** (`@` / host blank) — **exactly four** **A** records:

**185.199.108.153** • **185.199.109.153** • **185.199.110.153** • **185.199.111.153**

**`www`** — **one** **CNAME** record:

| Type | Host | Answer / points to |
|------|------|-------------------|
| CNAME | **`www`** | **`jobk84092.github.io`** |

Rules GitHub cares about:

- **No `https://`**, **no trailing slash**, **no path** — only the hostname **`jobk84092.github.io`**.
- **Do not** CNAME **`www`** to **`username.github.io/new_quotes`** (invalid).
- **`www`** should **not** also have **A** records; use **CNAME** only for `www`.

(Optional: GitHub **AAAA** for apex — [Managing a custom domain](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site#configuring-an-apex-domain).)

### If GitHub shows `InvalidCNAMEError`

Public DNS currently returned **`www`** → **`uixie.porkbun.com`** instead of **`jobk84092.github.io`**. Fix: remove that CNAME, add **`www` → `jobk84092.github.io`**, wait a few minutes, click **Verify** again in GitHub Pages. Recheck locally: `dig +short www.openourquotes.com CNAME` should eventually show **`jobk84092.github.io.`**.

---

## Step C — HTTPS + deploy

Wait until GitHub Pages **checks pass**, then enable **Enforce HTTPS**.

Trigger **Actions → Deploy Open Our Quotes site → Run workflow** (after `VITE_SITE_BASE=/` is set).

Smoke test:

- `https://www.openourquotes.com/`
- `https://www.openourquotes.com/privacy.html`

---

## Earning (Ads)

Use **`https://www.openourquotes.com/`** when you submit the site to **Google AdSense**; follow **[ADSENSE_FIRST_TIME.md](ADSENSE_FIRST_TIME.md)** for secrets (`VITE_ADSENSE_*`) and **`ADSENSE_ADS_TXT_LINE`** for `ads.txt`.
