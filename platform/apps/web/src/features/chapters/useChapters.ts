import { useEffect, useState } from "react";
import { chapterListSchema, type Chapter } from "@755/contracts";

type LoadState =
  | { status: "loading" }
  | { status: "error" }
  | { status: "ready"; items: Chapter[] };
export function useChapters() {
  const [state, setState] = useState<LoadState>({ status: "loading" });
  const [attempt, setAttempt] = useState(0);
  useEffect(() => {
    const controller = new AbortController();
    const timeout = window.setTimeout(() => controller.abort(), 10_000);
    let active = true;
    setState({ status: "loading" });
    void fetch("/api/v1/chapters", {
      signal: controller.signal,
      headers: { Accept: "application/json" },
    })
      .then(async (response) => {
        if (!response.ok) throw new Error("Unavailable");
        return chapterListSchema.parse(await response.json());
      })
      .then(({ items }) => {
        if (active) setState({ status: "ready", items });
      })
      .catch(() => {
        if (active) setState({ status: "error" });
      })
      .finally(() => window.clearTimeout(timeout));
    return () => {
      active = false;
      window.clearTimeout(timeout);
      controller.abort();
    };
  }, [attempt]);
  return { state, retry: () => setAttempt((value) => value + 1) };
}
