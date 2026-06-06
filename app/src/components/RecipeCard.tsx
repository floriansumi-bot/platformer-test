import { useState } from "react";
import type { Recipe, Slot } from "../lib/types";
import { SLOT_EMOJI, SLOT_LABELS } from "../lib/types";

interface Props {
  slot: Slot;
  recipe: Recipe | null;
}

export function RecipeCard({ slot, recipe }: Props) {
  const [open, setOpen] = useState(false);

  return (
    <article className="card">
      <div className="card-slot">
        <span className="slot-emoji" aria-hidden="true">
          {SLOT_EMOJI[slot]}
        </span>
        {SLOT_LABELS[slot]}
      </div>

      {!recipe ? (
        <div className="card-empty muted">No recipe found for this slot.</div>
      ) : (
        <>
          {recipe.image ? (
            <img className="card-img" src={recipe.image} alt={recipe.title} loading="lazy" />
          ) : (
            <div className="card-img placeholder" aria-hidden="true">
              {SLOT_EMOJI[slot]}
            </div>
          )}

          <h3 className="card-title">{recipe.title}</h3>

          <div className="card-meta">
            {recipe.area && <span>🌍 {recipe.area}</span>}
            {recipe.minutes != null && <span>⏱️ {recipe.minutes} min</span>}
            <span className={recipe.offline ? "badge offline" : "badge online"}>
              {recipe.offline ? "Offline bank" : "Found online"}
            </span>
          </div>

          {recipe.matched.length > 0 && (
            <p className="card-match">
              ✅ Uses what you have: {recipe.matched.slice(0, 6).join(", ")}
            </p>
          )}

          <button className="btn ghost full" onClick={() => setOpen((o) => !o)}>
            {open ? "Hide recipe" : "Show recipe"}
          </button>

          {open && (
            <div className="card-detail">
              <h4>Ingredients</h4>
              <ul>
                {recipe.ingredients.map((ing, i) => (
                  <li key={i}>{ing}</li>
                ))}
              </ul>
              <h4>Method</h4>
              <ol>
                {recipe.steps.map((step, i) => (
                  <li key={i}>{step}</li>
                ))}
              </ol>
              <p className="card-source">
                Source: {recipe.source}
                {recipe.sourceUrl && (
                  <>
                    {" — "}
                    <a href={recipe.sourceUrl} target="_blank" rel="noreferrer">
                      full recipe ↗
                    </a>
                  </>
                )}
              </p>
            </div>
          )}
        </>
      )}
    </article>
  );
}
