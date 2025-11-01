import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:front/features/settings/data/settings_repository.dart';

class NetworkPolicyException implements Exception {
  NetworkPolicyException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Enforces network usage policies such as Wi-Fi only mode.
class NetworkPolicyService {
  NetworkPolicyService._internal();

  static final NetworkPolicyService instance = NetworkPolicyService._internal();

  final SettingsRepository _settingsRepository = SettingsRepository();
  final Connectivity _connectivity = Connectivity();

  Future<void> ensureAllowedConnectivity() async {
    await _settingsRepository.initialize();

    if (!_settingsRepository.wifiOnlyUpload) {
      return;
    }

    final connectivityResults = await _connectivity.checkConnectivity();
    final hasValidConnection = connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.ethernet) ||
        connectivityResults.contains(ConnectivityResult.vpn);

    if (!hasValidConnection) {
      throw NetworkPolicyException('Wi-Fi 연결에서만 이용할 수 있는 기능입니다.');
    }
  }
}
