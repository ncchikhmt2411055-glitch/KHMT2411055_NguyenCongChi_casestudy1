import 'package:flutter/material.dart';
import 'transaction_form_screen.dart';

class DashboardItem {
  final String title;
  final String category;
  final double amount;
  final IconData icon;
  final Color color;

  const DashboardItem({
    required this.title,
    required this.category,
    required this.amount,
    required this.icon,
    required this.color,
  });
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const double income = 5000000;
  static const double expense = 1250000;

  static const List<DashboardItem> recentItems = [
    DashboardItem(
      title: 'Lương tháng 4',
      category: 'Thu nhập',
      amount: 5000000,
      icon: Icons.payments,
      color: Color(0xFF4CAF50),
    ),
    DashboardItem(
      title: 'Ăn trưa',
      category: 'Ăn uống',
      amount: -100000,
      icon: Icons.restaurant,
      color: Color(0xFFF44336),
    ),
    DashboardItem(
      title: 'Xăng xe',
      category: 'Di chuyển',
      amount: -150000,
      icon: Icons.directions_car,
      color: Color(0xFF2196F3),
    ),
    DashboardItem(
      title: 'Tiền điện',
      category: 'Hóa đơn',
      amount: -800000,
      icon: Icons.receipt_long,
      color: Color(0xFF607D8B),
    ),
  ];

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

  Widget buildSummaryCard(String label, double amount, Color color, IconData icon) {
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
            Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 4),
            Text(
              formatMoney(amount),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildItemTile(DashboardItem item) {
    final isExpense = item.amount < 0;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: item.color,
        child: Icon(item.icon, color: Colors.white, size: 18),
      ),
      title: Text(item.title),
      subtitle: Text(item.category),
      trailing: Text(
        formatMoney(item.amount),
        style: TextStyle(
          color: isExpense ? Colors.red : Colors.green,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balance = income - expense;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Tổng quan'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TransactionFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: ListView(
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
              buildSummaryCard(
                'Thu nhập',
                income,
                const Color(0xFF4CAF50),
                Icons.arrow_downward,
              ),
              const SizedBox(width: 12),
              buildSummaryCard(
                'Chi tiêu',
                expense,
                const Color(0xFFF44336),
                Icons.arrow_upward,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Giao dịch gần đây',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...recentItems.map(buildItemTile),
        ],
      ),
    );
  }
}