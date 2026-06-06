import { useState } from "react";
import { getBackendUrl, setBackendUrl } from "../lib/config";

interface Props {
  onClose: () => void;
}

/**
 * Lets a user point the app at their own deployed detection backend without a
 * rebuild — handy for testing, or if Mom is on a different deployment. The
 * shared deployment normally bakes the URL in at build time (VITE_BACKEND_URL).
 */
export function Settings({ onClose }: Props) {
  const [url, setUrl] = useState(getBackendUrl());

  function save() {
    setBackendUrl(url);
    onClose();
  }

  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <h2>Settings</h2>
        <label className="field">
          <span>AI detection backend URL</span>
          <input
            value={url}
            placeholder="https://fridge-chef.<you>.workers.dev"
            onChange={(e) => setUrl(e.target.value)}
          />
        </label>
        <p className="muted small">
          Leave blank to use the deployment&apos;s built-in backend (or manual
          ingredient entry if none is configured). Your photos are sent to this
          backend only for ingredient detection.
        </p>
        <div className="modal-actions">
          <button className="btn ghost" onClick={onClose}>
            Cancel
          </button>
          <button className="btn primary" onClick={save}>
            Save
          </button>
        </div>
      </div>
    </div>
  );
}
