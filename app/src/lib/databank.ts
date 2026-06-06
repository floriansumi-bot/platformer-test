import type { Recipe, Slot } from "./types";

interface RawDbRecipe {
  id: string;
  title: string;
  slot: Slot;
  area?: string;
  minutes?: number;
  ingredients: string[];
  steps: string[];
  source: string;
}

let cache: RawDbRecipe[] | null = null;

/** Load (and cache) the bundled offline recipe bank. */
export async function loadDatabank(): Promise<RawDbRecipe[]> {
  if (cache) return cache;
  const url = `${import.meta.env.BASE_URL}recipes-databank.json`;
  const res = await fetch(url);
  const data = (await res.json()) as { recipes: RawDbRecipe[] };
  cache = data.recipes;
  return cache;
}

function scoreOverlap(recipeIngredients: string[], have: string[]): string[] {
  const haveSet = have.map((h) => h.toLowerCase());
  return recipeIngredients.filter((ri) =>
    haveSet.some((h) => ri.includes(h) || h.includes(ri)),
  );
}

/**
 * Pick the best-matching offline recipe for a slot given the detected
 * ingredients, skipping any ids already used. Falls back to the first unused
 * recipe in the slot when nothing matches.
 */
export async function pickFromDatabank(
  slot: Slot,
  have: string[],
  exclude: Set<string>,
): Promise<Recipe | null> {
  const all = (await loadDatabank()).filter(
    (r) => r.slot === slot && !exclude.has(r.id),
  );
  if (all.length === 0) return null;

  let best = all[0];
  let bestMatched = scoreOverlap(best.ingredients, have);
  for (const r of all.slice(1)) {
    const matched = scoreOverlap(r.ingredients, have);
    if (matched.length > bestMatched.length) {
      best = r;
      bestMatched = matched;
    }
  }

  return {
    id: best.id,
    title: best.title,
    slot: best.slot,
    area: best.area,
    minutes: best.minutes,
    ingredients: best.ingredients,
    steps: best.steps,
    source: best.source,
    matched: bestMatched,
    offline: true,
  };
}
