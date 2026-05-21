import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class CurrencyText extends StatelessWidget {
  final double amount;
  final bool showPositiveSign;
  final bool isIncome;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;

  const CurrencyText({
    super.key,
    required this.amount,
    this.showPositiveSign = false,
    this.isIncome = true,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final prefix = showPositiveSign ? (isIncome ? '+ ' : '- ') : '';
    final sign = isIncome ? '' : '- ';
    final text = '$prefix$sign${fmt.format(amount.abs())}';

    return Text(
      text,
      textAlign: textAlign,
      style: (fontSize != null
              ? AppTypography.bodyMd.copyWith(fontSize: fontSize, fontWeight: fontWeight)
              : AppTypography.bodyMd.copyWith(fontWeight: fontWeight ?? FontWeight.w600))
          .copyWith(
        color: color ?? (isIncome ? AppColors.primary : AppColors.secondary),
      ),
    );
  }
}
