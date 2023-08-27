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
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: CupertinoColors.black,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
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
