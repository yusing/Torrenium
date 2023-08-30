import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '/style.dart';

void showSnackBar(String title, String message) {
  GetSnackBar(
    duration: const Duration(seconds: 2),
    titleText: Text(
      title,
      style: kItemTitleTextStyle,
    ),
    messageText: Text(
      message,
      style: kItemSubtitleTextStyle,
    ),
    snackPosition: SnackPosition.TOP,
  );
}
