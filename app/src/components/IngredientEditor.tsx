import { useState } from "react";

interface Props {
  ingredients: string[];
  onChange: (next: string[]) => void;
  onSearch: () => void;
  note?: string;
  busy: boolean;
}

/** Editable chip list of detected ingredients — add, remove, then search. */
export function IngredientEditor({ ingredients, onChange, onSearch, note, busy }: Props) {
  const [draft, setDraft] = useState("");

  function add() {
    const v = draft.trim().toLowerCase();
    if (v && !ingredients.includes(v)) onChange([...ingredients, v]);
    setDraft("");
  }

  function remove(item: string) {
    onChange(ingredients.filter((i) => i !== item));
  }

  return (
    <div className="editor">
      <h2>Your ingredients</h2>
      {note && <p className="muted">{note}</p>}

      <div className="chips">
        {ingredients.length === 0 && (
          <span className="muted">No ingredients yet — add a few below.</span>
        )}
        {ingredients.map((item) => (
          <span key={item} className="chip">
            {item}
            <button aria-label={`Remove ${item}`} onClick={() => remove(item)}>
              ×
            </button>
          </span>
        ))}
      </div>

      <div className="add-row">
        <input
          value={draft}
          placeholder="Add an ingredient…"
          onChange={(e) => setDraft(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Enter") add();
          }}
        />
        <button className="btn ghost" onClick={add}>
          Add
        </button>
      </div>

      <button
        className="btn primary big"
        disabled={busy || ingredients.length === 0}
        onClick={onSearch}
      >
        {busy ? "Finding recipes…" : "🍽️ Find my 3 recipes"}
      </button>
    </div>
  );
}
