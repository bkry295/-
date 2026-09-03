import { createServer } from 'node:http';
import { readFile, stat } from 'node:fs/promises';
import { resolve, extname, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../build/web/', import.meta.url));
const mime = { '.html': 'text/html; charset=utf-8', '.js': 'application/javascript', '.json': 'application/json',
  '.wasm': 'application/wasm', '.png': 'image/png', '.svg': 'image/svg+xml', '.ttf': 'font/ttf', '.otf': 'font/otf' };
createServer(async (request, response) => {
  try {
    const pathname = decodeURIComponent(new URL(request.url, 'http://localhost').pathname);
    let path = resolve(root, '.' + pathname);
    if (path !== resolve(root) && !path.startsWith(resolve(root) + sep)) {
      response.writeHead(403).end();
      return;
    }
    if ((await stat(path)).isDirectory()) path = resolve(path, 'index.html');
    const content = await readFile(path);
    response.writeHead(200, { 'Content-Type': mime[extname(path)] ?? 'application/octet-stream', 'Cache-Control': 'no-store' });
    response.end(content);
  } catch {
    response.writeHead(404).end('Not found');
  }
}).listen(4173, '127.0.0.1', () => console.log('Mainichi preview: http://127.0.0.1:4173'));
