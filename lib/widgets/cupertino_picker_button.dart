import 'package:flutter/cupertino.dart';

import 'cupertino_picker_dialog.dart';

class CupertinoPickerButton<T> extends StatefulWidget {
  final ValueChanged<int>? onSelectedItemChanged;
  final List<T>? items;
  final ValueGetter<T> valueGetter;
  final Text Function(T item) itemBuilder;
  final void Function(T) onPop;
  final Widget onEmpty;

  const CupertinoPickerButton({
    super.key,
    this.onSelectedItemChanged,
    this.items,
    required this.valueGetter,
    required this.itemBuilder,
    required this.onPop,
    this.onEmpty = const SizedBox.shrink(),
  });

  @override
  State<CupertinoPickerButton<T>> createState() =>
      _CupertinoPickerButtonState<T>();
}

class _CupertinoPickerButtonState<T> extends State<CupertinoPickerButton<T>> {
  late FixedExtentScrollController _controller;

  @override
  Widget build(BuildContext context) {
    if (widget.items == null || widget.items!.isEmpty) {
      return widget.onEmpty;
    }
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        final initItem = widget.items!.indexOf(widget.valueGetter());
        _controller = FixedExtentScrollController(initialItem: initItem);
        showPickerDialog(
                context,
                widget.valueGetter,
                CupertinoPicker(
                    scrollController: _controller,
                    itemExtent: 32,
                    onSelectedItemChanged: (i) =>
                        widget.onSelectedItemChanged?.call(i),
                    children: List.unmodifiable(
                        widget.items!.map(widget.itemBuilder))))
            .then((value) {
          _controller.dispose();
          if (value == null) {
            widget.onSelectedItemChanged?.call(initItem);
          } else {
            widget.onPop.call(value);
          }
        });
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.itemBuilder(widget.valueGetter()).data!),
          const Padding(
            padding: EdgeInsets.only(left: 5.0),
            child: Icon(CupertinoIcons.chevron_down, size: 14),
          ),
        ],
      ),
    );
  }
}
