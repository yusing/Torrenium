import 'dart:convert';

import 'package:crypto/crypto.dart';

extension DateTimeExt on DateTime {
  String get relative {
    final now = DateTime.now();
    final diff = now.difference(this);
    if (diff.inDays > 0) {
      return '${diff.inDays} days ago';
    }
    if (diff.inHours > 0) {
      return '${diff.inHours} hours ago';
    }
    if (diff.inMinutes > 0) {
      return '${diff.inMinutes} minutes ago';
    }
    return '${diff.inSeconds} seconds ago';
  }
}

extension DurationExt on Duration? {
  String toStringNoMs() {
    if (this == null) {
      return '00:00';
    }

    var microseconds = this!.inMicroseconds;

    var hours = microseconds ~/ Duration.microsecondsPerHour;
    microseconds = microseconds.remainder(Duration.microsecondsPerHour);

    if (microseconds < 0) microseconds = -microseconds;

    var minutes = microseconds ~/ Duration.microsecondsPerMinute;
    microseconds = microseconds.remainder(Duration.microsecondsPerMinute);

    var minutesPadding = minutes < 10 ? "0" : "";

    var seconds = microseconds ~/ Duration.microsecondsPerSecond;
    microseconds = microseconds.remainder(Duration.microsecondsPerSecond);

    var secondsPadding = seconds < 10 ? "0" : "";

    var str = "$minutesPadding$minutes:"
        "$secondsPadding$seconds";
    if (hours > 0) {
      return "$hours:$str";
    }
    return str;
  }
}

extension NumExt on num {
  String get countUnit {
    if (this < 1000) {
      return '$this';
    } else if (this < 1000 * 1000) {
      return '${(this / 1000).toStringAsFixed(0)}K';
    } else if (this < 1000 * 1000 * 1000) {
      return '${(this / 1000 / 1000).toStringAsFixed(0)}M';
    } else {
      return '${(this / 1000 / 1000 / 1000).toStringAsFixed(0)}B';
    }
  }

  String get sizeUnit {
    if (this < 1024) {
      return '$this B';
    } else if (this < 1024 * 1024) {
      return '${(this / 1024).toStringAsFixed(2)} KB';
    } else if (this < 1024 * 1024 * 1024) {
      return '${(this / 1024 / 1024).toStringAsFixed(2)} MB';
    } else {
      return '${(this / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
    }
  }

  String get timeUnit {
    if (this < 60) {
      return '${floor()} seconds';
    }
    if (this == double.infinity) {
      return '∞ s';
    }
    if (this < 60 * 60) {
      return '${(this / 60).floor()} minutes and ${(this % 60).floor()} seconds';
    } else if (this < 60 * 60 * 24) {
      return '${(this / 60 / 60).floor()} hours and ${(this % 60).floor()} minutes';
    } else {
      return '${(this / 60 / 60 / 24).floor()} days and ${(this % 24).floor()} hours';
    }
  }

  String percentageUnit([int precision = 2]) {
    return '${(this * 100).toStringAsFixed(precision)}%';
  }
}

extension StringExt on String {
  String get sha1Hash => sha1.convert(utf8.encode(this)).toString();
  String get sha256Hash => sha256.convert(utf8.encode(this)).toString();

  String removeDelimiters(String delimiters) {
    String s = this;
    for (var delimiter in delimiters.split('')) {
      s = s.replaceAll(delimiter, ' ');
    }
    return s;
  }
}
