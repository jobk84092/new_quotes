import { defineConfig, loadEnv } from "vite";

/** `./` relative (Netlify apex, previews), `/repo/` GitHub Pages project site, `/` custom domain apex. */
function viteBase(siteBaseEnv) {
  if (siteBaseEnv == null) return "./";
  const t = String(siteBaseEnv).trim();
  if (t === "" || t === "." || t === "./") return "./";
  let b = t.replace(/\\/g, "/");
  if (!b.startsWith("/")) b = `/${b}`;
  if (b !== "/" && !b.endsWith("/")) b += "/";
  return b;
}

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), "");
  const base = viteBase(env.VITE_SITE_BASE);

  return {
    base,
    build: {
      outDir: "dist",
      assetsDir: "assets",
      sourcemap: false,
    },
  };
});
