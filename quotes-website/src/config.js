/** Trimmed publisher id and slot IDs from `.env.local` / GitHub Secrets at build time. */
export const AD_CLIENT = trimEnv(import.meta.env.VITE_ADSENSE_CLIENT);

export const AD_SLOT_SIDEBAR = trimEnv(import.meta.env.VITE_ADSENSE_SIDEBAR);

export const AD_SLOT_IN_ARTICLE = trimEnv(import.meta.env.VITE_ADSENSE_IN_ARTICLE);

/** Normalizes quoted secret strings from GitHub Actions into plain text. */
export function trimEnv(value) {
  if (value == null || typeof value !== "string") return "";
  return value.replace(/^"|"$/g, "").trim();
}

export function canonicalQuoteUrl(id) {
  if (typeof location === "undefined") return `#/quote/${id}`;
  try {
    const u = new URL(location.href.split("#")[0] || location.href);
    u.hash = `#/quote/${id}`;
    return u.href;
  } catch {
    return `#/quote/${id}`;
  }
}
