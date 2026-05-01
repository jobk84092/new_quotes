#!/usr/bin/env node
/**
 * Builds data for the quotes site:
 * - Topic shards under public/data/t/{category}/{n}.json
 * - locate.json: id → "category/shardIndex/offsetInShard"
 * - topic-manifest.json, categories-meta.json, qotd-year.json
 * - search-index.json.gz (MiniSearch, ~1 MB gzip for full corpus)
 * - Removes monolithic public/data/quotes.json (too large for browsers)
 *
 * CSV_PATH=... npm run sync-data
 */
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { gzipSync } from "node:zlib";
import MiniSearch from "minisearch";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const webRoot = path.resolve(__dirname, "..");
const repoRoot = path.resolve(webRoot, "..");
const outDir = path.join(webRoot, "public", "data");
const tempJson = path.join(outDir, "quotes.tmp.json");
const QUOTES_PER_SHARD = 500;

const csvFromEnv = process.env.CSV_PATH?.trim();
const csvCandidates = [
  csvFromEnv && path.resolve(csvFromEnv),
  path.join(webRoot, "data", "final-set.csv"),
  path.join(webRoot, "data", "20240118 final set.csv"),
  path.join(repoRoot, "20240118 final set.csv"),
].filter(Boolean);

function findCsv() {
  for (const p of csvCandidates) {
    if (fs.existsSync(p) && fs.statSync(p).size > 0) return p;
  }
  return null;
}

function formatCatLabel(id) {
  return id
    .replace(/-/g, " ")
    .replace(/\b\w/g, (c) => c.toUpperCase());
}

fs.mkdirSync(outDir, { recursive: true });

const csvPath = findCsv();
const pyScript = path.join(repoRoot, "tools", "quotes_csv_to_json.py");

if (csvPath && fs.existsSync(pyScript)) {
  console.log(`Using CSV: ${csvPath}`);
  const res = spawnSync(
    process.env.PYTHON || "python3",
    [pyScript, csvPath, tempJson],
    { stdio: "inherit", cwd: repoRoot }
  );
  if (res.status !== 0) {
    console.error("quotes_csv_to_json.py failed.");
    process.exit(res.status ?? 1);
  }
} else {
  const fallback = path.join(repoRoot, "assets", "data", "quotes.json");
  if (!fs.existsSync(fallback)) {
    console.error("No CSV found and no fallback at", fallback);
    process.exit(1);
  }
  console.warn(
    "No usable CSV — using Flutter quotes.json. Add CSV to quotes-website/data/final-set.csv for the full catalog."
  );
  fs.copyFileSync(fallback, tempJson);
}

const raw = JSON.parse(fs.readFileSync(tempJson, "utf8"));
if (!Array.isArray(raw)) {
  console.error("quotes root must be an array");
  process.exit(1);
}

const enriched = raw.map((row, i) => ({
  id: i + 1,
  text: row.text ?? row.quote ?? "",
  author: row.author ?? "Unknown",
  category: (row.category || "general").toString().trim().toLowerCase() || "general",
  tags: Array.isArray(row.tags) ? row.tags : [],
  created_at: row.created_at ?? "",
}));

fs.rmSync(path.join(outDir, "t"), { recursive: true, force: true });

const byCat = {};
for (const q of enriched) {
  (byCat[q.category] ??= []).push(q);
}

const catsSorted = Object.keys(byCat).sort();
const locate = new Array(enriched.length);
const manifest = {};

for (const cat of catsSorted) {
  const arr = byCat[cat];
  const tdir = path.join(outDir, "t", cat);
  fs.mkdirSync(tdir, { recursive: true });
  let si = 0;
  for (let i = 0; i < arr.length; i += QUOTES_PER_SHARD, si++) {
    const chunk = arr.slice(i, i + QUOTES_PER_SHARD);
    fs.writeFileSync(path.join(tdir, `${si}.json`), JSON.stringify(chunk));
    chunk.forEach((q, j) => {
      locate[q.id - 1] = `${cat}/${si}/${j}`;
    });
  }
  manifest[cat] = { shards: si, total: arr.length };
}

fs.writeFileSync(path.join(outDir, "locate.json"), JSON.stringify(locate));
console.log(`Wrote topic shards + locate.json (${enriched.length} quotes)`);

const meta = catsSorted.map((id) => ({
  id,
  label: formatCatLabel(id),
  count: byCat[id].length,
}));
meta.sort((a, b) => b.count - a.count);
fs.writeFileSync(path.join(outDir, "categories-meta.json"), JSON.stringify(meta));
fs.writeFileSync(path.join(outDir, "topic-manifest.json"), JSON.stringify(manifest));

function dofHash(doy) {
  const s = `y2026-doy${doy}`;
  let h = 2166136261;
  for (let i = 0; i < s.length; i++) {
    h = Math.imul(h ^ s.charCodeAt(i), 16777619);
  }
  return Math.abs(h >>> 0);
}

const qotdYear = [];
for (let doy = 1; doy <= 366; doy++) {
  const idx = dofHash(doy) % enriched.length;
  qotdYear.push(enriched[idx]);
}
fs.writeFileSync(path.join(outDir, "qotd-year.json"), JSON.stringify(qotdYear));
console.log("Wrote qotd-year.json (366 days)");

const ms = new MiniSearch({
  fields: ["text", "author"],
  idField: "id",
  extractField: (doc, fieldName) => (fieldName === "id" ? doc.id : doc[fieldName]),
});
for (const q of enriched) {
  ms.add({ id: q.id, text: q.text, author: q.author });
}
const searchJson = JSON.stringify(ms.toJSON());
const gz = gzipSync(Buffer.from(searchJson));
fs.writeFileSync(path.join(outDir, "search-index.json.gz"), gz);
console.log(
  `Wrote search-index.json.gz (${(gz.length / 1024 / 1024).toFixed(2)} MB gzip from ${(
    searchJson.length /
    1024 /
    1024
  ).toFixed(1)} MB index)`
);

try {
  fs.unlinkSync(tempJson);
} catch {
  /* noop */
}

try {
  fs.unlinkSync(path.join(outDir, "quotes.json"));
} catch {
  /* noop */
}

console.log("Sync complete. Monolithic quotes.json removed from public/data.");
