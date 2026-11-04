import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  server: {
    host: "127.0.0.1",
    port: Number(process.env.WEB_PORT ?? 5174),
    strictPort: true,
    proxy: { "/api": `http://127.0.0.1:${process.env.PORT ?? 3001}` },
  },
  build: { target: "es2022", sourcemap: false },
});
