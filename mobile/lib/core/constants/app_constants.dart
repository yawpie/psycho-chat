class AppConstants {
  AppConstants._();
  static const String backendIpStorageKey = 'backend_ip';
  static String ip = '10.78.184.15';
  static const String appTitle = 'Psycho Chat';
  static String get webSocketUrl => 'ws://$ip:3000';
  static String get apiBaseUrl => 'http://$ip:3000';
}
