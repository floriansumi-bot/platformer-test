# 🧊 Fridge Chef

Take a photo of your fridge or pantry → AI detects your ingredients → get **3 recipes**:
one **breakfast**, one **lunch/dinner**, and one **dessert**. Installable on Android,
shareable as a web link, and it keeps working **offline** with a built-in recipe bank.

- **Frontend:** installable PWA (Vite + React + TypeScript) → deploys to **GitHub Pages**
- **AI detection:** a tiny **Cloudflare Worker** that holds one API key (**OpenAI** by default, Anthropic optional)
- **Recipes online:** [TheMealDB](https://www.themealdb.com) free API (no key), searched by your ingredients
- **Recipes offline:** bundled `app/public/recipes-databank.json`, cached by the service worker

```
 Phone/Browser ──photo──▶ Cloudflare Worker (your API key) ──▶ OpenAI/Anthropic vision
       │                                                              │
       │◀──────────── ingredient list ───────────────────────────────┘
       │
       ├─ online  ──▶ TheMealDB  ──▶ breakfast / main / dessert
       └─ offline ──▶ built-in recipe bank (service worker)
```

---

## 1. Deploy the AI backend (uses your OpenAI tokens)

The backend keeps your API key off the public site. It defaults to **OpenAI**.

```bash
cd worker
npm install
npx wrangler login                     # opens a browser, one time
npx wrangler secret put OPENAI_API_KEY # paste your OpenAI key
npx wrangler deploy
```

Wrangler prints a URL like `https://fridge-chef.<you>.workers.dev`. Test it:

```bash
curl https://fridge-chef.<you>.workers.dev
# {"ok":true,"service":"fridge-chef-detect","provider":"openai","configured":true}
```

**Model / cost:** defaults to `gpt-4o-mini` (cheap, vision-capable). Change it in
`worker/wrangler.toml` (`OPENAI_MODEL`, e.g. `gpt-4o`). Photos are downscaled to
~1024px and sent with `detail: "low"` to keep token use small.

**Prefer Anthropic instead?** In `worker/wrangler.toml` set `PROVIDER = "anthropic"`,
then `npx wrangler secret put ANTHROPIC_API_KEY` (default model `claude-opus-4-8`).

**Lock down CORS (recommended):** set `ALLOWED_ORIGIN = "https://<owner>.github.io"`
in `wrangler.toml` and redeploy, so only your site can call the backend.

> No backend yet? The app still works — it just asks you to type ingredients by hand,
> and recipes come from TheMealDB (online) or the offline bank.

## 2. Publish the web app (the link you share with Mom)

1. In GitHub: **Settings → Pages → Build and deployment → Source: GitHub Actions**.
2. (Optional, enables AI) **Settings → Secrets and variables → Actions → Variables →
   New repository variable**: name `BACKEND_URL`, value your Worker URL from step 1.
3. Push to the branch (the workflow `.github/workflows/deploy-pages.yml` runs on
   `main` and `claude/fridge-recipe-app-VKvYD`), or run it from the **Actions** tab.

Your permanent link:

```
https://<owner>.github.io/<repo>/
```

For this repo that's **https://floriansumi-bot.github.io/platformer-test/** — open it on
any device with wifi. On Android, tap the browser menu → **Add to Home screen** to
install it as a full-screen app. It updates automatically on every push.

## 3. Run locally (optional)

```bash
cd app
npm install
npm run dev        # http://localhost:5173/platformer-test/
```

To use AI locally, open **⚙️ Settings** in the app and paste your Worker URL (stored
only in your browser), or run the worker locally with `cd worker && npm run dev`.

---

## How the 3-recipe pick works

1. Each detected ingredient is searched on TheMealDB (`filter.php?i=…`).
2. Candidate meals are scored by how many of your ingredients they use.
3. The top matches are fetched in full and sorted into the three slots by
   category (Breakfast → breakfast, Dessert → dessert, everything else → main).
4. Any empty slot is filled by browsing that category; if you're offline or a
   slot is still empty, the **offline bank** fills it — so you always get 3.

## Offline behaviour

Once the PWA has been opened on wifi, the service worker caches the app shell,
icons, and the recipe bank. With no connection the app skips AI/online search,
you add ingredients by hand, and it suggests the best matches from the bank.

## Project layout

```
app/      PWA frontend (React + Vite, vite-plugin-pwa)
  public/recipes-databank.json   offline recipe bank (edit to add your own)
  public/icons/                  generated PWA icons
worker/   Cloudflare Worker AI backend (OpenAI default, Anthropic optional)
scripts/make_icons.py            regenerate the icons (needs Pillow)
.github/workflows/deploy-pages.yml   builds app/ → GitHub Pages
```
