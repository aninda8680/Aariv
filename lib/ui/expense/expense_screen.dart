import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';
import '../../data/database.dart';
import 'expense_viewmodel.dart';
import 'package:intl/intl.dart';

class ExpenseScreen extends ConsumerWidget {
  const ExpenseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(expenseSummaryProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    
    // In settings we will have currency, hardcode ₹ for now
    const currency = '₹';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 28)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSummaryCard(context, summary, currency),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text('RECENT TRANSACTIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const Center(
                    child: Text('No transactions yet.', 
                        style: TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w600)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    return _buildTransactionTile(context, ref, tx, currency);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.ink)),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        width: 175,
        height: 50,
        child: BrutalistButton(
          color: AppColors.expenseAccent,
          onPressed: () => _showAddTransactionSheet(context, ref),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, color: AppColors.ink),
              SizedBox(width: 8),
              Text('ADD RECORD'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, ExpenseSummary summary, String currency) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: BrutalistContainer(
        child: Column(
          children: [
            const Text('TOTAL BALANCE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
            const SizedBox(height: 8),
            Text(
              '$currency${summary.balance.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppColors.ink),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: BrutalistContainer(
                    color: const Color(0xFFD4F7E3), // Light mint green
                    padding: const EdgeInsets.all(12),
                    shadowOffset: 2,
                    borderWidth: 1.5,
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.south_west, size: 16, color: Colors.green),
                            SizedBox(width: 4),
                            Text('INCOME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('$currency${summary.income.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: BrutalistContainer(
                    color: const Color(0xFFFFD6D6), // Light red
                    padding: const EdgeInsets.all(12),
                    shadowOffset: 2,
                    borderWidth: 1.5,
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.north_east, size: 16, color: AppColors.error),
                            SizedBox(width: 4),
                            Text('EXPENSE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('$currency${summary.expense.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                      ],
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(BuildContext context, WidgetRef ref, Transaction tx, String currency) {
    final isIncome = tx.type == 'income';
    return BrutalistContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      shadowOffset: 2,
      borderWidth: 1.5,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isIncome ? AppColors.expenseAccent : AppColors.error,
              border: Border.all(color: AppColors.ink, width: 1.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              isIncome ? Icons.south_west : Icons.north_east,
              color: AppColors.ink,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                if (tx.note != null && tx.note!.isNotEmpty)
                  Text(tx.note!, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                Text(
                  DateFormat('MMM dd, yyyy - HH:mm').format(tx.date),
                  style: const TextStyle(color: Colors.black38, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}$currency${tx.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: isIncome ? Colors.green[800] : AppColors.error,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 16),
            onPressed: () => ref.read(expenseActionsProvider).deleteTransaction(tx),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          )
        ],
      ),
    );
  }

  void _showAddTransactionSheet(BuildContext context, WidgetRef ref) {
    String type = 'expense';
    final amountController = TextEditingController();
    final categoryController = TextEditingController();
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              margin: const EdgeInsets.all(16).copyWith(bottom: MediaQuery.of(context).viewInsets.bottom + 16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border.all(color: AppColors.ink, width: 3),
                boxShadow: const [BoxShadow(color: AppColors.ink, offset: Offset(4, 4))],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('NEW TRANSACTION', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => type = 'expense'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: type == 'expense' ? AppColors.error : Theme.of(context).scaffoldBackgroundColor,
                              border: Border.all(color: AppColors.ink, width: 2),
                            ),
                            child: const Center(child: Text('EXPENSE', style: TextStyle(fontWeight: FontWeight.bold))),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => type = 'income'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: type == 'income' ? AppColors.expenseAccent : Theme.of(context).scaffoldBackgroundColor,
                              border: Border.all(color: AppColors.ink, width: 2),
                            ),
                            child: const Center(child: Text('INCOME', style: TextStyle(fontWeight: FontWeight.bold))),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
                      border: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.ink, width: 2)),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.ink, width: 2.5)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: categoryController,
                    decoration: InputDecoration(
                      labelText: 'Category (e.g. Food, Salary)',
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
                      border: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.ink, width: 2)),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.ink, width: 2.5)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      labelText: 'Note (optional)',
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
                      border: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.ink, width: 2)),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.ink, width: 2.5)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  BrutalistButton(
                    color: AppColors.expenseAccent,
                    onPressed: () {
                      final amount = double.tryParse(amountController.text);
                      final category = categoryController.text;
                      if (amount != null && category.isNotEmpty) {
                        ref.read(expenseActionsProvider).addTransaction(
                          type: type,
                          amount: amount,
                          category: category,
                          note: noteController.text.isNotEmpty ? noteController.text : null,
                        );
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('SAVE RECORD'),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }
}
