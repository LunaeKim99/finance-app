import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';

class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionCard({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
    final isIncome = transaction.type == 'income';
    final amountColor = isIncome ? Colors.green : Colors.red;
    final amountPrefix = isIncome ? '+ ' : '- ';

    final iconData = _getCategoryIcon(transaction.category);

    if (isIOS) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CupertinoColors.systemGrey5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isIncome
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                iconData,
                color: amountColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.category,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateFormat.format(transaction.date),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  if (transaction.note.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      transaction.note,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Text(
              '$amountPrefix${currencyFormat.format(transaction.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: amountColor,
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isIncome ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  iconData,
                  color: amountColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.category,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateFormat.format(transaction.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (transaction.note.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        transaction.note,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                '$amountPrefix${currencyFormat.format(transaction.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: amountColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Makanan':
        return Platform.isIOS ? CupertinoIcons.bag_fill : Icons.restaurant;
      case 'Transportasi':
        return Platform.isIOS ? CupertinoIcons.car_fill : Icons.directions_car;
      case 'Belanja':
        return Platform.isIOS ? CupertinoIcons.bag : Icons.shopping_bag;
      case 'Hiburan':
        return Platform.isIOS ? CupertinoIcons.game_controller_solid : Icons.movie;
      case 'Kesehatan':
        return Platform.isIOS ? CupertinoIcons.heart_fill : Icons.local_hospital;
      case 'Pendidikan':
        return Platform.isIOS ? CupertinoIcons.book_fill : Icons.school;
      case 'Tagihan':
        return Platform.isIOS ? CupertinoIcons.doc_text_fill : Icons.receipt;
      case 'Gaji':
        return Platform.isIOS ? CupertinoIcons.money_dollar : Icons.work;
      case 'Bonus':
        return Platform.isIOS ? CupertinoIcons.gift_fill : Icons.card_giftcard;
      case 'Usaha':
        return Platform.isIOS ? CupertinoIcons.briefcase_fill : Icons.business;
      case 'Investasi':
        return Platform.isIOS ? CupertinoIcons.chart_bar_fill : Icons.trending_up;
      case 'Hadiah':
        return Platform.isIOS ? CupertinoIcons.gift : Icons.card_giftcard;
      default:
        return Platform.isIOS ? CupertinoIcons.ellipsis : Icons.more_horiz;
    }
  }
}