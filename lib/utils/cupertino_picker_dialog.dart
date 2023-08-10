import 'package:flutter/cupertino.dart';

Future<T?> showPickerDialog<T>(
    BuildContext context, T? Function() valueGetter, Widget child) async {
  return await showCupertinoModalPopup<T>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) => Container(
      height: 216,
      padding: const EdgeInsets.only(top: 6.0),
      // The Bottom margin is provided to align the popup above the system navigation bar.
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      // Provide a background color for the popup.
      color: CupertinoColors.systemBackground.resolveFrom(context),
      // Use a SafeArea widget to avoid system overlaps.
      child: SafeArea(
        top: false,
        child: Column(children: [
          Expanded(child: child),
          CupertinoButton(
            child: const Text('Done'),
            onPressed: () => Navigator.of(context).pop(valueGetter()),
          ),
        ]),
      ),
    ),
  );
}
