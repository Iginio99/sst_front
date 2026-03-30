import 'package:flutter/material.dart';

import '../utils/colors.dart';

class DesktopContentScaffold extends StatelessWidget {
  const DesktopContentScaffold({
    super.key,
    required this.child,
    this.sidePanel,
    this.maxContentWidth = 1320,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final Widget? sidePanel;
  final double maxContentWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgSlate100,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: Padding(
            padding: padding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: child),
                if (sidePanel != null) ...[
                  const SizedBox(width: 24),
                  SizedBox(width: 320, child: sidePanel!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
