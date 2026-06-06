import { useEffect, useState } from "react";
import { CameraCapture } from "./components/CameraCapture";
import { IngredientEditor } from "./components/IngredientEditor";
import { RecipeCard } from "./components/RecipeCard";
import { Settings } from "./components/Settings";
import { detectIngredients, fileToScaledDataUrl, NoBackendError } from "./lib/detect";
import { hasBackend } from "./lib/config";
import { buildTrio } from "./lib/recipes";
import type { RecipeTrio, Slot } from "./lib/types";

type View = "capture" | "review" | "results";
const SLOTS: Slot[] = ["breakfast", "main", "dessert"];

export default function App() {
  const [view, setView] = useState<View>("capture");
  const [preview, setPreview] = useState<string | null>(null);
  const [ingredients, setIngredients] = useState<string[]>([]);
  const [note, setNote] = useState<string | undefined>();
  const [trio, setTrio] = useState<RecipeTrio | null>(null);
  const [detecting, setDetecting] = useState(false);
  const [searching, setSearching] = useState(false);
  const [online, setOnline] = useState(navigator.onLine);
  const [showSettings, setShowSettings] = useState(false);

  useEffect(() => {
    const on = () => setOnline(true);
    const off = () => setOnline(false);
    window.addEventListener("online", on);
    window.addEventListener("offline", off);
    return () => {
      window.removeEventListener("online", on);
      window.removeEventListener("offline", off);
    };
  }, []);

  async function handlePhoto(file: File) {
    if (preview) URL.revokeObjectURL(preview);
    setPreview(URL.createObjectURL(file));
    setIngredients([]);
    setTrio(null);
    setView("review");
    setNote(undefined);

    if (!navigator.onLine) {
      setNote("You're offline — add your ingredients by hand and we'll pull recipes from the saved bank.");
      return;
    }
    if (!hasBackend()) {
      setNote("No AI backend is set up yet, so add your ingredients by hand. (You can point the app at one in Settings.)");
      return;
    }

    setDetecting(true);
    try {
      const dataUrl = await fileToScaledDataUrl(file);
      const result = await detectIngredients(dataUrl);
      setIngredients(result.ingredients);
      setNote(
        result.ingredients.length
          ? `Detected ${result.ingredients.length} item${result.ingredients.length === 1 ? "" : "s"} with AI${result.model ? ` (${result.model})` : ""}. Tap × to remove or add anything we missed.`
          : "AI didn't spot anything clearly — add your ingredients by hand.",
      );
    } catch (err) {
      if (err instanceof NoBackendError) {
        setNote("No AI backend configured — add your ingredients by hand.");
      } else {
        setNote(`Couldn't run AI detection (${(err as Error).message}). Add your ingredients by hand.`);
      }
    } finally {
      setDetecting(false);
    }
  }

  async function handleSearch() {
    setSearching(true);
    try {
      const result = await buildTrio(ingredients);
      setTrio(result);
      setView("results");
      window.scrollTo({ top: 0, behavior: "smooth" });
    } finally {
      setSearching(false);
    }
  }

  function reset() {
    if (preview) URL.revokeObjectURL(preview);
    setPreview(null);
    setIngredients([]);
    setTrio(null);
    setNote(undefined);
    setView("capture");
  }

  return (
    <div className="app">
      <header className="topbar">
        <button className="brand" onClick={reset}>
          🧊 Fridge&nbsp;Chef
        </button>
        <div className="topbar-right">
          {!online && <span className="pill offline" title="No connection">Offline</span>}
          <button className="icon-btn" aria-label="Settings" onClick={() => setShowSettings(true)}>
            ⚙️
          </button>
        </div>
      </header>

      <main className="content">
        {view === "capture" && <CameraCapture onPhoto={handlePhoto} busy={detecting} />}

        {view === "review" && (
          <div className="review">
            {preview && <img className="preview" src={preview} alt="Your kitchen" />}
            {detecting ? (
              <div className="detecting">
                <div className="spinner" />
                <p>Looking at your photo…</p>
              </div>
            ) : (
              <IngredientEditor
                ingredients={ingredients}
                onChange={setIngredients}
                onSearch={handleSearch}
                note={note}
                busy={searching}
              />
            )}
            <button className="btn ghost full" onClick={reset}>
              ↺ Start over
            </button>
          </div>
        )}

        {view === "results" && trio && (
          <div className="results">
            <h2>Your 3 recipes</h2>
            {!online && (
              <p className="muted">📴 You&apos;re offline — these come from the built-in recipe bank.</p>
            )}
            <div className="cards">
              {SLOTS.map((slot) => (
                <RecipeCard key={slot} slot={slot} recipe={trio[slot]} />
              ))}
            </div>
            <button className="btn primary big" onClick={reset}>
              📷 New photo
            </button>
          </div>
        )}
      </main>

      <footer className="footer muted small">
        Recipes from TheMealDB &amp; the built-in bank · works offline once installed
      </footer>

      {showSettings && <Settings onClose={() => setShowSettings(false)} />}
    </div>
  );
}
