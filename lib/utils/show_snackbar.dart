import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/style.dart';

Future<SnackbarController> showSnackBar(String title, String message) async {
  final snackbar = GetSnackBar(
    titleText: Text(
      title,
      style: kItemTitleTextStyle,
    ),
    messageText: Text(
      message,
      style: kItemSubtitleTextStyle,
    ),
    snackPosition: SnackPosition.TOP,
    borderRadius: 15,
    margin: const EdgeInsets.symmetric(horizontal: 10),
    duration: const Duration(seconds: 2),
    barBlur: 7.0,
    backgroundColor: Colors.black.withOpacity(.2),
    shouldIconPulse: true,
    padding: const EdgeInsets.all(16),
    isDismissible: true,
    showProgressIndicator: false,
    snackStyle: SnackStyle.FLOATING,
  );
  final controller = SnackbarController(snackbar);
  await controller.show();
  return controller;
}
