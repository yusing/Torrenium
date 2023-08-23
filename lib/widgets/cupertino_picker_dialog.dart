import 'package:flutter/cupertino.dart';

Future<T?> showPickerDialog<T>(
    BuildContext context, T? Function() valueGetter, Widget child) async {
  return await showCupertinoModalPopup<T>(
    context: context,
    barrierDismissible: true,
    useRootNavigator: false,
    builder: (BuildContext context) => Container(
      height: 230,
      width: 450,
      alignment: Alignment.bottomRight,
      // The Bottom margin is provided to align the popup above the system navigation bar.
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      // Provide a background color for the popup.
      color: CupertinoColors.black,
      // Use a SafeArea widget to avoid system overlaps.
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Expanded(child: child),
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(valueGetter()),
          ),
        ]),
      ),
    ),
  );
}
