import { useEffect, useState } from "react";
import { readMediaQuery, subscribeMediaQuery } from "../core/ClientCompatibility";

export function useMediaQuery(query: string, fallback = false): boolean {
  const [matches, setMatches] = useState(() => readMediaQuery(query, fallback));

  useEffect(() => {
    setMatches(readMediaQuery(query, fallback));
    return subscribeMediaQuery(query, setMatches);
  }, [fallback, query]);

  return matches;
}
