class AppConfig {
  static String? _backendIp;

  static String? get backendIp => _backendIp;

  static set backendIp(String value) {
    _backendIp = value;
  }

  static bool get isConfigured =>
      _backendIp != null && _backendIp!.isNotEmpty;

  static String get apiBaseUrl {
    if (!isConfigured) {
      throw Exception('Backend IP belum dikonfigurasi');
    }
    return 'http://$_backendIp:3000';
  }

  static String get websocketUrl {
    if (!isConfigured) {
      throw Exception('Backend IP belum dikonfigurasi');
    }
    return 'ws://$_backendIp:3000';
  }
}