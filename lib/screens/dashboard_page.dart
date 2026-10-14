import 'package:flutter/material.dart';

// ============================================================
// MODEL
// ============================================================

class ExpenseItem {
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final bool isExpense;

  ExpenseItem({
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.isExpense,
  });
}

// ============================================================
// HELPERS
// ============================================================

IconData categoryIcon(String category) {
  switch (category) {
    case 'Food':
      return Icons.restaurant_rounded;
    case 'Transport':
      return Icons.directions_car_rounded;
    case 'Shopping':
      return Icons.shopping_bag_rounded;
    case 'Bills':
      return Icons.receipt_long_rounded;
    case 'Health':
      return Icons.favorite_rounded;
    case 'Salary':
      return Icons.account_balance_wallet_rounded;
    default:
      return Icons.category_rounded;
  }
}

Color categoryColor(String category) {
  switch (category) {
    case 'Food':
      return const Color(0xFFFF8A65);
    case 'Transport':
      return const Color(0xFF42A5F5);
    case 'Shopping':
      return const Color(0xFFAB47BC);
    case 'Bills':
      return const Color(0xFFFFB300);
    case 'Health':
      return const Color(0xFFEF5350);
    case 'Salary':
      return const Color(0xFF26A69A);
    default:
      return const Color(0xFF78909C);
  }
}

String money(double value) {
  final digits = value.abs().toStringAsFixed(0);
  final buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return '${value < 0 ? '-' : ''}Rs $buffer';
}

String shortDate(DateTime d) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${d.day} ${months[d.month - 1]}';
}

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

// ============================================================
// DASHBOARD
// ============================================================

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const Color primary = Color(0xFF5B4BFF);
  static const Color dark = Color(0xFF1B1B2F);
  static const Color background = Color(0xFFF5F6FA);

  int _navIndex = 0;

  late final List<ExpenseItem> _items;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _items = [];
  }

  // ---------- Calculations ----------

  double get _income => _items
      .where((e) => !e.isExpense)
      .fold<double>(0, (sum, e) => sum + e.amount);

  double get _expense => _items
      .where((e) => e.isExpense)
      .fold<double>(0, (sum, e) => sum + e.amount);

  double get _balance => _income - _expense;

  Map<String, double> get _categoryTotals {
    final map = <String, double>{};
    for (final e in _items.where((e) => e.isExpense)) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  // ---------- Actions ----------

  Future<void> _openAddSheet() async {
    final result = await showModalBottomSheet<ExpenseItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _AddTransactionSheet(),
    );

    if (result != null) {
      setState(() => _items.add(result));
    }
  }

  void _deleteItem(ExpenseItem item) {
    setState(() => _items.remove(item));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.title} deleted'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final recent = [..._items]..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: primary.withValues(alpha: 0.15),
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded, color: primary),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(
              Icons.account_balance_wallet_rounded,
              color: primary,
            ),
            label: 'Wallet',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded, color: primary),
            label: 'Profile',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  const SizedBox(height: 24),
                  _balanceCard(),
                  const SizedBox(height: 28),
                  _sectionTitle('Last 7 days'),
                  const SizedBox(height: 12),
                  _weeklyChart(),
                  const SizedBox(height: 28),
                  _sectionTitle('Top spending'),
                  const SizedBox(height: 12),
                  _topCategories(),
                  const SizedBox(height: 28),
                  _sectionTitle('Recent transactions'),
                  const SizedBox(height: 12),
                  if (recent.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No transactions yet. Tap Add to create one.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    )
                  else
                    ...recent.map(_transactionTile),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 24,
          backgroundColor: primary,
          child: Text(
            'A',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const Text(
              'Ali',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: dark,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded, color: dark),
          ),
        ),
      ],
    );
  }

  Widget _balanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B4BFF), Color(0xFF9B6BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Balance',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            money(_balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _balanceStat(
                  label: 'Income',
                  value: money(_income),
                  icon: Icons.arrow_downward_rounded,
                  iconColor: const Color(0xFF69F0AE),
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.white24,
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              Expanded(
                child: _balanceStat(
                  label: 'Expenses',
                  value: money(_expense),
                  icon: Icons.arrow_upward_rounded,
                  iconColor: const Color(0xFFFF8A80),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _balanceStat({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: dark,
      ),
    );
  }

  Widget _weeklyChart() {
    const dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final now = DateTime.now();

    final days = List.generate(
      7,
      (i) => DateTime(now.year, now.month, now.day - (6 - i)),
    );

    final totals = days
        .map(
          (d) => _items
              .where((e) => e.isExpense && sameDay(e.date, d))
              .fold<double>(0, (sum, e) => sum + e.amount),
        )
        .toList();

    final maxValue = totals.fold<double>(0, (m, v) => v > m ? v : m);
    final weekTotal = totals.fold<double>(0, (sum, v) => sum + v);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spent this week',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            money(weekTotal),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: dark,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final isToday = i == 6;
                final barHeight = maxValue == 0
                    ? 6.0
                    : 6 + 100 * totals[i] / maxValue;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 30,
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: isToday
                            ? primary
                            : primary.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dayLetters[days[i].weekday - 1],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                        color: isToday ? primary : Colors.grey.shade600,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topCategories() {
    final totals = _categoryTotals;
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(4).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: top.isEmpty
          ? Text(
              'No expenses yet',
              style: TextStyle(color: Colors.grey.shade600),
            )
          : Column(
              children: top.map((entry) {
                final percent = _expense == 0 ? 0.0 : entry.value / _expense;
                final color = categoryColor(entry.key);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          categoryIcon(entry.key),
                          color: color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: dark,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  money(entry.value),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: dark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: percent,
                                minHeight: 7,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _transactionTile(ExpenseItem item) {
    final color = categoryColor(item.category);

    return Dismissible(
      key: ObjectKey(item),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteItem(item),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(categoryIcon(item.category), color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: dark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${item.category} • ${shortDate(item.date)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Text(
              '${item.isExpense ? '-' : '+'}${money(item.amount)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: item.isExpense
                    ? Colors.redAccent
                    : const Color(0xFF26A69A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ADD TRANSACTION BOTTOM SHEET
// ============================================================

class _AddTransactionSheet extends StatefulWidget {
  const _AddTransactionSheet();

  @override
  State<_AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<_AddTransactionSheet> {
  static const Color primary = Color(0xFF5B4BFF);
  static const Color dark = Color(0xFF1B1B2F);

  static const List<String> expenseCategories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Health',
    'Other',
  ];
  static const List<String> incomeCategories = ['Salary', 'Other'];

  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  bool _isExpense = true;
  String _category = 'Food';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final item = ExpenseItem(
      title: _titleCtrl.text.trim(),
      category: _category,
      amount: double.parse(_amountCtrl.text.trim()),
      date: DateTime.now(),
      isExpense: _isExpense,
    );

    Navigator.pop(context, item);
  }

  InputDecoration _decoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey.shade600),
      filled: true,
      fillColor: const Color(0xFFF3F4F8),
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = _isExpense ? expenseCategories : incomeCategories;

    return Padding(
      // Keyboard ke upar sheet uthane ke liye
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Add transaction',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: dark,
                ),
              ),
              const SizedBox(height: 20),

              // Expense / Income toggle
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: true, label: Text('Expense')),
                    ButtonSegment(value: false, label: Text('Income')),
                  ],
                  selected: {_isExpense},
                  onSelectionChanged: (value) {
                    setState(() {
                      _isExpense = value.first;
                      _category = _isExpense ? 'Food' : 'Salary';
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleCtrl,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: _decoration(
                  'Title (e.g. Lunch)',
                  Icons.edit_outlined,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _decoration('Amount', Icons.payments_outlined),
                validator: (v) {
                  final value = double.tryParse(v?.trim() ?? '');
                  if (value == null) return 'Enter a valid amount';
                  if (value <= 0) return 'Amount must be greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: 18),

              const Text(
                'Category',
                style: TextStyle(fontWeight: FontWeight.w700, color: dark),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((c) {
                  final selected = _category == c;
                  return ChoiceChip(
                    label: Text(c),
                    selected: selected,
                    showCheckmark: false,
                    selectedColor: primary,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : dark,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => setState(() => _category = c),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
