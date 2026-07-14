import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database.dart';
import '../../providers/database_provider.dart';
import 'package:drift/drift.dart' as drift;

final transactionsProvider = StreamProvider<List<Transaction>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.transactions)..orderBy([(t) => drift.OrderingTerm(expression: t.date, mode: drift.OrderingMode.desc)])).watch();
});

class ExpenseSummary {
  final double balance;
  final double income;
  final double expense;

  ExpenseSummary({required this.balance, required this.income, required this.expense});
}

final expenseSummaryProvider = Provider<ExpenseSummary>((ref) {
  final transactions = ref.watch(transactionsProvider).value ?? [];
  
  double income = 0;
  double expense = 0;
  
  for (final t in transactions) {
    if (t.type == 'income') {
      income += t.amount;
    } else {
      expense += t.amount;
    }
  }
  
  return ExpenseSummary(
    balance: income - expense,
    income: income,
    expense: expense,
  );
});

final expenseActionsProvider = Provider<ExpenseActions>((ref) {
  return ExpenseActions(ref);
});

class ExpenseActions {
  final Ref ref;
  ExpenseActions(this.ref);

  Future<void> addTransaction({
    required String type,
    required double amount,
    required String category,
    String? note,
    DateTime? date,
  }) async {
    final db = ref.read(databaseProvider);
    await db.into(db.transactions).insert(TransactionsCompanion.insert(
      type: type,
      amount: amount,
      category: category,
      note: drift.Value(note),
      date: date ?? DateTime.now(),
    ));
  }

  Future<void> deleteTransaction(Transaction transaction) async {
    final db = ref.read(databaseProvider);
    await (db.delete(db.transactions)..where((t) => t.id.equals(transaction.id))).go();
  }
}
