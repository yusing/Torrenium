import 'dart:convert';
import 'dart:io';

late final WebSocket _webSocketChannel;

Future<void> initReporter() async {
  _webSocketChannel = await WebSocket.connect(
    'wss://err.yumar.org',
  );
}

Future<void> reportError(
    {Object? error, String? msg, StackTrace? stackTrace}) async {
  final kBody = jsonEncode({
    'error': error.toString(),
    'stackTrace': stackTrace.toString(),
    'message': msg,
  });
  _webSocketChannel.add(kBody);
}
