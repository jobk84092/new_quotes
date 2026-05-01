# openourquotes.com + GitHub Pages (Porkbun)

Your domain lives at **Porkbun**; hosting is **free** on **GitHub Pages**, built automatically from Actions.

---

## Prerequisites

1. **Pages requires a public repo** on the Free GitHub plan (or Team/Enterprise for private). Repo: **`jobk84092/new_quotes`** → consider **Settings → General → Change visibility → Public**.
2. **Settings → Pages → Build and deployment** → Source: **GitHub Actions**.
3. **Actions variable `VITE_SITE_BASE` = `/`** (**Settings → Secrets and variables → Actions → Variables**) so CSS/JS load at `https://www.openourquotes.com/` instead of assuming `/new_quotes/`.

---

## Step A — GitHub: add domain first

1. Open **https://github.com/jobk84092/new_quotes/settings/pages**
2. **Custom domain** → **`www.openourquotes.com`** (recommended) → **Save**.  
   (You can use apex only instead; **`www`** is slightly easier first.)

GitHub warns until DNS propagates—that’s OK.

---

## Step B — Porkbun DNS

1. Porkbun → **openourquotes.com** → **DNS Records** → **Edit**.
2. Remove **`@`** / **`www`** records that point to **placeholder / parking / old hosting** only.
3. **Apex** (`@`) — four **A** rows:

**185.199.108.153** • **185.199.109.153** • **185.199.110.153** • **185.199.111.153**

(Host is usually blank or **`@`**; see Porkbun’s UI.)

4. **`www`** — **CNAME** pointing to **`jobk84092.github.io`** (**no `/new_quotes`** in the hostname).

(Optional: add GitHub **AAAA** records from [Managing a custom domain](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site#configuring-an-apex-domain) if you want IPv6.)

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
