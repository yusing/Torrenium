import 'package:cupertino_progress_bar/cupertino_progress_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

import '../main.dart' show kIsDesktop;

class DynamicIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double? size;
  const DynamicIcon(this.icon, {super.key, this.color, this.size});

  @override
  Widget build(BuildContext context) {
    if (kIsDesktop) {
      return MacosIcon(icon, color: color, size: size);
    }
    return Icon(icon, color: color, size: size);
  }
}

class DynamicIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onPressed;
  final EdgeInsetsGeometry? padding;
  const DynamicIconButton(
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

class DynamicListTile extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final List<Widget>? trailing;

  final VoidCallback? onTap;
  const DynamicListTile(
      {super.key,
      required this.title,
      this.subtitle,
      this.leading,
      this.trailing,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    if (kIsDesktop) {
      return MacosListTile(
        title: trailing == null
            ? title
            : Row(
                children: [
                  Expanded(child: title),
                  const SizedBox(width: 16),
                  ...trailing!,
                ],
              ),
        subtitle: subtitle,
        leading: leading,
        onClick: onTap,
      );
    }
    return CupertinoListTile(
      title: title,
      subtitle: subtitle,
      leading: leading,
      onTap: onTap,
      trailing: trailing == null
          ? null
          : trailing!.length == 1
              ? trailing!.first
              : Row(mainAxisSize: MainAxisSize.min, children: trailing!),
    );
  }
}

class DynamicProgressBar extends StatelessWidget {
  final double value;
  final Color? trackColor;
  const DynamicProgressBar({super.key, required this.value, this.trackColor})
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
