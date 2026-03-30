# SST Front

Aplicacion Flutter para el sistema SST.

## Desarrollo local

```bash
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8010
```

Para probar el front contra el backend UAT en la nube:

```bash
flutter run -d chrome \
  --dart-define=API_BASE_URL=https://sst-backend-uat.onrender.com \
  --dart-define=APP_ENV=production
```

## Build web

```bash
flutter build web --release --dart-define=API_BASE_URL=https://sst-backend-uat.onrender.com --dart-define=APP_ENV=production
```

Si tu WebSocket usa otra URL, puedes pasar tambien:

```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://sst-backend-uat.onrender.com \
  --dart-define=WS_BASE_URL=wss://sst-backend-uat.onrender.com \
  --dart-define=APP_ENV=production
```

Si en el navegador sigues viendo llamadas a `https://tu-backend.onrender.com`, el problema no es este repo sino un build viejo publicado o cacheado en el navegador. En ese caso:

```bash
flutter build web --release --dart-define=API_BASE_URL=https://sst-backend-uat.onrender.com --dart-define=APP_ENV=production
```

y luego vuelve a publicar `build/web`. Si usas PWA/service worker, fuerza recarga del navegador o borra cache del sitio.
