import 'package:connectivity_plus/connectivity_plus.dart';

import '/main.dart' show kIsDesktop;
import '/services/settings.dart';

Future<bool> isLimitedConnectivity() async {
  if (kIsDesktop) {
    return false;
  }
  final conn = await Connectivity().checkConnectivity();
  return (conn == ConnectivityResult.mobile ||
          conn == ConnectivityResult.bluetooth &&
              Settings.dlOverWifiOnly.value) ||
      conn == ConnectivityResult.none;
}
