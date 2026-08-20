import { defineConfig } from "vite";

// The app is the one exposed port. The proxy carries the wire, /listen and
// /mcp to `lapa dev` under /_lapa/ and forwards Authorization untouched.
export default defineConfig({
  server: {
    port: 8080,
    strictPort: true,
    proxy: {
      "/_lapa/": {
        target: "http://127.0.0.1:8081",
        rewrite: path => path.replace(/^\/_lapa/, ""),
        ws: true,
      },
    },
  },
});
