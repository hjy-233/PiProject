{{flutter_js}}
{{flutter_build_config}}

async function clearLegacyFlutterCache() {
  if ('serviceWorker' in navigator) {
    const registrations = await navigator.serviceWorker.getRegistrations();
    await Promise.all(registrations.map((registration) => registration.unregister()));
  }
  if ('caches' in window) {
    const cacheNames = await caches.keys();
    await Promise.all(cacheNames.map((cacheName) => caches.delete(cacheName)));
  }
}

clearLegacyFlutterCache()
  .catch((error) => console.warn('Unable to clear the legacy Flutter cache.', error))
  .then(() => _flutter.loader.load());
