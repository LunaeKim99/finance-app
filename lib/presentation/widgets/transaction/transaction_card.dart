import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/transaction_type.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/icon_registry.dart';

class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;
  final bool showEditIcon;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
    this.showEditIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
    final isIncome = transaction.type == TransactionType.income;
    final amountColor = isIncome 
        ? AppTheme.incomeColor(context) 
        : AppTheme.expenseColor(context);
    final amountPrefix = isIncome ? '+ ' : '- ';

    final iconData = CategoryIconRegistry.resolve(transaction.categoryId, transaction.categoryName ?? transaction.categoryId);

    if (isIOS) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.cardBorderColor(context)),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: amountColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isIncome ? AppTheme.lightGreen : AppTheme.lightRed,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(iconData, color: amountColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      Text(
                        transaction.categoryName ?? transaction.categoryId,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppTheme.textPrimaryColor(context),
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      dateFormat.format(transaction.date),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondaryColor(context),
                      ),
                    ),
                    if (transaction.note.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        transaction.note,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondaryColor(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!transaction.isSynced)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Tooltip(
                            message: 'Menunggu sinkronisasi',
                            child: Icon(
                              Icons.cloud_off,
                              size: 14,
                              color: Colors.orange.shade400,
                            ),
                          ),
                        ),
                      Text(
                        '$amountPrefix${currencyFormat.format(transaction.amount)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: amountColor,
                        ),
                      ),
                    ],
                  ),
                  if (showEditIcon) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: onTap,
                      child: Icon(
                        Icons.edit_outlined,
                        size: 13,
                        color: isDark ? Colors.grey[600] : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.cardBorderColor(context)),
      ),
      color: AppTheme.cardColor(context),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap ?? () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: amountColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isIncome ? AppTheme.lightGreen : AppTheme.lightRed,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(iconData, color: amountColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      Text(
                        transaction.categoryName ?? transaction.categoryId,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppTheme.textPrimaryColor(context),
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      dateFormat.format(transaction.date),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondaryColor(context),
                      ),
                    ),
                    if (transaction.note.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        transaction.note,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondaryColor(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!transaction.isSynced)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Tooltip(
                            message: 'Menunggu sinkronisasi',
                            child: Icon(
                              Icons.cloud_off,
                              size: 14,
                              color: Colors.orange.shade400,
                            ),
                          ),
                        ),
                      Text(
                        '$amountPrefix${currencyFormat.format(transaction.amount)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: amountColor,
                        ),
                      ),
                    ],
                  ),
                  if (showEditIcon) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: onTap,
                      child: Icon(
                        Icons.edit_outlined,
                        size: 13,
                        color: isDark ? Colors.grey[600] : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Removed _getCategoryIcon method as it is now handled by CategoryIconRegistry.resolve()
}
