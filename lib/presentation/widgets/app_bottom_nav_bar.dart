import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_radius.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _tabs = (
    icons: <String>['home', 'history', 'equalizer', 'smart_toy', 'person'],
    labels: <String>['Beranda', 'Riwayat', 'Laporan', 'FinChat', 'Profil'],
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.surfaceContainerHighest, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: List.generate(5, (i) => _buildNavItem(context, i)),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index) {
    final isActive = currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: AppRadius.lgRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _resolveIcon(_tabs.icons[index], isActive),
                size: 24,
                color: isActive ? AppColors.primary : AppColors.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 2),
              Text(
                _tabs.labels[index],
                style: AppTypography.labelMono.copyWith(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? AppColors.primary : AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _resolveIcon(String name, bool active) {
    switch (name) {
      case 'home':
        return active ? Icons.home_rounded : Icons.home_outlined;
      case 'history':
        return active ? Icons.history_rounded : Icons.history_outlined;
      case 'equalizer':
        return active ? Icons.bar_chart_rounded : Icons.bar_chart_outlined;
      case 'smart_toy':
        return active ? Icons.smart_toy_rounded : Icons.smart_toy_outlined;
      case 'person':
        return active ? Icons.person_rounded : Icons.person_outlined;
      default:
        return Icons.circle_outlined;
    }
  }
}
