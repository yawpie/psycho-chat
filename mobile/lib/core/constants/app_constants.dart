class AppConstants {
  AppConstants._();
  static const String backendIpStorageKey = 'backend_ip';
  static String ip = '192.168.1.108';
  static const String appTitle = 'Psycho Chat';
  static String get webSocketUrl => 'wss://$ip:3000';
  static String get apiBaseUrl => 'https://$ip:3000';
}
