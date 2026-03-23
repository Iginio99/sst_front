# SST Front

Aplicacion Flutter para el sistema SST.

## Desarrollo local

```bash
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8010
```

## Build web

```bash
flutter build web --release --dart-define=API_BASE_URL=https://tu-api.onrender.com
```

Si tu WebSocket usa otra URL, puedes pasar tambien:

```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://tu-api.onrender.com \
  --dart-define=WS_BASE_URL=wss://tu-api.onrender.com
```
