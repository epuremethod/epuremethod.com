import { defineConfig } from "vite";
import tailwindcss from "@tailwindcss/vite";

// The app is the one exposed port. The proxy carries the wire, /listen and
// /mcp to `radif dev` under /_radif/ and forwards Authorization untouched.
//
// The host is named. Vite's default is `localhost`, which is not one address:
// it binds whichever family that resolves to, and other processes resolve it
// the other way. Everything that has to reach this app names an address —
// `epure-dev` probing the port, the scenarios, the proxy target below — so the
// app names one too.
export default defineConfig({
  plugins: [tailwindcss()],
  server: {
    host: "127.0.0.1",
    port: 8080,
    strictPort: true,
    proxy: {
      "/_radif/": {
        target: "http://127.0.0.1:8081",
        rewrite: path => path.replace(/^\/_radif/, ""),
        ws: true,
      },
    },
  },
});
