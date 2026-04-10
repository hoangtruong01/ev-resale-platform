import { relative, isAbsolute } from "pathe";

// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: "2025-07-15",
  devtools: { enabled: true },
  modules: [
    "@nuxt/eslint",
    "@nuxt/image",
    "@nuxt/ui",
    "@nuxtjs/i18n",
    "@nuxtjs/color-mode",
  ],
  css: ["~/assets/css/main.css", "~/assets/css/admin.css"],
  devServer: {
    port: 3001,
  },
  vite: {
    server: {
      proxy: {
        "/be": {
          target: "http://localhost:3000/api",
          changeOrigin: true,
          rewrite: (path) => path.replace(/^\/be/, ""),
        },
        "/uploads": {
          target: "http://localhost:3000",
          changeOrigin: true,
        },
      },
    },
  },
  runtimeConfig: {
    // Private keys (only available on server-side)
    geminiApiKey: process.env.GEMINI_API_KEY || "",

    // Public keys (exposed to client-side)
    public: {
      // Point FE API calls to Nuxt dev proxy path for the backend.
      // This avoids clashing with Nuxt server routes under `/api`.
      apiBaseUrl: process.env.NUXT_PUBLIC_API_BASE_URL || "/be",
      googleClientId: process.env.NUXT_PUBLIC_GOOGLE_CLIENT_ID || "",
    },
  },
  nitro: {
    devProxy: {
      // Proxy backend (NestJS) behind `/be` to prevent conflicts with Nuxt `/api/*` routes
      "/be": {
        target: "http://localhost:3000/api",
        changeOrigin: true,
        prependPath: true,
      },
      "/uploads": {
        target: "http://localhost:3000",
        changeOrigin: true,
        prependPath: true,
      },
    },
  },
  hooks: {
    "vite:extendConfig"(config) {
      const rootDir = config.root ?? process.cwd();
      const plugins = config.plugins ?? [];
      for (const plugin of plugins) {
        const pluginObj = plugin as any;
        if (!pluginObj || pluginObj.name !== "nuxt:components:imports") {
          continue;
        }

        const originalTransform =
          typeof pluginObj.transform === "function"
            ? pluginObj.transform.bind(pluginObj)
            : null;

        if (!originalTransform) {
          continue;
        }

        pluginObj.transform = function patchedComponentsImportTransform(
          code: string,
          id: string,
          ...args: any[]
        ) {
          if (typeof id === "string" && isAbsolute(id)) {
            const normalizedId = relative(rootDir, id).split("\\").join("/");
            return originalTransform(code, normalizedId, ...args);
          }
          return originalTransform(code, id, ...args);
        };
      }
    },
  },
  i18n: {
    strategy: "no_prefix",
    defaultLocale: "vi",
    langDir: "locales",
    lazy: false,
    detectBrowserLanguage: {
      useCookie: true,
      cookieKey: "i18n_redirected",
      redirectOn: "root",
      fallbackLocale: "vi",
    },
    locales: [
      { code: "vi", iso: "vi-VN", file: "vi.json", name: "Tiếng Việt" },
      { code: "en", iso: "en-US", file: "en.json", name: "English" },
      { code: "ja", iso: "ja-JP", file: "ja.json", name: "日本語" },
    ],
    bundle: {
      optimizeTranslationDirective: false,
    },
  },
  colorMode: {
    classSuffix: "",
    preference: "system",
    fallback: "light",
    storageKey: "nuxt-color-mode",
  },
});
