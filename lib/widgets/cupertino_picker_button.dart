import 'package:flutter/cupertino.dart';

import '../utils/cupertino_picker_dialog.dart';

class CupertinoPickerButton<T> extends StatefulWidget {
  final ValueChanged<int>? onSelectedItemChanged;
  final Iterable<T>? items;
  final T Function() valueGetter;
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
        _controller = FixedExtentScrollController(
            initialItem: widget.items!
                .toList(growable: false)
                .indexOf(widget.valueGetter()));
        showPickerDialog(
                context,
                widget.valueGetter,
                CupertinoPicker(
                    scrollController: _controller,
                    itemExtent: 32,
                    onSelectedItemChanged: (i) =>
                        widget.onSelectedItemChanged?.call(i),
                    children: widget.items!
                        .map((e) => widget.itemBuilder(e))
                        .toList(growable: false)))
            .then((value) {
          _controller.dispose();
          if (value == null) return;
          widget.onPop.call(value);
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
