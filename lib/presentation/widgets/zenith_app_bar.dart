import 'package:flutter/material.dart';
import '../../core/theme/app_typography.dart';

class ZenithAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showLogo;
  final Widget? titleWidget;
  final Color? backgroundColor;

  const ZenithAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.showLogo = false,
    this.titleWidget,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? cs.surface,
        border: Border(
          bottom: BorderSide(color: cs.surfaceContainerHighest, width: 0.5),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              if (leading != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: leading!,
                )
              else
                const SizedBox(width: 12),
              const SizedBox(width: 4),
              if (showLogo)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(Icons.account_balance_wallet_rounded, color: cs.primary, size: 28),
                ),
              Expanded(
                child: titleWidget ??
                    Text(
                      title ?? '',
                      style: AppTypography.headlineSm.copyWith(color: cs.onSurface),
                    ),
              ),
              if (actions != null) ...[
                const SizedBox(width: 8),
                ...actions!,
              ],
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
