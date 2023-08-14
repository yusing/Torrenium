import 'package:flutter/cupertino.dart';

import '../utils/cupertino_picker_dialog.dart';

class CupertinoPickerButton<T> extends StatefulWidget {
  final ValueChanged<int>? onSelectedItemChanged;
  final Iterable<T>? items;
  final T? value;
  final Text Function(T item) itemBuilder;
  final void Function(T) onPop;

  const CupertinoPickerButton({
    super.key,
    this.onSelectedItemChanged,
    this.value,
    this.items,
    required this.itemBuilder,
    required this.onPop,
  });

  @override
  State<CupertinoPickerButton<T>> createState() =>
      _CupertinoPickerButtonState<T>();
}

class _CupertinoPickerButtonState<T> extends State<CupertinoPickerButton<T>> {
  var _selectedItem = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.items == null || widget.items!.isEmpty) {
      return const SizedBox();
    }
    return CupertinoButton(
      onPressed: () => showPickerDialog(
              context,
              () => widget.items!.elementAt(_selectedItem) ?? widget.value,
              CupertinoPicker(
                  itemExtent: 32,
                  onSelectedItemChanged: (i) {
                    widget.onSelectedItemChanged?.call(i);
                    setState(() {
                      _selectedItem = i;
                    });
                  },
                  children: widget.items!
                      .map((e) => widget.itemBuilder(e))
                      .toList(growable: false)))
          .then((value) {
        if (value == null) return;
        widget.onPop.call(value);
      }),
      child: Text(
          widget.itemBuilder(widget.items!.elementAt(_selectedItem)).data!),
    );
  }
}
