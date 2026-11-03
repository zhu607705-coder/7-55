export function Icon({
  name,
  size = 20,
  className = "",
}: {
  name:
    | "heart"
    | "star"
    | "plus"
    | "arrow"
    | "search"
    | "user"
    | "flag"
    | "note"
    | "spark"
    | "share";
  size?: number;
  className?: string;
}) {
  const shapes: Record<string, string> = {
    heart: "M2 3h3v1h2V3h3v1h1v4h-1v1H9v1H8v1H7v1H5v-1H4v-1H3V9H2V8H1V4h1z",
    star: "M5 1h2v3h4v2H9v2h1v3H8V9H7V8H5v1H4v2H2V8h1V6H1V4h4z",
    plus: "M5 1h2v4h4v2H7v4H5V7H1V5h4z",
    arrow: "M6 2h2v2h2v2h2v2h-2v2H8v2H6v-2h2V8H0V6h8V4H6z",
    search:
      "M2 1h5v1h1v1h1v5H8v1H7v1H2V9H1V8H0V3h1V2h1zm0 2v5h5V3zm6 6h2v1h1v1h1v2h-2v-1H9v-1H8z",
    user: "M4 0h4v1h1v5H8v1H4V6H3V1h1zM2 8h8v1h1v3H1V9h1z",
    flag: "M1 0h2v1h7v4H8v2H3v5H1z",
    note: "M2 0h7v1h1v1h1v10H1V0zm1 3v1h5V3zm0 3v1h5V6zm0 3v1h3V9z",
    spark: "M5 0h2v4h1v1h4v2H8v1H7v4H5V8H4V7H0V5h4V4h1z",
    share: "M8 0h3v3H8V2H5v3h2v3H5v2h3V9h3v3H8v-1H4V8H1V5h3V1h4z",
  };
  return (
    <svg
      className={`pixel-icon ${className}`}
      width={size}
      height={size}
      viewBox="0 0 12 13"
      aria-hidden="true"
      shapeRendering="crispEdges"
    >
      <path d={shapes[name]} fill="currentColor" />
    </svg>
  );
}
