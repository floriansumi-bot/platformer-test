import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { VitePWA } from "vite-plugin-pwa";

// GitHub Pages serves a project repo at https://<user>.github.io/<repo>/, so the
// app must be built with that sub-path as its base. Override with VITE_BASE for
// other hosts (e.g. a custom domain or local root).
const base = process.env.VITE_BASE ?? "/platformer-test/";

export default defineConfig({
  base,
  plugins: [
    react(),
    VitePWA({
      registerType: "autoUpdate",
      includeAssets: [
        "icons/apple-touch-icon.png",
        "icons/favicon-64.png",
        "recipes-databank.json",
      ],
      manifest: {
        name: "Fridge Chef — snap, detect, cook",
        short_name: "Fridge Chef",
        description:
          "Take a photo of your fridge or pantry, let AI detect your ingredients, and get a breakfast, a lunch/dinner and a dessert recipe. Works offline with a built-in recipe bank.",
        theme_color: "#228b6e",
        background_color: "#f5f1ea",
        display: "standalone",
        orientation: "portrait",
        start_url: ".",
        scope: ".",
        icons: [
          { src: "icons/icon-192.png", sizes: "192x192", type: "image/png" },
          { src: "icons/icon-512.png", sizes: "512x512", type: "image/png" },
          {
            src: "icons/icon-maskable-512.png",
            sizes: "512x512",
            type: "image/png",
            purpose: "maskable",
          },
        ],
      },
      workbox: {
        // Precache the app shell + the offline recipe bank so the app loads and
        // can still suggest recipes with no network at all.
        globPatterns: ["**/*.{js,css,html,png,svg,ico,json,webmanifest}"],
        navigateFallback: "index.html",
        runtimeCaching: [
          {
            // TheMealDB JSON lookups — fresh when online, cached as a fallback.
            urlPattern: /^https:\/\/www\.themealdb\.com\/api\/.*/i,
            handler: "NetworkFirst",
            options: {
              cacheName: "mealdb-api",
              networkTimeoutSeconds: 6,
              expiration: { maxEntries: 200, maxAgeSeconds: 60 * 60 * 24 * 7 },
              cacheableResponse: { statuses: [0, 200] },
            },
          },
          {
            // Recipe photos — keep them around once seen.
            urlPattern: /^https:\/\/www\.themealdb\.com\/images\/.*/i,
            handler: "CacheFirst",
            options: {
              cacheName: "mealdb-images",
              expiration: { maxEntries: 120, maxAgeSeconds: 60 * 60 * 24 * 30 },
              cacheableResponse: { statuses: [0, 200] },
            },
          },
        ],
      },
    }),
  ],
});
