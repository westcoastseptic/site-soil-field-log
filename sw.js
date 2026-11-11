/* Site & Soil Field Log service worker. Version b74082cb (2026-11-11).
   The app page loads fresh when online (so updates arrive) and from the cache when offline.
   Libraries and fonts are cached the first time they load. Map tiles are not cached. */
const CACHE="ssfl-b74082cb";
const SHELL=["./","index.html","manifest.webmanifest","icons/icon-192.png","icons/icon-512.png","icons/apple-touch-icon.png"];
const LIBS=[
"https://cdnjs.cloudflare.com/ajax/libs/exceljs/4.4.0/exceljs.min.js",
"https://cdn.jsdelivr.net/npm/docx@8.5.0/build/index.umd.js",
"https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js",
"https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.js",
"https://cdnjs.cloudflare.com/ajax/libs/jspdf-autotable/3.8.2/jspdf.plugin.autotable.min.js",
"https://fonts.googleapis.com/css2?family=Bayon&family=Open+Sans:wght@400;500;600;700&display=swap"
];
self.addEventListener("install",e=>{e.waitUntil((async()=>{const c=await caches.open(CACHE);await c.addAll(SHELL);
  await Promise.all(LIBS.map(u=>fetch(u,{mode:"no-cors"}).then(r=>c.put(u,r)).catch(()=>{})));self.skipWaiting()})())});
self.addEventListener("activate",e=>{e.waitUntil((async()=>{for(const k of await caches.keys())if(k!==CACHE)await caches.delete(k);await self.clients.claim()})())});
self.addEventListener("fetch",e=>{const r=e.request;if(r.method!=="GET")return;const u=new URL(r.url);
  if(r.mode==="navigate"){e.respondWith(fetch(r).then(res=>{const cp=res.clone();caches.open(CACHE).then(c=>c.put("index.html",cp));return res}).catch(()=>caches.match("index.html")));return}
  if(u.hostname.endsWith("tile.openstreetmap.org"))return;
  e.respondWith(caches.match(r).then(hit=>hit||fetch(r).then(res=>{if(res.ok||res.type==="opaque"){const cp=res.clone();caches.open(CACHE).then(c=>c.put(r,cp))}return res})))});
