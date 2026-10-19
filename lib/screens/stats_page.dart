import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:expense_tracker/services/currency_service.dart';
import 'package:expense_tracker/services/finance_service.dart';

class _MonthTotal {
  final DateTime month;
  final double income;
  final double expense;
  const _MonthTotal(this.month, this.income, this.expense);
}

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final _svc = FinanceService.instance;

  late DateTime _month;
  int? _walletId;
  bool _showIncome = false;

  List<Wallet> _wallets = [];
  List<TxItem> _monthTxs = [];
  List<_MonthTotal> _trend = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _month = DateTime(n.year, n.month);
    _svc.changes.addListener(_load);
    CurrencyService.instance.changes.addListener(_currencyChanged);
    _load();
  }

  @override
  void dispose() {
    _svc.changes.removeListener(_load);
    CurrencyService.instance.changes.removeListener(_currencyChanged);
    super.dispose();
  }

  void _currencyChanged() {
    if (mounted) setState(() {});
  }

  bool get _isCurrentMonth {
    final n = DateTime.now();
    return _month.year == n.year && _month.month == n.month;
  }

  Future<void> _load() async {
    try {
      final wallets = await _svc.getWallets();
      if (_walletId != null && !wallets.any((w) => w.id == _walletId)) {
        _walletId = null;
      }

      final start = DateTime(_month.year, _month.month);
      final end = DateTime(_month.year, _month.month + 1);
      final trendStart = DateTime(_month.year, _month.month - 5);

      // Ek hi query: pichle 6 mahine
      final all = await _svc.getTransactionsBetween(
        trendStart,
        end,
        walletId: _walletId,
      );
      final monthTxs = all.where((t) => !t.date.isBefore(start)).toList();

      final trend = <_MonthTotal>[];
      for (var i = 5; i >= 0; i--) {
        final m = DateTime(_month.year, _month.month - i);
        double inc = 0, exp = 0;
        for (final t in all) {
          if (t.date.year == m.year && t.date.month == m.month) {
            if (t.isIncome) {
              inc += t.amount;
            } else {
              exp += t.amount;
            }
          }
        }
        trend.add(_MonthTotal(m, inc, exp));
      }

      if (!mounted) return;
      setState(() {
        _wallets = wallets;
        _monthTxs = monthTxs;
        _trend = trend;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load stats: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _changeMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
    _load();
  }

  double get _income =>
      _monthTxs.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
  double get _expense =>
      _monthTxs.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    const Text(
                      'Statistics',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: kDark,
                      ),
                    ),
                    Text(
                      'See where your money goes',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _monthSelector(),
                    const SizedBox(height: 12),
                    _walletChips(),
                    const SizedBox(height: 16),
                    _summaryRow(),
                    const SizedBox(height: 16),
                    _categoryCard(),
                    const SizedBox(height: 16),
                    _trendCard(),
                    const SizedBox(height: 16),
                    _insightsRow(),
                  ],
                ),
              ),
      ),
    );
  }

  // ---------- month selector ----------
  Widget _monthSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => _changeMonth(-1),
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          '${monthName(_month.month)} ${_month.year}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: kDark,
          ),
        ),
        IconButton(
          onPressed: _isCurrentMonth ? null : () => _changeMonth(1),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  // ---------- wallet filter ----------
  Widget _walletChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip('All wallets', _walletId == null, () {
            setState(() => _walletId = null);
            _load();
          }),
          ..._wallets.map(
            (w) => _chip(w.name, _walletId == w.id, () {
              setState(() => _walletId = w.id);
              _load();
            }),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        selectedColor: kPrimary,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: selected ? Colors.white : kDark,
          fontWeight: FontWeight.w600,
        ),
        onSelected: (_) => onTap(),
      ),
    );
  }

  // ---------- summary ----------
  Widget _summaryRow() {
    final net = _income - _expense;
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            'Income',
            money(_income),
            kIncome,
            Icons.south_west,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryCard(
            'Expense',
            money(_expense),
            kExpense,
            Icons.north_east,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryCard(
            'Saved',
            money(net),
            net >= 0 ? kPrimary : kExpense,
            Icons.savings_outlined,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- category donut ----------
  Widget _categoryCard() {
    final byCat = <String, double>{};
    for (final t in _monthTxs.where((t) => t.isIncome == _showIncome)) {
      byCat[t.category] = (byCat[t.category] ?? 0) + t.amount;
    }
    final entries = byCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<double>(0, (s, e) => s + e.value);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'By category',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: kDark,
                  ),
                ),
              ),
              ChoiceChip(
                label: const Text('Expenses'),
                selected: !_showIncome,
                showCheckmark: false,
                selectedColor: kExpense,
                labelStyle: TextStyle(
                  color: !_showIncome ? Colors.white : kDark,
                  fontSize: 12,
                ),
                onSelected: (_) => setState(() => _showIncome = false),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: const Text('Income'),
                selected: _showIncome,
                showCheckmark: false,
                selectedColor: kIncome,
                labelStyle: TextStyle(
                  color: _showIncome ? Colors.white : kDark,
                  fontSize: 12,
                ),
                onSelected: (_) => setState(() => _showIncome = true),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.pie_chart_outline,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No ${_showIncome ? 'income' : 'expenses'} this month',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Center(
              child: SizedBox(
                width: 190,
                height: 190,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(190, 190),
                      painter: _DonutPainter(
                        values: entries.map((e) => e.value).toList(),
                        colors: entries
                            .map(
                              (e) => Categories.find(
                                e.key,
                                income: _showIncome,
                              ).color,
                            )
                            .toList(),
                        trackColor: const Color(0xFFF1F1F6),
                      ),
                    ),
                    SizedBox(
                      width: 110,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _showIncome ? 'Earned' : 'Spent',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              money(total),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: kDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ...entries.map((e) {
              final info = Categories.find(e.key, income: _showIncome);
              final pct = total == 0 ? 0.0 : e.value / total;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: info.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(info.icon, size: 18, color: info.color),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            e.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: kDark,
                            ),
                          ),
                        ),
                        Text(
                          money(e.value),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: kDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 38,
                          child: Text(
                            '${(pct * 100).toStringAsFixed(0)}%',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        color: info.color,
                        backgroundColor: const Color(0xFFF1F1F6),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ---------- 6 month trend ----------
  Widget _trendCard() {
    final hasData = _trend.any((m) => m.income > 0 || m.expense > 0);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Last 6 months',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: kDark,
                  ),
                ),
              ),
              _legendDot(kIncome, 'Income'),
              const SizedBox(width: 12),
              _legendDot(kExpense, 'Expense'),
            ],
          ),
          const SizedBox(height: 16),
          if (!hasData)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text(
                  'No data yet',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            )
          else
            SizedBox(
              height: 190,
              child: CustomPaint(
                size: Size.infinite,
                painter: _BarPainter(
                  data: _trend,
                  incomeColor: kIncome,
                  expenseColor: kExpense,
                  textColor: Colors.grey.shade600,
                  gridColor: const Color(0xFFEDEDF3),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
        ),
      ],
    );
  }

  // ---------- insights ----------
  Widget _insightsRow() {
    final days = _isCurrentMonth
        ? DateTime.now().day
        : DateTime(_month.year, _month.month + 1, 0).day;
    final avg = days == 0 ? 0.0 : _expense / days;

    return Row(
      children: [
        Expanded(child: _insightTile('Daily average', money(avg), Icons.today)),
        const SizedBox(width: 10),
        Expanded(
          child: _insightTile(
            'Transactions',
            '${_monthTxs.length}',
            Icons.swap_vert,
          ),
        ),
      ],
    );
  }

  Widget _insightTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: kPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: kDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ======================= Painters =======================
void _drawText(
  Canvas canvas,
  String text,
  Offset offset,
  double size,
  Color color, {
  bool center = false,
}) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(fontSize: size, color: color),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(
    canvas,
    center ? Offset(offset.dx - tp.width / 2, offset.dy) : offset,
  );
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final Color trackColor;

  _DonutPainter({
    required this.values,
    required this.colors,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.15;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = trackColor;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    final total = values.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return;

    final gap = values.length > 1 ? 0.04 : 0.0;
    var start = -math.pi / 2;

    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / total * math.pi * 2;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = colors[i % colors.length];
      canvas.drawArc(
        rect,
        start + gap / 2,
        math.max(sweep - gap, 0.001),
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => true;
}

class _BarPainter extends CustomPainter {
  final List<_MonthTotal> data;
  final Color incomeColor;
  final Color expenseColor;
  final Color textColor;
  final Color gridColor;

  _BarPainter({
    required this.data,
    required this.incomeColor,
    required this.expenseColor,
    required this.textColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const left = 36.0, bottom = 22.0, top = 8.0;
    final chartH = size.height - bottom - top;
    final chartW = size.width - left;
    final base = top + chartH;

    var maxV = 1.0;
    for (final d in data) {
      maxV = math.max(maxV, math.max(d.income, d.expense));
    }

    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = top + chartH * i / 3;
      canvas.drawLine(Offset(left, y), Offset(size.width, y), grid);
      _drawText(
        canvas,
        compact(maxV * (1 - i / 3)),
        Offset(0, y - 6),
        9,
        textColor,
      );
    }

    final groupW = chartW / data.length;
    final barW = math.min(16.0, groupW * 0.3);

    for (var i = 0; i < data.length; i++) {
      final cx = left + groupW * i + groupW / 2;

      void bar(double v, double x, Color c) {
        final h = v / maxV * chartH;
        if (h <= 0) return;
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(x, base - h, barW, h),
            topLeft: const Radius.circular(5),
            topRight: const Radius.circular(5),
          ),
          Paint()..color = c,
        );
      }

      bar(data[i].income, cx - barW - 2, incomeColor);
      bar(data[i].expense, cx + 2, expenseColor);

      _drawText(
        canvas,
        shortMonth(data[i].month.month),
        Offset(cx, base + 6),
        10,
        textColor,
        center: true,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) => true;
}
