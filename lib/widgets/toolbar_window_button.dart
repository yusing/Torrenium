import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

class ToolbarWindowButton extends MacosTooltip {
  ToolbarWindowButton({
    required Color color,
    required String tooltipMessage,
    VoidCallback? onPressed,
    super.key,
  }) : super(
            message: tooltipMessage,
            child: MacosIconButton(
              semanticLabel: tooltipMessage,
              onPressed: onPressed,
              backgroundColor: color,
              hoverColor: color.withOpacity(0.5),
              shape: BoxShape.circle,
              icon: const SizedBox.square(dimension: 12),
              boxConstraints:
                  const BoxConstraints.tightFor(width: 12, height: 12),
              padding: EdgeInsets.zero,
            ));
}
