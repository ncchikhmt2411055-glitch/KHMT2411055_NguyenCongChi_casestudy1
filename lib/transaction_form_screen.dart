import 'package:flutter/material.dart';
import 'database_helper.dart';

class TransactionFormScreen extends StatefulWidget {
  // Nếu có giao dịch truyền vào thì là màn hình Sửa, không thì là màn hình Thêm
  final Map<String, Object?>? transaction;

  const TransactionFormScreen({super.key, this.transaction});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _db = DatabaseHelper.instance;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isExpense = true;
  bool _saving = false;
  DateTime _date = DateTime.now();
  List<Map<String, Object?>> _categories = [];
  int? _selectedCategoryId;

  bool get _isEdit => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    if (t != null) {
      _isExpense = (t['is_expense'] as int) == 1;
      _selectedCategoryId = t['category_id'] as int;
      _amountController.text = (t['amount'] as num).round().toString();
      _noteController.text = (t['note'] as String?) ?? '';
      final parts = (t['transaction_date'] as String).split('-');
      _date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    }
    _loadCategories();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final list = await _db.getCategories(isIncome: !_isExpense);
    if (!mounted) return;
    setState(() {
      _categories = list;
      final exists = list.any((c) => c['id'] == _selectedCategoryId);
      if (!exists && list.isNotEmpty) {
        _selectedCategoryId = list.first['id'] as int;
      }
    });
  }

  void _setType(bool isExpense) {
    setState(() {
      _isExpense = isExpense;
      _selectedCategoryId = null;
      _categories = [];
    });
    _loadCategories();
  }

  String _formatDbDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  String _formatDisplayDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$day/$m/${d.year}';
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

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _save() async {
    final digits = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      _showMessage('Vui lòng nhập số tiền');
      return;
    }
    if (_selectedCategoryId == null) {
      _showMessage('Vui lòng chọn danh mục');
      return;
    }

    setState(() => _saving = true);

    final data = <String, Object?>{
      'category_id': _selectedCategoryId,
      'amount': double.parse(digits),
      'is_expense': _isExpense ? 1 : 0,
      'transaction_date': _formatDbDate(_date),
      'note': _noteController.text.trim(),
    };

    if (_isEdit) {
      await _db.updateTransaction(widget.transaction!['id'] as int, data);
    } else {
      await _db.insertTransaction(data);
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa giao dịch?'),
        content: const Text('Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await _db.deleteTransaction(widget.transaction!['id'] as int);
    if (!mounted) return;
    Navigator.pop(context, true);
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
        title: Text(_isEdit ? 'Sửa giao dịch' : 'Thêm giao dịch'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Chi tiêu')),
                ButtonSegment(value: false, label: Text('Thu nhập')),
              ],
              selected: {_isExpense},
              onSelectionChanged: (s) => _setType(s.first),
            ),

            _label('Danh mục'),
            DropdownButtonFormField<int>(
              key: ValueKey('${_isExpense}_${_categories.length}'),
              initialValue: _selectedCategoryId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _categories.map((c) {
                final color = Color(c['color_value'] as int);
                final icon = IconData(c['icon_code'] as int, fontFamily: 'MaterialIcons');
                return DropdownMenuItem<int>(
                  value: c['id'] as int,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: color,
                        child: Icon(icon, size: 14, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Text(c['name'] as String),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedCategoryId = v),
            ),

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

            _label('Ngày giao dịch'),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today, size: 18),
                ),
                child: Text(_formatDisplayDate(_date)),
              ),
            ),

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

            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
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

            if (_isEdit) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: _delete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Xóa giao dịch', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}