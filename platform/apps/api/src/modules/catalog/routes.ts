import type { FastifyInstance } from "fastify";
import { chapterListSchema, type Chapter } from "@755/contracts";

export interface CatalogReader {
  listPublicChapters(): Promise<Chapter[]>;
}
export function registerCatalog(app: FastifyInstance, catalog: CatalogReader) {
  app.get("/api/v1/chapters", async () => {
    const items = await catalog.listPublicChapters();
    return chapterListSchema.parse({ items });
  });
}
