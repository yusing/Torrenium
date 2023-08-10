import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../services/torrent.dart';

extension DartStringTCallback<T> on T Function(String) {
  T cStringCall(Pointer<Char> cStr) {
    assert(cStr != nullptr);
    T result = this(cStr.cast<Utf8>().toDartString());
    TorrentManager.go.FreeCString(cStr);
    return result;
  }
}

extension NativeStringTCallback<T> on T Function(Pointer<Char>) {
  T dartStringCall(String s) {
    Pointer<Char> cStr = s.toNativeUtf8().cast<Char>();
    assert(cStr != nullptr);
    T result = this(cStr);
    calloc.free(cStr);
    return result;
  }
}
