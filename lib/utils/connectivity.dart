import 'package:connectivity_plus/connectivity_plus.dart';

Future<bool> isLimitedConnectivity() async {
  final conn = await Connectivity().checkConnectivity();
  return conn == ConnectivityResult.mobile ||
      conn == ConnectivityResult.bluetooth ||
      conn == ConnectivityResult.none;
}
