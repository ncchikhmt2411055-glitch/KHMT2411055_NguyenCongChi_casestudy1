import 'package:flutter/material.dart';

class Category {
  final String name;
  final IconData icon;
  final Color color;

  const Category(this.name, this.icon, this.color);
}

const List<Category> expenseCategories = [
  Category('Ăn uống', Icons.restaurant, Color(0xFFF44336)),
  Category('Di chuyển', Icons.directions_car, Color(0xFF2196F3)),
  Category('Mua sắm', Icons.shopping_bag, Color(0xFFFF9800)),
  Category('Giải trí', Icons.movie, Color(0xFF9C27B0)),
  Category('Hóa đơn', Icons.receipt_long, Color(0xFF607D8B)),
];

class TransactionFormScreen extends StatefulWidget {
  final bool isEdit;

  const TransactionFormScreen({super.key, this.isEdit = false});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  bool _isExpense = true;
  late Category _selected;
  late DateTime _date;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = expenseCategories[0];
    _date = DateTime(2025, 4, 12);

    // Màn hình sửa: điền sẵn dữ liệu của giao dịch đang sửa
    if (widget.isEdit) {
      _amountController.text = '100.000';
      _noteController.text = 'Ăn trưa';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day/$month/${d.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  void _save() {
    if (_amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.isEdit
            ? 'Đã cập nhật giao dịch'
            : 'Đã lưu giao dịch'),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Sửa giao dịch' : 'Thêm giao dịch'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Chọn loại giao dịch
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Chi tiêu')),
                ButtonSegment(value: false, label: Text('Thu nhập')),
              ],
              selected: {_isExpense},
              onSelectionChanged: (s) => setState(() => _isExpense = s.first),
            ),

            // Danh mục
            _label('Danh mục'),
            DropdownButtonFormField<Category>(
              initialValue: _selected,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: expenseCategories
                  .map(
                    (c) => DropdownMenuItem<Category>(
                      value: c,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: c.color,
                            child: Icon(c.icon, size: 14, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Text(c.name),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (c) => setState(() => _selected = c!),
            ),

            // Số tiền
            _label('Số tiền'),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Nhập số tiền',
                suffixText: 'đ',
                border: OutlineInputBorder(),
              ),
            ),

            // Ngày giao dịch
            _label('Ngày giao dịch'),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today, size: 18),
                ),
                child: Text(_formatDate(_date)),
              ),
            ),

            // Ghi chú
            _label('Ghi chú'),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Nhập ghi chú (tùy chọn)',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            // Nút lưu
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Lưu', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}