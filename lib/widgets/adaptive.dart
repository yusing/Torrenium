import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:macos_ui/macos_ui.dart';

import '/main.dart' show kIsDesktop;
import '/style.dart';
import 'cupertino_picker_button.dart';

Future<T?> showAdaptiveAlertDialog<T>({
  required Widget title,
  required Widget content,
  VoidCallback? onConfirm,
  String confirmLabel = 'Confirm',
  VoidCallback? onCancel,
  String cancelLabel = 'Cancel',
  TextStyle? onConfirmStyle,
}) async {
  onConfirm ?? () => Get.back(closeOverlays: true);
  if (kIsDesktop) {
    return await showMacosAlertDialog<T?>(
        context: Get.context!,
        barrierDismissible: true,
        builder: (context) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: MacosAlertDialog(
              title: title,
              message: content,
              appIcon: const SizedBox.shrink(),
              primaryButton: PushButton(
                controlSize: ControlSize.large,
                onPressed: () {
                  onConfirm?.call();
                  Get.back(closeOverlays: true);
                },
                child: Text(confirmLabel, style: onConfirmStyle),
              ),
              secondaryButton: onCancel == null
                  ? null
                  : PushButton(
                      controlSize: ControlSize.large,
                      onPressed: () {
                        onCancel.call();
                        Get.back(closeOverlays: true);
                      },
                      child: Text(cancelLabel),
                    ),
            ),
          );
        });
  }
  return await showCupertinoModalPopup(
      context: Get.context!,
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      builder: (_) =>
          CupertinoActionSheet(title: title, message: content, actions: [
            CupertinoActionSheetAction(
              isDefaultAction: true,
              onPressed: () {
                onConfirm?.call();
                Get.back(closeOverlays: true);
              },
              child: Text(confirmLabel),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                onCancel?.call();
                Get.back(closeOverlays: true);
              },
              child: Text(cancelLabel),
            ),
          ]));
}

Future<T?> showAdaptivePopup<T>({
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
}) async {
  if (kIsDesktop) {
    return await showMacosSheet<T>(
        context: Get.context!,
        barrierDismissible: barrierDismissible,
        useRootNavigator: useRootNavigator,
        builder: (context) {
          return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: MacosSheet(
                  child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: builder(context),
                ),
              )));
        });
  }
  return await showCupertinoModalPopup(
    context: Get.context!,
    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
    barrierDismissible: barrierDismissible,
    useRootNavigator: useRootNavigator,
    builder: (context) {
      return Container(
          height: MediaQuery.of(context).size.height * .8,
          alignment: Alignment.topLeft,
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground
                .resolveFrom(context)
                .withOpacity(.8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: builder(context),
          ));
    },
  );
}

class AdaptiveDropDown<T> extends StatefulWidget {
  final Iterable<T> items;
  final String Function(T) textGetter;
  final int value;
  final void Function(int) onChange;
  final bool Function(String)? enabledFilter;

  const AdaptiveDropDown(
      {super.key,
      required this.value,
      required this.items,
      required this.textGetter,
      required this.onChange,
      this.enabledFilter});

  @override
  State<AdaptiveDropDown<T>> createState() => _AdaptiveDropDownState<T>();
}

class AdaptiveIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double? size;
  const AdaptiveIcon(this.icon, {super.key, this.color, this.size});

  @override
  Widget build(BuildContext context) {
    if (kIsDesktop) {
      return MacosIcon(icon, color: color, size: size);
    }
    return Icon(icon, color: color, size: size);
  }
}

class AdaptiveIconButton extends StatelessWidget {
  final AdaptiveIcon icon;
  final VoidCallback onPressed;
  final EdgeInsetsGeometry? padding;
  final String? slidableLabel;
  const AdaptiveIconButton(
      {super.key,
      required this.icon,
      required this.onPressed,
      this.padding,
      this.slidableLabel});

  @override
  Widget build(BuildContext context) {
    if (kIsDesktop) {
      return MacosIconButton(
          padding: padding ?? const EdgeInsets.all(0),
          icon: icon,
          onPressed: onPressed,
          shape: BoxShape.circle);
    }
    return CupertinoButton(
      padding: padding ?? const EdgeInsets.all(0),
      onPressed: onPressed,
      child: icon,
    );
  }
}

class AdaptiveListTile extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final List<AdaptiveIconButton>? trailing;

  final VoidCallback? onTap;
  const AdaptiveListTile(
      {super.key,
      required this.title,
      this.subtitle,
      this.leading,
      this.trailing,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    final tile = GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leading != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: leading!,
                ),
              Expanded(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultTextStyle(
                      style: kItemTitleTextStyle,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 3,
                      child: title),
                  if (subtitle != null)
                    DefaultTextStyle(
                      style: kItemSubtitleTextStyle,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      child: subtitle!,
                    )
                ],
              )),
              if (kIsDesktop && trailing != null) ...[
                const SizedBox(width: 8),
                ...trailing!
              ]
            ],
          ),
        ),
      ),
    );
    if (!kIsDesktop && trailing != null) {
      return Slidable(
        key: key,
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: trailing!
              .map((e) => SlidableAction(
                    onPressed: (_) => e.onPressed(),
                    icon: e.icon.icon,
                    backgroundColor:
                        e.icon.color ?? CupertinoTheme.of(context).primaryColor,
                    foregroundColor: CupertinoColors.white,
                    label: e.slidableLabel,
                  ))
              .toList(),
        ),
        child: tile,
      );
    }
    return tile;
  }
}

class AdaptiveProgressBar extends StatelessWidget {
  final double value;
  final Color? trackColor;
  final Color backgroundColor;
  final double height;

  const AdaptiveProgressBar(
      {super.key,
      required this.value,
      this.trackColor,
      this.backgroundColor = MacosColors.systemGrayColor,
      this.height = 4.0})
      : assert(value >= 0 && value <= 1);

  @override
  Widget build(BuildContext context) {
    if (value == 0) {
      return const SizedBox.shrink();
    }
    if (kIsDesktop) {
      return ProgressBar(
        value: value * 100,
        trackColor: trackColor,
        backgroundColor: backgroundColor,
        height: height,
      );
    }
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: height,
        maxHeight: height,
        minWidth: 80.0,
      ),
      child: CustomPaint(
        painter: _ProgressBarPainter(
            value: value,
            trackColor: trackColor ?? CupertinoTheme.of(context).primaryColor,
            backgroundColor: backgroundColor,
            height: height),
      ),
    );
  }
}

class AdaptiveSwitch extends StatelessWidget {
  final String? label;
  final TextStyle? labelStyle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const AdaptiveSwitch(
      {this.value = true,
      this.label,
      this.labelStyle,
      this.onChanged,
      super.key});

  @override
  Widget build(BuildContext context) {
    if (label != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Text(label!, style: labelStyle),
          ),
          buildWidget()
        ],
      );
    }

    return buildWidget();
  }

  Widget buildWidget() {
    if (kIsDesktop) {
      return MacosSwitch(value: value, onChanged: onChanged);
    }
    return CupertinoSwitch(value: value, onChanged: onChanged);
  }
}

class AdaptiveTextButton extends StatelessWidget {
  final Widget? icon;
  final Widget label;
  final VoidCallback? onPressed;
  final Color? color;
  final double hPadding;

  const AdaptiveTextButton(
      {super.key,
      this.icon,
      this.color,
      this.hPadding = 6,
      required this.label,
      required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final child = icon == null
        ? label
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              color != null
                  ? IconTheme(data: IconThemeData(color: color), child: icon!)
                  : icon!,
              const SizedBox(width: 4),
              DefaultTextStyle(
                style: kItemTitleTextStyle.copyWith(color: color),
                overflow: TextOverflow.ellipsis,
                child: label,
              )
            ],
          );
    if (kIsDesktop) {
      return PushButton(
          padding: EdgeInsets.symmetric(horizontal: hPadding),
          onPressed: onPressed,
          controlSize: ControlSize.regular,
          color: const Color.fromARGB(0, 0, 0, 0),
          child: child);
    }
    if (icon == null) {
      return CupertinoButton.filled(
          padding: EdgeInsets.symmetric(horizontal: hPadding),
          onPressed: onPressed,
          child: child);
    }
    return CupertinoButton(
      padding: EdgeInsets.symmetric(horizontal: hPadding),
      onPressed: onPressed,
      child: child,
    );
  }
}

class AdaptiveTextField extends StatelessWidget {
  final bool autofocus;
  final TextEditingController? controller;
  final String? placeholder;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const AdaptiveTextField(
      {super.key,
      this.autofocus = false,
      this.controller,
      this.placeholder,
      this.onChanged,
      this.onSubmitted});

  _decoration() {
    // bottom only border
    return BoxDecoration(
        border: Border(
            bottom: BorderSide(
                color:
                    CupertinoColors.placeholderText.resolveFrom(Get.context!),
                width: 1)));
  }

  @override
  Widget build(BuildContext context) {
    if (kIsDesktop) {
      return MacosTextField(
        decoration: _decoration(),
        controller: controller,
        placeholder: placeholder,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        autofocus: autofocus,
      );
    }
    return CupertinoTextField(
      decoration: _decoration(),
      controller: controller,
      placeholder: placeholder,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      autofocus: autofocus,
    );
  }
}

class _AdaptiveDropDownState<T> extends State<AdaptiveDropDown<T>> {
  late var _value = widget.value;

  @override
  Widget build(BuildContext context) {
    if (!kIsDesktop) {
      return CupertinoPickerButton(
          items: List.generate(widget.items.length, (i) => i, growable: false),
          itemBuilder: (i) =>
              Text(widget.textGetter(widget.items.elementAt(i))),
          valueGetter: () => _value,
          onSelectedItemChanged: (i) => setState(() => _value = i),
          onPop: widget.onChange);
    }

    return MacosPopupButton(
        value: _value,
        items: List.generate(widget.items.length, (index) {
          final item = widget.items.elementAt(index);
          return MacosPopupMenuItem(
              value: index,
              enabled:
                  widget.enabledFilter?.call(widget.textGetter(item)) ?? true,
              child: Text(widget.textGetter(item)));
        }),
        onChanged: (i) {
          if (i == null) return;
          setState(() {
            _value = i;
          });
          widget.onChange(i);
        });
  }
}

class _ProgressBarPainter extends CustomPainter {
  final double value;
  final Color trackColor;
  final Color backgroundColor;
  final double height;

  const _ProgressBarPainter(
      {required this.value,
      this.trackColor = CupertinoColors.activeGreen,
      this.backgroundColor = CupertinoColors.systemGrey,
      this.height = 4.0});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw the background line
    canvas.drawRRect(
      const BorderRadius.all(Radius.circular(100)).toRRect(
        Offset.zero & size,
      ),
      Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.fill,
    );

    // Draw the active tick line
    canvas.drawRRect(
      const BorderRadius.horizontal(left: Radius.circular(100)).toRRect(
        Offset.zero &
            Size(
              value.clamp(0.0, 1.0) * size.width,
              size.height,
            ),
      ),
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressBarPainter old) => old.value != value;
}
