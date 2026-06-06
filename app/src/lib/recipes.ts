import type { Recipe, RecipeTrio, Slot } from "./types";
import { pickFromDatabank } from "./databank";

const MEALDB = "https://www.themealdb.com/api/json/v1/1";

// Cap how many ingredient queries / detail lookups we fan out, to keep the
// free API happy and the UI fast.
const MAX_INGREDIENT_QUERIES = 8;
const MAX_DETAIL_LOOKUPS = 14;

interface MealSummary {
  idMeal: string;
  strMeal: string;
  strMealThumb: string;
}

async function fetchJson<T>(url: string, signal?: AbortSignal): Promise<T> {
  const res = await fetch(url, { signal });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return (await res.json()) as T;
}

function slotForCategory(category: string): Slot {
  const c = category.toLowerCase();
  if (c === "breakfast") return "breakfast";
  if (c === "dessert") return "dessert";
  return "main";
}

/** Turn a raw TheMealDB meal-detail object into our Recipe shape. */
function mealToRecipe(meal: Record<string, string>, have: string[]): Recipe {
  const ingredients: string[] = [];
  for (let i = 1; i <= 20; i++) {
    const name = (meal[`strIngredient${i}`] || "").trim();
    const measure = (meal[`strMeasure${i}`] || "").trim();
    if (name) ingredients.push(measure ? `${measure} ${name}`.trim() : name);
  }

  const steps = (meal.strInstructions || "")
    .split(/\r?\n+/)
    .map((s) => s.trim())
    .filter((s) => s.length > 0);

  const haveSet = have.map((h) => h.toLowerCase());
  const matched = haveSet.filter((h) =>
    ingredients.some((ing) => ing.toLowerCase().includes(h)),
  );

  return {
    id: `mealdb-${meal.idMeal}`,
    title: meal.strMeal,
    slot: slotForCategory(meal.strCategory || ""),
    area: meal.strArea || undefined,
    category: meal.strCategory || undefined,
    image: meal.strMealThumb || undefined,
    ingredients,
    steps: steps.length ? steps : ["See the full method at the source link below."],
    source: "TheMealDB",
    sourceUrl: meal.strSource || meal.strYoutube || undefined,
    matched: Array.from(new Set(matched)),
    offline: false,
  };
}

async function lookupMeal(id: string, have: string[], signal?: AbortSignal): Promise<Recipe | null> {
  try {
    const data = await fetchJson<{ meals: Record<string, string>[] | null }>(
      `${MEALDB}/lookup.php?i=${encodeURIComponent(id)}`,
      signal,
    );
    const meal = data.meals?.[0];
    return meal ? mealToRecipe(meal, have) : null;
  } catch {
    return null;
  }
}

/** Find online recipes that use the detected ingredients, scored by overlap. */
async function getOnlineMatches(have: string[], signal?: AbortSignal): Promise<Recipe[]> {
  const counts = new Map<string, number>();

  const queries = have.slice(0, MAX_INGREDIENT_QUERIES).map(async (ing) => {
    try {
      const data = await fetchJson<{ meals: MealSummary[] | null }>(
        `${MEALDB}/filter.php?i=${encodeURIComponent(ing)}`,
        signal,
      );
      for (const m of data.meals ?? []) {
        counts.set(m.idMeal, (counts.get(m.idMeal) ?? 0) + 1);
      }
    } catch {
      /* one ingredient failing shouldn't sink the batch */
    }
  });
  await Promise.all(queries);

  const ranked = [...counts.entries()]
    .sort((a, b) => b[1] - a[1])
    .slice(0, MAX_DETAIL_LOOKUPS)
    .map(([id]) => id);

  const recipes = await Promise.all(ranked.map((id) => lookupMeal(id, have, signal)));
  return recipes.filter((r): r is Recipe => r !== null);
}

/** Browse a category and return a recipe, used to fill an empty slot. */
async function getCategoryFallback(
  slot: Slot,
  have: string[],
  exclude: Set<string>,
  signal?: AbortSignal,
): Promise<Recipe | null> {
  const category = slot === "breakfast" ? "Breakfast" : slot === "dessert" ? "Dessert" : "Beef";
  try {
    const data = await fetchJson<{ meals: MealSummary[] | null }>(
      `${MEALDB}/filter.php?c=${encodeURIComponent(category)}`,
      signal,
    );
    const meals = (data.meals ?? []).filter((m) => !exclude.has(`mealdb-${m.idMeal}`));
    if (meals.length === 0) return null;
    // A little variety so repeated photos don't always show the same dish.
    const pick = meals[Math.floor(Math.random() * Math.min(meals.length, 12))];
    return await lookupMeal(pick.idMeal, have, signal);
  } catch {
    return null;
  }
}

function chooseBest(candidates: Recipe[], used: Set<string>): Recipe | null {
  const pool = candidates.filter((r) => !used.has(r.id));
  if (pool.length === 0) return null;
  return pool.sort(
    (a, b) => b.matched.length - a.matched.length || (a.minutes ?? 999) - (b.minutes ?? 999),
  )[0];
}

/**
 * Build the three-recipe trio (breakfast / main / dessert) for the detected
 * ingredients. Tries TheMealDB online first, fills gaps from category browsing,
 * and falls back to the bundled offline bank when offline or when a slot is
 * still empty — so the user always gets three recipes.
 */
export async function buildTrio(have: string[], signal?: AbortSignal): Promise<RecipeTrio> {
  const trio: RecipeTrio = { breakfast: null, main: null, dessert: null };
  const used = new Set<string>();
  const slots: Slot[] = ["breakfast", "main", "dessert"];

  const online = typeof navigator === "undefined" ? true : navigator.onLine;

  if (online) {
    let matches: Recipe[] = [];
    try {
      matches = await getOnlineMatches(have, signal);
    } catch {
      matches = [];
    }

    for (const slot of slots) {
      const pick = chooseBest(
        matches.filter((r) => r.slot === slot),
        used,
      );
      if (pick) {
        trio[slot] = pick;
        used.add(pick.id);
      }
    }

    // Fill any slot the ingredient search couldn't cover by browsing categories.
    for (const slot of slots) {
      if (trio[slot]) continue;
      const fb = await getCategoryFallback(slot, have, used, signal);
      if (fb) {
        // category browse may classify a meal differently; force the slot
        fb.slot = slot;
        trio[slot] = fb;
        used.add(fb.id);
      }
    }
  }

  // Final safety net: the offline bank guarantees every slot is filled.
  for (const slot of slots) {
    if (trio[slot]) continue;
    const db = await pickFromDatabank(slot, have, used);
    if (db) {
      trio[slot] = db;
      used.add(db.id);
    }
  }

  return trio;
}
