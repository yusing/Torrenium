import 'dart:ui';

import 'package:cupertino_progress_bar/cupertino_progress_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

import '/main.dart' show kIsDesktop;
import 'cupertino_picker_button.dart';

Future<T?> showAdaptiveAlertDialog<T>({
  required BuildContext context,
  required Widget title,
  required Widget content,
  VoidCallback? onConfirm,
  String confirmLabel = "Dismiss",
  VoidCallback? onCancel,
  String cancelLabel = "Cancel",
  TextStyle? onConfirmStyle,
}) async {
  onConfirm ?? () => Navigator.of(context).pop();
  if (kIsDesktop) {
    return await showMacosAlertDialog<T?>(
        context: context,
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
                  Navigator.of(context).pop();
                },
                child: Text(confirmLabel, style: onConfirmStyle),
              ),
              secondaryButton: onCancel == null
                  ? null
                  : PushButton(
                      controlSize: ControlSize.large,
                      onPressed: () {
                        onCancel.call();
                        Navigator.of(context).pop();
                      },
                      child: Text(cancelLabel),
                    ),
            ),
          );
        });
  }
  return await showCupertinoModalPopup(
      context: context,
      barrierDismissible: true,
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      builder: (_) => AlertDialog(
              alignment: Alignment.center,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0)),
              title: title,
              content: content,
              actions: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    onConfirm?.call();
                    Navigator.of(context).pop();
                  },
                  child: Text(confirmLabel),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    onCancel?.call();
                    Navigator.of(context).pop();
                  },
                  child: Text(cancelLabel),
                ),
              ]));
}

Future<T?> showAdaptivePopup<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
}) async {
  if (kIsDesktop) {
    return await showMacosSheet<T>(
        context: context,
        builder: (context) {
          return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: MacosSheet(
                  child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: builder(context),
              )));
        },
        barrierDismissible: barrierDismissible,
        useRootNavigator: useRootNavigator);
  }
  return await showCupertinoModalPopup(
      context: context,
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * .8,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground
                .resolveFrom(context)
                .withOpacity(.8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: builder(context),
          ),
        );
      },
      barrierDismissible: barrierDismissible,
      useRootNavigator: useRootNavigator);
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
  final Widget icon;
  final VoidCallback onPressed;
  final EdgeInsetsGeometry? padding;
  const AdaptiveIconButton(
      {super.key, required this.icon, required this.onPressed, this.padding});

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

class AdaptiveListTile extends StatefulWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final List<Widget>? trailing;

  final VoidCallback? onTap;
  const AdaptiveListTile(
      {super.key,
      required this.title,
      this.subtitle,
      this.leading,
      this.trailing,
      this.onTap});

  @override
  State<AdaptiveListTile> createState() => _AdaptiveListTileState();
}

class AdaptiveProgressBar extends StatelessWidget {
  final double value;
  final Color? trackColor;
  const AdaptiveProgressBar({super.key, required this.value, this.trackColor})
      : assert(value >= 0 && value <= 1);

  @override
  Widget build(BuildContext context) {
    if (value == 0) {
      return const SizedBox.shrink();
    }
    if (kIsDesktop) {
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: ProgressBar(
          value: value * 100,
          trackColor: trackColor,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: CupertinoProgressBar(
        value: value,
        valueColor: trackColor,
      ),
    );
  }
}

class AdaptiveTextButton extends StatelessWidget {
  final Widget? icon;
  final Widget label;
  final VoidCallback onPressed;

  const AdaptiveTextButton(
      {super.key, this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final child = icon == null
        ? label
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [icon!, const SizedBox(width: 6), label],
          );
    if (kIsDesktop) {
      return PushButton(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          onPressed: onPressed,
          controlSize: ControlSize.regular,
          color: const Color.fromARGB(0, 0, 0, 0),
          child: child);
    }
    if (icon == null) {
      return CupertinoButton.filled(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          onPressed: onPressed,
          child: child);
    }
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      onPressed: onPressed,
      child: child,
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

class _AdaptiveListTileState extends State<AdaptiveListTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    if (kIsDesktop) {
      return MouseRegion(
        onHover: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: Container(
          color: _hovering ? MacosColors.systemBlueColor.withOpacity(.1) : null,
          child: MacosListTile(
            title: widget.trailing == null
                ? widget.title
                : Row(
                    children: [
                      Expanded(child: widget.title),
                      const SizedBox(width: 16),
                      ...widget.trailing!,
                    ],
                  ),
            subtitle: widget.subtitle,
            leading: widget.leading,
            onClick: widget.onTap,
          ),
        ),
      );
    }
    return CupertinoListTile(
      title: widget.title,
      subtitle: widget.subtitle,
      leading: widget.leading,
      onTap: widget.onTap,
      trailing: widget.trailing == null
          ? null
          : widget.trailing!.length == 1
              ? widget.trailing!.first
              : Row(mainAxisSize: MainAxisSize.min, children: widget.trailing!),
    );
  }
}
