class ApiConfig {
  ApiConfig._();

  /// Android emulator default. Override when running on a real device:
  /// flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8001/api/v1/
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8001/api/v1/',
  );

  static String resolveMediaUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return '';

    final value = rawUrl.trim();
    final apiUri = Uri.parse(baseUrl);
    final origin = Uri(
      scheme: apiUri.scheme,
      host: apiUri.host,
      port: apiUri.hasPort ? apiUri.port : null,
    );

    final parsed = Uri.tryParse(value);
    if (parsed != null && parsed.hasScheme) {
      if (parsed.host == 'localhost' || parsed.host == '127.0.0.1') {
        return parsed
            .replace(
              scheme: origin.scheme,
              host: origin.host,
              port: origin.hasPort ? origin.port : null,
            )
            .toString();
      }
      return value;
    }

    if (value.startsWith('/')) {
      return origin.replace(path: value).toString();
    }
    return origin.replace(path: '/$value').toString();
  }
}
