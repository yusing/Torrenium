extension ByteUnits on num {
  String get humanReadableUnit {
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
}

extension PercentageUnit on num {
  String percentageUnit([int precision = 2]) {
    return '${(this * 100).toStringAsFixed(precision)}%';
  }
}

extension TimeUnit on num {
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
