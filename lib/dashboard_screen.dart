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

  Widget _balanceCard(double balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'SỐ DƯ HIỆN TẠI',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.visibility_outlined,
                        color: Colors.white70, size: 16),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  formatMoney(balance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.account_balance_wallet,
            color: Colors.white54,
            size: 64,
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatMoney(amount),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
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
    final date = displayDate(t['transaction_date'] as String);

    return InkWell(
      onTap: () => _openForm(t),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color,
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.isNotEmpty ? note : categoryName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$categoryName  $date',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              '${isExpense ? '-' : '+'}${formatMoney(amount)}',
              style: TextStyle(
                color: isExpense ? Colors.red : Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recentList() {
    if (_items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Chưa có giao dịch nào. Bấm nút + để thêm.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final recent = _items.take(5).toList();
    return Column(
      children: [
        for (int i = 0; i < recent.length; i++) ...[
          _transactionTile(recent[i]),
          if (i < recent.length - 1) const Divider(height: 1),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final balance = _income - _expense;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87),
          onPressed: () {},
        ),
        title: const Text(
          'Quản lý thu chi',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined, color: Colors.black87),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
                  _balanceCard(balance),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _summaryCard(
                        label: 'TỔNG THU NHẬP',
                        amount: _income,
                        color: const Color(0xFF4CAF50),
                        icon: Icons.arrow_downward,
                      ),
                      const SizedBox(width: 12),
                      _summaryCard(
                        label: 'TỔNG CHI TIÊU',
                        amount: _expense,
                        color: const Color(0xFFF44336),
                        icon: Icons.arrow_upward,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Giao dịch gần đây',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Xem tất cả'),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _recentList(),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}