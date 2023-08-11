import 'package:flutter/material.dart';

class AFDropdown<T> extends StatefulWidget {
  final Map<T, String> itemsMap;
  final ValueGetter<T> valueGetter;
  final ValueChanged<T?> onChanged;

  const AFDropdown(
      {super.key,
      required this.itemsMap,
      required this.valueGetter,
      required this.onChanged});

  @override
  State<AFDropdown<T>> createState() => _AFDropdownState<T>();
}

class _AFDropdownState<T> extends State<AFDropdown<T>> {
  @override
  Widget build(BuildContext context) {
    final value = widget.valueGetter();
    if (widget.itemsMap.isEmpty || widget.itemsMap[value] == null) {
      return const Text('Default');
    }
    if (widget.itemsMap.length == 1) {
      return Text(widget.itemsMap[value]!);
    }
    return DropdownButton<T>(
      value: value,
      onChanged: (v) {
        widget.onChanged.call(v);
        setState(() {});
      },
      items: widget.itemsMap.entries
          .map((e) => DropdownMenuItem<T>(
                value: e.key,
                child: Text(e.value),
              ))
          .toList(),
      alignment: Alignment.center,
    );
  }
}
