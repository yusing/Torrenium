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
  String get percentageUnit {
    return '${(this * 100).toStringAsFixed(2)}%';
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
