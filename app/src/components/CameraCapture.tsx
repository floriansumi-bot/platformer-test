import { useRef } from "react";

interface Props {
  onPhoto: (file: File) => void;
  busy: boolean;
}

/**
 * Photo input. On phones `capture="environment"` opens the rear camera; on
 * desktop it falls back to a normal file picker. A second button without the
 * capture hint lets users pick an existing photo from their library.
 */
export function CameraCapture({ onPhoto, busy }: Props) {
  const cameraRef = useRef<HTMLInputElement>(null);
  const libraryRef = useRef<HTMLInputElement>(null);

  function handle(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (file) onPhoto(file);
    e.target.value = "";
  }

  return (
    <div className="capture">
      <div className="capture-art" aria-hidden="true">📸🧊🥕🍅🧀</div>
      <h2>What&apos;s in your kitchen?</h2>
      <p className="muted">
        Snap your fridge or pantry. AI spots your ingredients and finds you a
        breakfast, a lunch&nbsp;/&nbsp;dinner and a dessert.
      </p>

      <input
        ref={cameraRef}
        type="file"
        accept="image/*"
        capture="environment"
        hidden
        onChange={handle}
      />
      <input ref={libraryRef} type="file" accept="image/*" hidden onChange={handle} />

      <button className="btn primary big" disabled={busy} onClick={() => cameraRef.current?.click()}>
        📷 Take a photo
      </button>
      <button className="btn ghost" disabled={busy} onClick={() => libraryRef.current?.click()}>
        Choose from library
      </button>
    </div>
  );
}
