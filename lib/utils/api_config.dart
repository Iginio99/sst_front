// URLs configurables por compilacion:
// flutter build web --dart-define=API_BASE_URL=https://tu-api.onrender.com
const String _configuredApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8010',
);
const String _configuredWsBaseUrl = String.fromEnvironment('WS_BASE_URL');

final String apiBaseUrl = _configuredApiBaseUrl.endsWith('/')
    ? _configuredApiBaseUrl.substring(0, _configuredApiBaseUrl.length - 1)
    : _configuredApiBaseUrl;

final String wsBaseUrl = _configuredWsBaseUrl.isNotEmpty
    ? (_configuredWsBaseUrl.endsWith('/')
        ? _configuredWsBaseUrl.substring(0, _configuredWsBaseUrl.length - 1)
        : _configuredWsBaseUrl)
    : apiBaseUrl.startsWith('https://')
        ? apiBaseUrl.replaceFirst('https://', 'wss://')
        : apiBaseUrl.replaceFirst('http://', 'ws://');
