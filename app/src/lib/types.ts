export type Slot = "breakfast" | "main" | "dessert";

export const SLOT_LABELS: Record<Slot, string> = {
  breakfast: "Breakfast",
  main: "Lunch / Dinner",
  dessert: "Dessert",
};

export const SLOT_EMOJI: Record<Slot, string> = {
  breakfast: "🍳",
  main: "🍝",
  dessert: "🍰",
};

export interface Recipe {
  id: string;
  title: string;
  slot: Slot;
  area?: string;
  category?: string;
  minutes?: number;
  image?: string;
  ingredients: string[];
  steps: string[];
  source: string;
  sourceUrl?: string;
  /** Detected ingredients that this recipe uses. */
  matched: string[];
  /** True when served from the bundled offline bank rather than online. */
  offline: boolean;
}

export type RecipeTrio = Record<Slot, Recipe | null>;

export interface DetectionResult {
  ingredients: string[];
  /** How the ingredients were obtained, for UI messaging. */
  via: "ai" | "manual";
  model?: string;
}
