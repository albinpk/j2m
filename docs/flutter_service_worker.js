'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"favicon-16x16.png": "bea660b8a34b7c3d7a70ce66921d9900",
"flutter_bootstrap.js": "8f3896be5b0e892539ef25cd5ff866b4",
"version.json": "5ac9bc3f89e89bd0ee37dd14ead2c9f9",
"splash/img/light-2x.png": "3b264c865e395d7b4d73d5b2952ae781",
"splash/img/branding-4x.png": "b2f71793934f51018e29fcbb6dc6a383",
"splash/img/dark-4x.png": "4212c8f1d9f22af9a3537656d62f4f6c",
"splash/img/branding-dark-1x.png": "eac9795c5d55dd72463034b6df390a1a",
"splash/img/light-3x.png": "78f8843f14771f0cddb858a471f6ad60",
"splash/img/dark-3x.png": "78f8843f14771f0cddb858a471f6ad60",
"splash/img/light-4x.png": "4212c8f1d9f22af9a3537656d62f4f6c",
"splash/img/branding-2x.png": "73806b328d7be1b937c06fefb912fb20",
"splash/img/branding-3x.png": "056a275549cdb95ac814039e286fa401",
"splash/img/dark-2x.png": "3b264c865e395d7b4d73d5b2952ae781",
"splash/img/dark-1x.png": "6bc97662f402839edaf1a94309a8c5d6",
"splash/img/branding-dark-4x.png": "b2f71793934f51018e29fcbb6dc6a383",
"splash/img/branding-1x.png": "eac9795c5d55dd72463034b6df390a1a",
"splash/img/branding-dark-2x.png": "73806b328d7be1b937c06fefb912fb20",
"splash/img/light-1x.png": "6bc97662f402839edaf1a94309a8c5d6",
"splash/img/branding-dark-3x.png": "056a275549cdb95ac814039e286fa401",
"favicon.ico": "6cb16e500759c39af8430636fdfd3ecc",
"index.html": "15e4d8599552b0b6efb339278e43ac92",
"/": "15e4d8599552b0b6efb339278e43ac92",
"android-chrome-192x192.png": "316281eb24e45cb1ed39ce2d9e365900",
"apple-touch-icon.png": "1b3ff6e764e215b372ed535a7c12b866",
"CNAME": "d2ebb7ee116c183af2bc7e1fa6a44246",
"main.dart.js": "1420d9aa6a44d591683e297f8c0abac2",
"flutter.js": "76f08d47ff9f5715220992f993002504",
"android-chrome-512x512.png": "04dd3c0e11fb56fec923829b683233b9",
"site.webmanifest": "a5ec276ff31952ac9f5c690272aab3cd",
"manifest.json": "7558eab65f26fb53fbdbd3871c3f66c4",
"assets/AssetManifest.json": "da3094da336db28b465259edd99bab54",
"assets/NOTICES": "7ad05df6a9aca926dbd0aeb8de78eb4a",
"assets/FontManifest.json": "7628123f0921752335aae1e0d2ae59ec",
"assets/AssetManifest.bin.json": "434d8dd2aebbcf56825311f1e3e51a70",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "dbcd91c3d2edd61144acc3487a7eebc8",
"assets/fonts/MaterialIcons-Regular.otf": "436549d40dd5952174edbcb9b1221217",
"assets/assets/icons/github.png": "13710f78d5b04e771aaf3ecad35497a9",
"assets/assets/icons/linkedin.png": "d762d9217206c1d07e7e8f77c32fe799",
"assets/assets/fonts/RobotoMono-VariableFont_wght.ttf": "336102a48d996db3d945a346b1790b1f",
"favicon-32x32.png": "7fe7d2d5a50ce2167c536a653a138bb2",
"canvaskit/skwasm_st.js": "d1326ceef381ad382ab492ba5d96f04d",
"canvaskit/skwasm.js": "f2ad9363618c5f62e813740099a80e63",
"canvaskit/skwasm.js.symbols": "80806576fa1056b43dd6d0b445b4b6f7",
"canvaskit/canvaskit.js.symbols": "68eb703b9a609baef8ee0e413b442f33",
"canvaskit/skwasm.wasm": "f0dfd99007f989368db17c9abeed5a49",
"canvaskit/chromium/canvaskit.js.symbols": "5a23598a2a8efd18ec3b60de5d28af8f",
"canvaskit/chromium/canvaskit.js": "34beda9f39eb7d992d46125ca868dc61",
"canvaskit/chromium/canvaskit.wasm": "64a386c87532ae52ae041d18a32a3635",
"canvaskit/skwasm_st.js.symbols": "c7e7aac7cd8b612defd62b43e3050bdd",
"canvaskit/canvaskit.js": "86e461cf471c1640fd2b461ece4589df",
"canvaskit/canvaskit.wasm": "efeeba7dcc952dae57870d4df3111fad",
"canvaskit/skwasm_st.wasm": "56c3973560dfcbf28ce47cebe40f3206"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
