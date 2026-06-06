// Where the AI detection backend lives. Priority:
//   1. a runtime override saved in the browser (Settings panel)
//   2. the build-time VITE_BACKEND_URL baked in at deploy time
//   3. empty — the app still works, it just falls back to manual entry.
const LS_KEY = "fridgechef.backendUrl";

export function getBackendUrl(): string {
  const override = localStorage.getItem(LS_KEY);
  if (override && override.trim()) return override.trim().replace(/\/$/, "");
  const baked = import.meta.env.VITE_BACKEND_URL;
  return baked ? baked.replace(/\/$/, "") : "";
}

export function setBackendUrl(url: string): void {
  if (url.trim()) localStorage.setItem(LS_KEY, url.trim());
  else localStorage.removeItem(LS_KEY);
}

export function hasBackend(): boolean {
  return getBackendUrl().length > 0;
}
