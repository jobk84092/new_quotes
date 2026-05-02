import MiniSearch from "minisearch";
import {
  AD_CLIENT,
  AD_SLOT_IN_ARTICLE,
  AD_SLOT_SIDEBAR,
  canonicalQuoteUrl,
} from "./config.js";

/** Same options as `scripts/sync-quotes.mjs` — required for `MiniSearch.loadJSON`. */
const MINISEARCH_LOAD_OPTIONS = {
  fields: ["text", "author"],
  idField: "id",
  extractField: (doc, fieldName) => (fieldName === "id" ? doc.id : doc[fieldName]),
};

const PAGE_SIZE = 12;
const AD_EVERY = 6;
/** MiniSearch can return many hits; cap list length for sanity (still covers large catalogs). */
const MAX_SEARCH_RESULTS = 250000;
let categories = [];
let locateArr = null;
let manifest = null;
let searchMini = null;
const shardCache = new Map();
let adsInit = false;

/**
 * Vite `base`: `./` (portable), `/` (custom domain), `/repo/` (project Pages path).
 * Normalized so relative links never become `.//…`.
 */
function assetBase() {
  const raw = import.meta.env.BASE_URL ?? "/";
  const b = typeof raw === "string" ? raw.trim() : "/";
  if (b === "." || b === "./") return "./";
  return b.endsWith("/") ? b : `${b}/`;
}

let memoDataRoot = null;

/**
 * Absolute base URL for `/public/data/*` on the **same host as the HTML document**.
 * Uses `location` (hash router keeps pathname at site root) so it matches GitHub Pages for both
 * `www.openourquotes.com` and `github.io/repo/` without depending on `import.meta.url`.
 */
function dataSiteRoot() {
  if (memoDataRoot) return memoDataRoot;
  if (typeof window !== "undefined") {
    const page = window.location.href.split("#")[0];
    memoDataRoot = new URL("./", page).href;
    return memoDataRoot;
  }
  try {
    const u = new URL(import.meta.url);
    const path = u.pathname;
    const i = path.lastIndexOf("/assets/");
    if (i !== -1) {
      const rootPath = path.slice(0, i) || "/";
      memoDataRoot =
        rootPath === "/" ? `${u.origin}/` : `${u.origin}${rootPath.endsWith("/") ? rootPath : `${rootPath}/`}`;
      return memoDataRoot;
    }
  } catch {
    /* fall through */
  }
  const b = assetBase();
  const fallbackPage = "http://localhost/";
  if (b === "." || b === "./") {
    memoDataRoot = new URL("./", fallbackPage).href.replace(/\/?$/, "/");
  } else if (b.startsWith("/")) {
    memoDataRoot = `http://localhost${b.endsWith("/") ? b : `${b}/`}`;
  } else {
    memoDataRoot = new URL(b, fallbackPage).href.replace(/\/?$/, "/");
  }
  return memoDataRoot;
}

function dataFetch(path) {
  const rel = path.replace(/^\//, "");
  return fetch(new URL(rel, dataSiteRoot()));
}

export function mount(el) {
  if (!el) return;
  hashRoute();
  window.addEventListener("hashchange", hashRoute);
}

async function decompressGzipBlob(blob) {
  const ds = new DecompressionStream("gzip");
  const stream = blob.stream().pipeThrough(ds);
  return new Response(stream).text();
}

async function ensureLocate() {
  if (locateArr) return;
  const res = await dataFetch("data/locate.json");
  if (!res.ok) throw new Error("locate fetch failed");
  locateArr = await res.json();
}

async function ensureManifest() {
  if (manifest) return;
  const res = await dataFetch("data/topic-manifest.json");
  if (!res.ok) throw new Error("manifest fetch failed");
  manifest = await res.json();
}

async function fetchShard(cat, si) {
  const key = `${cat}/${si}`;
  if (shardCache.has(key)) return shardCache.get(key);
  const res = await dataFetch(`data/t/${cat}/${si}.json`);
  if (!res.ok) throw new Error(`shard ${key}`);
  const arr = await res.json();
  shardCache.set(key, arr);
  return arr;
}

async function getQuoteById(id) {
  await ensureLocate();
  const spec = locateArr[id - 1];
  if (!spec) return null;
  const parts = spec.split("/");
  const cat = parts[0];
  const si = parts[1];
  const j = parseInt(parts[2], 10);
  const shard = await fetchShard(cat, si);
  return shard[j] ?? null;
}

async function getTopicQuotesSlice(cat, start, limit) {
  await ensureManifest();
  const info = manifest[cat];
  if (!info) return [];

  let skip = Math.max(0, start);
  const acc = [];
  for (let si = 0; si < info.shards && acc.length < limit; si++) {
    const shard = await fetchShard(cat, String(si));
    if (skip >= shard.length) {
      skip -= shard.length;
      continue;
    }
    for (let j = skip; j < shard.length && acc.length < limit; j++) {
      acc.push(shard[j]);
    }
    skip = 0;
  }
  return acc;
}

async function loadCategoriesMeta() {
  const res = await dataFetch("data/categories-meta.json");
  if (!res.ok) throw new Error("categories meta");
  categories = await res.json();
}

async function loadQotd() {
  const res = await dataFetch("data/qotd-year.json");
  if (!res.ok) throw new Error("qotd");
  const arr = await res.json();
  const doy = utcDayOfYear(new Date());
  const idx = Math.min(Math.max(doy, 1), 366) - 1;
  return arr[idx] ?? arr[0] ?? null;
}

function utcDayOfYear(d) {
  const y = d.getUTCFullYear();
  const start = Date.UTC(y, 0, 0);
  const cur = Date.UTC(y, d.getUTCMonth(), d.getUTCDate());
  return Math.floor((cur - start) / 86400000);
}

async function ensureSearchIndex() {
  if (searchMini) return searchMini;
  const res = await dataFetch("data/search-index.json.gz");
  if (!res.ok) throw new Error("search index fetch failed");
  const jsonString = await decompressGzipBlob(await res.blob());
  searchMini = MiniSearch.loadJSON(jsonString, MINISEARCH_LOAD_OPTIONS);
  return searchMini;
}

async function hydrateIds(ids) {
  await ensureLocate();
  const byShard = {};
  for (const id of ids) {
    const spec = locateArr[id - 1];
    if (!spec) continue;
    const [cat, si, jRaw] = spec.split("/");
    const key = `${cat}/${si}`;
    (byShard[key] ||= []).push({ id, j: parseInt(jRaw, 10) });
  }
  const map = {};
  await Promise.all(
    Object.keys(byShard).map(async (key) => {
      const [cat, si] = key.split("/");
      const shard = await fetchShard(cat, si);
      for (const { id, j } of byShard[key]) {
        if (shard[j]) map[id] = shard[j];
      }
    })
  );
  return ids.map((id) => map[id]).filter(Boolean);
}

function parseHashParts() {
  const raw = window.location.hash.slice(1) || "/";
  const qidx = raw.indexOf("?");
  const pathPart = (qidx >= 0 ? raw.slice(0, qidx) : raw) || "/";
  const qsPart = qidx >= 0 ? raw.slice(qidx + 1) : "";
  const parts = pathPart.split("/").filter(Boolean);
  const params = new URLSearchParams(qsPart);
  return {
    path: `/${parts.join("/")}` || "/",
    parts,
    q: params.get("q") || "",
    page: parseInt(params.get("page") || "1", 10),
  };
}

function readZeroBasedPage(p) {
  const n = Number.isFinite(p) ? p : 1;
  return Math.max(0, n - 1);
}

/** Preserve MiniSearch relevance order; dedupe document ids. */
function orderedIdsFromHits(hits, max = MAX_SEARCH_RESULTS) {
  const seen = new Set();
  const ids = [];
  for (const h of hits) {
    const id = Number(h.id);
    if (!Number.isFinite(id) || seen.has(id)) continue;
    seen.add(id);
    ids.push(id);
    if (ids.length >= max) break;
  }
  return ids;
}

async function prefetchCore() {
  await Promise.all([loadCategoriesMeta(), ensureManifest(), ensureLocate()]);
}

function hashRoute() {
  const root = document.getElementById("app");
  renderShell(root, async (main, side) => {
    main.innerHTML = `<p class="empty-hint">Loading quotations…</p>`;
    const { path, parts, q, page } = parseHashParts();
    try {
      await prefetchCore();
    } catch (err) {
      console.error("Open Our Quotes: catalog fetch failed", err);
      main.innerHTML =
        `<div class="hero"><p class="empty-hint">Could not load quote data. If you develop locally, run <code>npm run sync-data</code> in <code>quotes-website/</code>. On the live site, hard-refresh or open the console for the network error.</p></div>`;
      return;
    }
    try {
      initAdsOnce();
      if (path === "/" || path === "") await renderHome(main, side);
      else if (parts[0] === "topics") renderTopicIndex(main, side);
      else if (parts[0] === "topic" && parts[1])
        await renderTopic(main, side, decodeURIComponent(parts[1]), readZeroBasedPage(page));
      else if (parts[0] === "search") await renderSearch(main, side, q, readZeroBasedPage(page));
      else if (parts[0] === "quote" && parts[1]) await renderQuoteDetail(main, side, parseInt(parts[1], 10));
      else main.innerHTML = `<p class="empty-hint">Not found. <a href="#/">Home</a></p>`;

      renderAdSlots();
      flushAdsSoon();
    } catch (err) {
      console.error("Open Our Quotes: page failed", err);
      main.innerHTML =
        `<div class="hero"><p class="empty-hint">Something went wrong loading this page. Check the browser console. <a href="#/">Home</a></p></div>`;
    }
  });
}

function renderShell(root, inner) {
  root.innerHTML = `
    <header class="site-header">
      <div class="header-inner">
        <div class="brand">
          <a href="#/"><span class="brand-tag">Inspiration</span>Open Our Quotes</a>
        </div>
        <nav class="nav-main" aria-label="Main">
          <a href="#/">Today</a>
          <a href="#/topics">Topics</a>
          <a href="#/search">Search</a>
          <a href="${assetBase()}privacy.html">Privacy</a>
        </nav>
      </div>
    </header>
    <div class="layout">
      <main class="main-col" id="main-slot"></main>
      <aside class="ad-sidebar" id="side-slot" aria-label="Sponsored"></aside>
    </div>`;

  Promise.resolve(inner(root.querySelector("#main-slot"), root.querySelector("#side-slot"))).catch(
    () => {}
  );
}

function sidebarAdMarkup() {
  if (!AD_CLIENT || !AD_SLOT_SIDEBAR) {
    return `<div class="ad-wrap" aria-hidden="true">
      <span class="ad-label">Advertisement</span>
      <span style="font-size:0.85rem;color:var(--muted);max-width:16rem;">Set <code>VITE_ADSENSE_*</code> in <code>.env.local</code> or GitHub Actions secrets, then rebuild.</span>
    </div>`;
  }
  return `<div class="ad-wrap">
    <span class="ad-label">Advertisement</span>
    <ins class="adsbygoogle" style="display:block" data-ad-client="${AD_CLIENT}" data-ad-slot="${AD_SLOT_SIDEBAR}" data-ad-format="auto" data-full-width-responsive="true"></ins>
  </div>`;
}

async function renderHome(main, side) {
  side.innerHTML = sidebarAdMarkup();
  const quote = await loadQotd();
  main.innerHTML = `
    <section class="home-topics-panel" aria-labelledby="home-topics-heading">
      <div class="home-topics-panel__head">
        <h2 class="home-topics-panel__title" id="home-topics-heading">Browse by topic</h2>
        <p class="home-topics-panel__sub">Jump into a theme — love, wisdom, nature, and more.</p>
      </div>
      <div class="topic-chips topic-chips--prominent">
        ${categories
          .slice(0, 18)
          .map(
            (c) =>
              `<span class="chip chip--prominent"><a href="#/topic/${encodeURIComponent(c.id)}">${escapeHtml(c.label)} <span class="chip-count">${c.count}</span></a></span>`
          )
          .join("")}
        <span class="chip chip--prominent chip--all"><a href="#/topics">All topics →</a></span>
      </div>
    </section>
    <article class="hero hero--qotd" aria-labelledby="qotd-title">
      <p class="hero-label" id="qotd-title">Quote of the day</p>
      ${quote ? quoteBlockLarge(quote) : "<p>No quotes.</p>"}
    </article>
    <div class="ad-wrap ad-in-article" data-ad-inarticle="1"></div>`;
  bindQuoteActions(main);
}

function renderTopicIndex(main, side) {
  side.innerHTML = sidebarAdMarkup();
  main.innerHTML = `
    <h1 class="section-title">Topics</h1>
    <div class="topic-chips">${categories
      .map(
        (c) =>
          `<span class="chip"><a href="#/topic/${encodeURIComponent(c.id)}">${escapeHtml(c.label)} (${c.count})</a></span>`
      )
      .join("")}</div>`;
}

async function renderTopic(main, side, topicId, pageZero) {
  await ensureManifest();
  const info = manifest[topicId];
  side.innerHTML = sidebarAdMarkup();
  if (!info) {
    main.innerHTML = `<p class="empty-hint">Unknown topic. <a href="#/topics">Topics</a></p>`;
    return;
  }
  const label = categories.find((c) => c.id === topicId)?.label || formatTopicLabel(topicId);
  const start = pageZero * PAGE_SIZE;
  const slice = await getTopicQuotesSlice(topicId, start, PAGE_SIZE);
  const base = `#/topic/${encodeURIComponent(topicId)}`;
  const totalPages = Math.max(1, Math.ceil(info.total / PAGE_SIZE));

  main.innerHTML = `
    <div class="hero" style="margin-bottom:1rem;padding:1rem 1.1rem;">
      <h1 class="section-title" style="margin:0 0 0.25rem;">${escapeHtml(label)}</h1>
      <p style="margin:0;color:var(--muted);font-size:0.95rem;">${info.total} quotation${info.total === 1 ? "" : "s"} · <a href="#/topics">All topics</a></p>
    </div>
    <div class="quote-list" id="topic-list"></div>
    ${paginationControls(pageZero, totalPages, base)}`;
  fillQuoteList(main.querySelector("#topic-list"), slice, start);
  bindQuoteActions(main);
}

async function renderSearch(main, side, initialQ, pageZero) {
  side.innerHTML = sidebarAdMarkup();
  const q = initialQ || "";
  main.innerHTML = `
    <h1 class="section-title">Search</h1>
    <form class="search-bar" id="search-form">
      <input type="search" name="q" placeholder="Quotes and authors across the catalog…" value="${escapeHtml(q)}" autocomplete="off" />
      <button type="submit" class="btn btn-accent">Search</button>
    </form>
    <p style="font-size:0.88rem;color:var(--muted);margin:0 0 1rem;">Searches the <strong>full quote catalog</strong> (offline index, same technology as many sites — not Google.com). First search downloads ~6&nbsp;MB once, then it’s cached.</p>
    <div id="search-results"></div>`;

  main.querySelector("#search-form").addEventListener("submit", (e) => {
    e.preventDefault();
    const nv = main.querySelector('input[name="q"]').value.trim();
    window.location.hash = `#/search?q=${encodeURIComponent(nv)}`;
  });

  const out = main.querySelector("#search-results");
  if (!q.trim()) {
    out.innerHTML = `<p class="empty-hint">Try love, Plato, grief, sunrise…</p>`;
    return;
  }

  const ms = await ensureSearchIndex();
  const rawQ = q.trim();
  const ql = rawQ.toLowerCase();
  let hits = ms.search(ql, { prefix: true, fuzzy: 0.12 });
  if (!hits.length) hits = ms.search(rawQ, { prefix: false, fuzzy: 0.22 });
  if (!hits.length && rawQ.includes(" ")) {
    try {
      hits = ms.search(ql, { prefix: true, fuzzy: 0.18, combineWith: "AND" });
    } catch {
      hits = [];
    }
  }

  const idsAll = orderedIdsFromHits(hits);
  const hitCapReached = hits.length > 0 && idsAll.length >= MAX_SEARCH_RESULTS;
  const total = idsAll.length;
  const tp = total ? Math.ceil(total / PAGE_SIZE) : 1;
  const pz = total ? Math.min(pageZero, Math.max(0, tp - 1)) : 0;
  const pageIds = idsAll.slice(pz * PAGE_SIZE, pz * PAGE_SIZE + PAGE_SIZE);
  const rows = await hydrateIds(pageIds);

  const base = `#/search?q=${encodeURIComponent(q)}`;

  const intro =
    total === 0
      ? `<p style="color:var(--muted);">No hits for “${escapeHtml(q)}”. Try broader words.</p>`
      : `<p style="color:var(--muted);margin-bottom:1rem;">Showing ${pz * PAGE_SIZE + 1}–${Math.min((pz + 1) * PAGE_SIZE, total)} of ${total.toLocaleString()} match${total === 1 ? "" : "es"}.${
          hitCapReached
            ? ` <span style="opacity:0.9">(List capped at ${MAX_SEARCH_RESULTS.toLocaleString()} — refine your search.)</span>`
            : ""
        }</p>`;

  out.innerHTML = `
    ${intro}
    <div class="quote-list" id="search-list"></div>
    ${total > PAGE_SIZE ? paginationControls(pz, tp, base) : ""}`;

  if (total) {
    fillQuoteList(out.querySelector("#search-list"), rows, pz * PAGE_SIZE);
    bindQuoteActions(out);
  }
}

async function renderQuoteDetail(main, side, id) {
  side.innerHTML = sidebarAdMarkup();
  const qi = await getQuoteById(id);
  if (!qi) {
    main.innerHTML = `<p class="empty-hint">Quote not found. <a href="#/">Home</a></p>`;
    return;
  }
  await loadCategoriesMeta();
  const topic = categories.find((c) => c.id === qi.category);
  main.innerHTML = `
    <article class="hero">
      <p style="margin:0 0 0.5rem;"><a href="#/topic/${encodeURIComponent(qi.category)}">← ${escapeHtml(topic?.label || formatTopicLabel(qi.category))}</a></p>
      ${quoteBlockLarge(qi)}
      <p style="margin-top:1rem;"><a href="#" data-dl="${qi.id}" class="btn btn-accent">Download quote image</a></p>
    </article>
    <div class="ad-wrap ad-in-article" data-ad-inarticle="1"></div>`;
  bindQuoteActions(main);
}

function quoteBlockLarge(q) {
  const url = canonicalQuoteUrl(q.id);
  return `
    <blockquote class="quote-display" cite="${escapeAttr(url)}">
      <p class="quote-text"><span class="quote-dash">“</span>${escapeHtml(q.text)}<span class="quote-dash">”</span></p>
      <footer class="quote-meta">— ${escapeHtml(q.author)}</footer>
    </blockquote>
    ${toolRow(q)}`;
}

function toolRow(q) {
  const url = canonicalQuoteUrl(q.id);
  return `
    <div class="tool-row" data-quote-tools>
      <span class="share-label">Share</span>
      <button type="button" class="btn icon-btn" data-share="x">X / Twitter</button>
      <button type="button" class="btn icon-btn" data-share="fb">Facebook</button>
      <button type="button" class="btn icon-btn" data-share="li">LinkedIn</button>
      <button type="button" class="btn icon-btn" data-share="wa">WhatsApp</button>
      <button type="button" class="btn icon-btn" data-share="reddit">Reddit</button>
      <button type="button" class="btn icon-btn" data-share="copy">Copy link</button>
      <span class="download-image-group" role="group" aria-label="Download quote as image">
        <button type="button" class="btn btn-accent" data-action="download-image" data-format="og">Facebook / X · 1200×630</button>
        <button type="button" class="btn" data-action="download-image" data-format="igSquare">Instagram · 1080×1080</button>
        <button type="button" class="btn" data-action="download-image" data-format="igPortrait">Instagram · 1080×1350</button>
      </span>
      <input type="hidden" data-field="text" value="${escapeAttr(q.text)}" />
      <input type="hidden" data-field="author" value="${escapeAttr(q.author)}" />
      <input type="hidden" data-field="url" value="${escapeAttr(url)}" />
    </div>`;
}

function bindQuoteActions(scope) {
  scope.querySelectorAll("[data-quote-tools]").forEach((row) => {
    row.querySelectorAll("[data-share]").forEach((btn) => {
      btn.addEventListener("click", () =>
        openShare(
          btn.getAttribute("data-share"),
          row.querySelector('[data-field="text"]').value,
          row.querySelector('[data-field="author"]').value,
          row.querySelector('[data-field="url"]').value
        )
      );
    });
    row.querySelectorAll('[data-action="download-image"]').forEach((btn) => {
      btn.addEventListener("click", () =>
        downloadQuotePng(
          row.querySelector('[data-field="text"]').value,
          row.querySelector('[data-field="author"]').value,
          btn.getAttribute("data-format") || "og"
        )
      );
    });
  });
  scope.querySelectorAll("[data-dl]").forEach((lnk) => {
    lnk.addEventListener("click", async (ev) => {
      ev.preventDefault();
      const id = parseInt(lnk.getAttribute("data-dl"), 10);
      const qi = await getQuoteById(id);
      if (qi) await downloadQuotePng(qi.text, qi.author, "og");
    });
  });
}

function openShare(kind, text, author, url) {
  const short = text.length > 220 ? `${text.slice(0, 217)}…` : text;
  const body = `“${short}” — ${author}`;
  const encUrl = encodeURIComponent(url);

  const map = {
    x: `https://twitter.com/intent/tweet?text=${encodeURIComponent(`${body}\n\n${url}`)}`,
    fb: `https://www.facebook.com/sharer/sharer.php?u=${encUrl}`,
    li: `https://www.linkedin.com/sharing/share-offsite/?url=${encUrl}`,
    wa: `https://wa.me/?text=${encodeURIComponent(`${body}\n\n${url}`)}`,
    reddit: `https://www.reddit.com/submit?url=${encUrl}&title=${encodeURIComponent(body)}`,
  };

  if (kind === "copy") {
    navigator.clipboard.writeText(url).then(
      () => alert("Link copied."),
      () => prompt("Copy this link:", url)
    );
    return;
  }
  const target = map[kind];
  if (target) window.open(target, "_blank", "noopener,noreferrer,width=600,height=520");
}

/** Facebook / LinkedIn OG, X summary card · IG square · IG 4:5 portrait */
const IMAGE_PRESETS = {
  og: { w: 1200, h: 630, slug: "facebook-x-1200x630" },
  igSquare: { w: 1080, h: 1080, slug: "instagram-square-1080" },
  igPortrait: { w: 1080, h: 1350, slug: "instagram-portrait-1080x1350" },
};

async function downloadQuotePng(text, author, format = "og") {
  const preset = IMAGE_PRESETS[format] || IMAGE_PRESETS.og;
  await document.fonts?.load?.('italic 52px "Cormorant Garamond"', '"Aa"').catch(() => {});

  const canvas = document.createElement("canvas");
  canvas.width = preset.w;
  canvas.height = preset.h;
  const ctx = canvas.getContext("2d");
  paintQuoteGraphic(ctx, preset.w, preset.h, text, author);

  const blob = await new Promise((resolve) => canvas.toBlob(resolve, "image/png", 0.92));
  const a = document.createElement("a");
  const safeAuthor = author.replace(/[^\w\s-]/g, "").slice(0, 24).replace(/\s+/g, "-").toLowerCase();
  a.download = `openourquotes-${preset.slug}-${safeAuthor || "quote"}.png`;
  a.href = URL.createObjectURL(blob);
  a.click();
  URL.revokeObjectURL(a.href);
}

function paintQuoteGraphic(ctx, w, h, text, author) {
  const lg = ctx.createLinearGradient(0, 0, w, h * 1.05);
  lg.addColorStop(0, "#132822");
  lg.addColorStop(0.5, "#1a332d");
  lg.addColorStop(1, "#0c221c");
  ctx.fillStyle = lg;
  ctx.fillRect(0, 0, w, h);

  const vignette = ctx.createRadialGradient(w * 0.5, h * 0.35, 0, w * 0.5, h * 0.4, Math.max(w, h) * 0.85);
  vignette.addColorStop(0, "rgba(255,255,255,0.09)");
  vignette.addColorStop(0.55, "rgba(255,255,255,0.02)");
  vignette.addColorStop(1, "rgba(0,0,0,0.22)");
  ctx.fillStyle = vignette;
  ctx.fillRect(0, 0, w, h);

  const inset = Math.round(Math.min(w, h) * 0.045);
  ctx.strokeStyle = "rgba(214, 176, 96, 0.42)";
  ctx.lineWidth = Math.max(1, Math.round(Math.min(w, h) / 420));
  ctx.strokeRect(inset + 0.5, inset + 0.5, w - inset * 2 - 1, h - inset * 2 - 1);

  const deco = Math.min(w, h) * 0.14;
  ctx.fillStyle = "rgba(255,255,255,0.07)";
  ctx.font = `italic ${deco}px Cormorant Garamond, Georgia, serif`;
  ctx.textAlign = "left";
  ctx.fillText("\u201c", inset * 1.05, inset + deco * 0.92);

  let quotePx = Math.round(52 * (Math.min(w, h) / 1080));
  if (h <= 680) quotePx = Math.min(quotePx, 34);
  if (text.length > 180) quotePx = Math.round(quotePx * 0.92);
  if (text.length > 300) quotePx = Math.round(quotePx * 0.88);
  if (text.length > 420) quotePx = Math.round(quotePx * 0.82);
  quotePx = Math.max(22, Math.min(56, quotePx));

  const padX = Math.round(w * 0.085);
  const maxW = w - padX * 2;
  const lh = quotePx * 1.36;
  const startY = Math.round(h * (h > w * 1.1 ? 0.26 : h < 700 ? 0.29 : 0.34));

  ctx.fillStyle = "#faf9f6";
  ctx.textAlign = "center";
  ctx.font = `italic ${quotePx}px Cormorant Garamond, Georgia, serif`;
  const bodyBottom = drawWrappedText(ctx, text, w / 2, startY, maxW, lh);

  const authorSize = Math.round(quotePx * 0.52);
  const padBottom = Math.round(Math.min(w, h) * 0.07);
  let authorY = bodyBottom + quotePx * 0.65;
  authorY = Math.min(authorY, h - padBottom - authorSize * 2.4);

  ctx.font = `600 ${authorSize}px "Source Sans 3", system-ui, sans-serif`;
  ctx.fillStyle = "rgba(250,249,246,0.9)";
  ctx.fillText(`\u2014 ${author}`, w / 2, authorY);

  const brand = Math.round(quotePx * 0.36);
  ctx.font = `600 ${brand}px "Source Sans 3", system-ui, sans-serif`;
  ctx.fillStyle = "rgba(250,249,246,0.4)";
  ctx.fillText("Open Our Quotes", w / 2, h - padBottom);
}

/** Returns y position just below the last line of text. */
function drawWrappedText(ctx, text, cx, startY, maxWidth, lineHeight) {
  const words = text.split(/\s+/);
  let line = "";
  let y = startY;
  for (let n = 0; n < words.length; n++) {
    const test = line + words[n] + " ";
    if (ctx.measureText(test).width > maxWidth && n > 0) {
      ctx.fillText(line.trim(), cx, y);
      line = `${words[n]} `;
      y += lineHeight;
    } else line = test;
  }
  ctx.fillText(line.trim(), cx, y);
  return y + lineHeight;
}

function fillQuoteList(container, rows, startIndex) {
  if (!container) return;
  let html = "";
  rows.forEach((q, i) => {
    const globalI = startIndex + i;
    if (i > 0 && globalI % AD_EVERY === 0) {
      html += `<div class="ad-wrap ad-in-article" data-ad-inarticle="slot"></div>`;
    }
    html += `
      <article class="quote-card">
        <div class="quote-card-body">
          <blockquote class="quote-card-text"><a href="#/quote/${q.id}" style="color:inherit;text-decoration:none;">“${escapeHtml(q.text)}”</a></blockquote>
          <div class="quote-card-author">${escapeHtml(q.author)} · <a href="#/topic/${encodeURIComponent(q.category)}">${escapeHtml(formatTopicLabel(q.category))}</a></div>
          <div class="quote-card-foot" style="border-top:1px solid var(--border);padding-top:0.6rem;">
            ${toolRow(q).replace('class="share-label"', 'class="share-label" style="display:none"')}
          </div>
        </div>
      </article>`;
  });
  container.innerHTML = html || `<p class="empty-hint">No quotes found.</p>`;
  bindQuoteActions(container);
}

function paginationControls(pageZero, totalPages, baseHash) {
  if (totalPages <= 1) return "";
  const cur = pageZero + 1;
  const sep = baseHash.includes("?") ? "&" : "?";
  const prev =
    cur > 1
      ? `<a class="btn" href="${baseHash}${sep}page=${cur - 1}">« Prev</a>`
      : `<span class="btn" style="opacity:0.5;pointer-events:none;">« Prev</span>`;
  const next =
    cur < totalPages
      ? `<a class="btn" href="${baseHash}${sep}page=${cur + 1}">Next »</a>`
      : `<span class="btn" style="opacity:0.5;pointer-events:none;">Next »</span>`;
  return `<div class="pagination">${prev}<span>Page ${cur} of ${totalPages}</span>${next}</div>`;
}

function formatTopicLabel(id) {
  return id.replace(/-/g, " ").replace(/\b\w/g, (c) => c.toUpperCase());
}

function escapeHtml(s) {
  return String(s)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function escapeAttr(s) {
  return escapeHtml(s).replace(/'/g, "&#39;");
}

function initAdsOnce() {
  if (adsInit || !AD_CLIENT) return;
  adsInit = true;
  const s = document.createElement("script");
  s.async = true;
  s.crossOrigin = "anonymous";
  s.src = `https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=${AD_CLIENT}`;
  s.onload = () => flushAds();
  document.head.appendChild(s);
}

function flushAdsSoon() {
  queueMicrotask(() => flushAds());
}

/** One adsbygoogle push per new placement; survives SPA navigations without double-filling removed nodes. */
function flushAds() {
  if (!AD_CLIENT || !window.adsbygoogle) return;
  document.querySelectorAll("ins.adsbygoogle").forEach((el) => {
    if (el.dataset.adFilled === "1") return;
    el.dataset.adFilled = "1";
    try {
      (window.adsbygoogle = window.adsbygoogle || []).push({});
    } catch (_) {}
  });
}

function renderAdSlots() {
  if (!AD_CLIENT || !AD_SLOT_IN_ARTICLE) return;
  document.querySelectorAll("[data-ad-inarticle]").forEach((el) => {
    if (el.querySelector("ins.adsbygoogle")) return;
    el.innerHTML = `
      <span class="ad-label">Advertisement</span>
      <ins class="adsbygoogle" style="display:block;text-align:center" data-ad-layout="in-article" data-ad-format="fluid" data-ad-client="${AD_CLIENT}" data-ad-slot="${AD_SLOT_IN_ARTICLE}"></ins>`;
  });
}
