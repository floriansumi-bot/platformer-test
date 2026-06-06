import { getBackendUrl } from "./config";
import type { DetectionResult } from "./types";

/**
 * Downscale an image file to a JPEG data URL no larger than `maxDim` on its
 * long edge. Keeps the upload small (and the AI bill low) while staying sharp
 * enough to read labels and produce.
 */
export async function fileToScaledDataUrl(
  file: Blob,
  maxDim = 1024,
  quality = 0.82,
): Promise<string> {
  const bitmap = await createImageBitmap(file);
  const scale = Math.min(1, maxDim / Math.max(bitmap.width, bitmap.height));
  const w = Math.round(bitmap.width * scale);
  const h = Math.round(bitmap.height * scale);
  const canvas = document.createElement("canvas");
  canvas.width = w;
  canvas.height = h;
  const ctx = canvas.getContext("2d");
  if (!ctx) throw new Error("Canvas not supported on this device.");
  ctx.drawImage(bitmap, 0, 0, w, h);
  bitmap.close?.();
  return canvas.toDataURL("image/jpeg", quality);
}

export class NoBackendError extends Error {}

/**
 * Send the photo to the detection backend and get back a list of ingredients.
 * Throws NoBackendError when no backend is configured so the UI can fall back
 * to manual entry instead of showing a hard error.
 */
export async function detectIngredients(
  dataUrl: string,
  signal?: AbortSignal,
): Promise<DetectionResult> {
  const backend = getBackendUrl();
  if (!backend) throw new NoBackendError("No AI backend configured.");

  const base64 = dataUrl.split(",")[1] ?? "";
  const mediaType = (dataUrl.match(/^data:(.*?);/)?.[1] as string) || "image/jpeg";

  const res = await fetch(`${backend}/detect`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ image: base64, media_type: mediaType }),
    signal,
  });

  if (!res.ok) {
    let detail = `Detection failed (HTTP ${res.status}).`;
    try {
      const j = await res.json();
      if (j?.error) detail = j.error;
    } catch {
      /* ignore non-JSON bodies */
    }
    throw new Error(detail);
  }

  const data = (await res.json()) as { ingredients?: unknown; model?: string };
  const ingredients = Array.isArray(data.ingredients)
    ? data.ingredients
        .map((x) => String(x).trim().toLowerCase())
        .filter(Boolean)
    : [];

  return { ingredients: dedupe(ingredients), via: "ai", model: data.model };
}

export function dedupe(items: string[]): string[] {
  return Array.from(new Set(items.map((s) => s.trim().toLowerCase()).filter(Boolean)));
}
