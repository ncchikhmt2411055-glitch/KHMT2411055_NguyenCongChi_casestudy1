import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'transaction_form_screen.dart';

String formatMoney(double value) {
  final digits = value.abs().round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(digits[i]);
  }
  final sign = value < 0 ? '-' : '';
  return '$sign${buffer.toString()} đ';
}

String displayDate(String dbDate) {
  final p = dbDate.split('-');
  return '${p[2]}/${p[1]}/${p[0]}';
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _db = DatabaseHelper.instance;

  bool _loading = true;
  double _income = 0;
  double _expense = 0;
  List<Map<String, Object?>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final totals = await _db.getTotals();
    final items = await _db.getTransactions();
    if (!mounted) return;
    setState(() {
      _income = totals['income']!;
      _expense = totals['expense']!;
      _items = items;
      _loading = false;
    });
  }

  // Mở form Thêm (không truyền dữ liệu) hoặc form Sửa (truyền giao dịch).
  // Khi form đóng với kết quả true thì tải lại dữ liệu.
  Future<void> _openForm([Map<String, Object?>? transaction]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionFormScreen(transaction: transaction),
      ),
    );
    if (changed == true) {
      _load();
    }
  }

  Widget _summaryCard(String label, double amount, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 4),
            Text(
              formatMoney(amount),
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _transactionTile(Map<String, Object?> t) {
    final isExpense = (t['is_expense'] as int) == 1;
    final amount = (t['amount'] as num).toDouble();
    final categoryName = t['category_name'] as String;
    final note = (t['note'] as String?) ?? '';
    final color = Color(t['color_value'] as int);
    final icon = IconData(t['icon_code'] as int, fontFamily: 'MaterialIcons');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () => _openForm(t),
      leading: CircleAvatar(
        backgroundColor: color,
        child: Icon(icon, color: Colors.white, size: 18),
      ),
      title: Text(note.isNotEmpty ? note : categoryName),
      subtitle: Text('$categoryName | ${displayDate(t['transaction_date'] as String)}'),
      trailing: Text(
        '${isExpense ? '-' : '+'}${formatMoney(amount)}',
        style: TextStyle(
          color: isExpense ? Colors.red : Colors.green,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balance = _income - _expense;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Tổng quan'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Số dư hiện tại',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formatMoney(balance),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _summaryCard('Thu nhập', _income, const Color(0xFF4CAF50), Icons.arrow_downward),
                      const SizedBox(width: 12),
                      _summaryCard('Chi tiêu', _expense, const Color(0xFFF44336), Icons.arrow_upward),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Giao dịch gần đây',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  if (_items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'Chưa có giao dịch nào. Bấm nút + để thêm.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ..._items.map(_transactionTile),
                ],
              ),
            ),
    );
  }
}