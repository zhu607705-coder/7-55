/// <reference types="vite/client" />

declare module "*?chapter4-h3-embedded" {
  const source: string | {
    kind: "embedded_chunks";
    mimeType: "video/mp4; codecs=\"avc1.640028\"";
    chunks: string[];
  };
  export default source;
}

interface Window {
  render_game_to_text: () => string;
  render_endless_spotlight_to_text?: () => string;
  advanceTime?: (ms: number) => void | Promise<void>;
  __vt_pending?: Set<unknown>;
}
