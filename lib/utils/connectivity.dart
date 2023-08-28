import 'package:connectivity_plus/connectivity_plus.dart';

import '/services/settings.dart';

Future<bool> isLimitedConnectivity() async {
  final conn = await Connectivity().checkConnectivity();
  return (conn == ConnectivityResult.mobile ||
          conn == ConnectivityResult.bluetooth &&
              Settings.dlOverWifiOnly.value) ||
      conn == ConnectivityResult.none;
}
