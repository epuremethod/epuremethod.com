import http from "node:http";
import path from "node:path";
import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import chokidar from "chokidar";
import { runBuild } from "./build.mjs";

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, "..");
const distDir = path.join(root, "dist");
const port = 4175;

const CONTENT_TYPES = {
  ".html": "text/html; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".svg": "image/svg+xml",
  ".png": "image/png",
};

async function rebuild() {
  await runBuild();
}

function serve() {
  const server = http.createServer(async (req, res) => {
    const urlPath = req.url === "/" ? "/api.html" : req.url;
    const filePath = path.join(distDir, decodeURIComponent(urlPath.split("?")[0]));
    try {
      const data = await readFile(filePath);
      const ext = path.extname(filePath);
      res.writeHead(200, { "Content-Type": CONTENT_TYPES[ext] || "application/octet-stream" });
      res.end(data);
    } catch {
      res.writeHead(404, { "Content-Type": "text/plain" });
      res.end("Not found");
    }
  });
  server.listen(port, () => {
    console.log(`Dev server running at http://localhost:${port}`);
  });
}

async function main() {
  await rebuild();
  serve();
  chokidar
    .watch([path.join(root, "content"), path.join(root, "src"), path.join(root, "assets")], {
      ignoreInitial: true,
    })
    .on("all", async (event, file) => {
      console.log(`${event}: ${path.relative(root, file)} — rebuilding`);
      await rebuild();
    });
}

main();
