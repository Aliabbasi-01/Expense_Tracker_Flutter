import 'package:flutter/material.dart';

import 'package:expense_tracker/screens/groups_page.dart';
import 'package:expense_tracker/screens/stats_page.dart';
import 'package:expense_tracker/screens/wallet_page.dart';
import 'package:expense_tracker/services/currency_service.dart';
import 'package:expense_tracker/services/finance_service.dart';

import 'profile_page.dart';

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

  final _svc = FinanceService.instance;

  int _navIndex = 0;
  bool _loading = true;

  List<Wallet> _wallets = [];
  List<TxItem> _recent = [];
  List<TxItem> _monthTxs = [];
  List<TxItem> _weekTxs = [];
  int _txCount = 0;

  String get _userName {
    final name = Session.userName?.trim() ?? '';
    return name.isEmpty ? 'there' : name;
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  void initState() {
    super.initState();
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

  // ---------- Data ----------

  Future<void> _load() async {
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month);
      final monthEnd = DateTime(now.year, now.month + 1);
      final weekStart = DateTime(now.year, now.month, now.day - 6);
      final tomorrow = DateTime(now.year, now.month, now.day + 1);

      final wallets = await _svc.getWallets();
      final recent = await _svc.getTransactions(limit: 10);
      final monthTxs = await _svc.getTransactionsBetween(monthStart, monthEnd);
      final weekTxs = await _svc.getTransactionsBetween(weekStart, tomorrow);
      final count = await _svc.countTransactions();

      if (!mounted) return;
      setState(() {
        _wallets = wallets;
        _recent = recent;
        _monthTxs = monthTxs;
        _weekTxs = weekTxs;
        _txCount = count;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load data: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ---------- Calculations ----------

  double get _balance => _wallets.fold<double>(0, (s, w) => s + w.balance);

  double get _income => _monthTxs
      .where((e) => e.isIncome)
      .fold<double>(0, (sum, e) => sum + e.amount);

  double get _expense => _monthTxs
      .where((e) => !e.isIncome)
      .fold<double>(0, (sum, e) => sum + e.amount);

  Map<String, double> get _categoryTotals {
    final map = <String, double>{};
    for (final e in _monthTxs.where((e) => !e.isIncome)) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  // ---------- Actions ----------

  Future<void> _openAddSheet() async {
    if (_wallets.isEmpty) return;
    final saved = await showAddTransactionSheet(context, _wallets);
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction added'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<bool?> _confirmDelete(TxItem item) {
    final title = item.note.isEmpty ? item.category : item.note;
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: Text('"$title" will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(
    TxItem item, {
    bool confirm = true,
    bool dismissed = false,
  }) async {
    if (confirm && await _confirmDelete(item) != true) return;
    if (dismissed && mounted) {
      setState(() => _recent.removeWhere((e) => e.id == item.id));
    }
    try {
      await _svc.deleteTransaction(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction deleted'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete transaction: $error'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _load();
    }
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfilePage(
          name: Session.userName ?? 'User',
          email: Session.userEmail ?? '',
          transactionCount: _txCount,
          income: _income,
          expense: _expense,
        ),
      ),
    );
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      // Stats aur Wallet screens ka apna layout hai, FAB sirf Home par
      floatingActionButton: _navIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _openAddSheet,
              backgroundColor: primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Add',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: primary.withValues(alpha: 0.15),
        selectedIndex: _navIndex,
        onDestinationSelected: (i) {
          if (i == 4) {
            // Profile tab: nayi screen kholo
            _openProfile();
          } else {
            setState(() => _navIndex = i);
          }
        },
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
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded, color: primary),
            label: 'Groups',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded, color: primary),
            label: 'Profile',
          ),
        ],
      ),
      body: IndexedStack(
        index: _navIndex,
        children: [
          _homeTab(),
          const StatsPage(),
          const WalletPage(),
          const GroupsPage(),
        ],
      ),
    );
  }

  Widget _homeTab() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                  const SizedBox(height: 22),
                  _groupsFeatureCard(),
                  const SizedBox(height: 28),
                  _sectionTitle('Last 7 days'),
                  const SizedBox(height: 12),
                  _weeklyChart(),
                  const SizedBox(height: 28),
                  _sectionTitle('Top spending (this month)'),
                  const SizedBox(height: 12),
                  _topCategories(),
                  const SizedBox(height: 28),
                  _sectionTitle('Recent transactions'),
                  const SizedBox(height: 12),
                  if (_recent.isEmpty)
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
                    ..._recent.map(_transactionTile),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final initial = _userName.isNotEmpty ? _userName[0].toUpperCase() : '?';

    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF5B4BFF), Color(0xFF9B6BFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: dark,
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Open profile',
          onPressed: _openProfile,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: dark,
            fixedSize: const Size(46, 46),
          ),
          icon: const Icon(Icons.person_outline_rounded),
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
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              money(_balance),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'This month',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 16),
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

  Widget _groupsFeatureCard() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        onTap: () => setState(() => _navIndex = 3),
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF25234A), Color(0xFF5143C7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5143C7).withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -12,
                top: -18,
                child: Icon(
                  Icons.groups_rounded,
                  size: 128,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.groups_rounded,
                          color: Colors.white,
                          size: 25,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SHARED GROUPS',
                              style: TextStyle(
                                color: Color(0xFFD8D3FF),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.3,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Better together',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white70,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Share expenses, track contributions and stay in sync with your people.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Explore groups',
                          style: TextStyle(
                            color: Color(0xFF3D35A6),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(width: 7),
                        Icon(
                          Icons.north_east_rounded,
                          color: Color(0xFF3D35A6),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
          (d) => _weekTxs
              .where((e) => !e.isIncome && sameDay(e.date, d))
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
                final info = Categories.find(entry.key, income: false);
                final color = info.color;

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
                        child: Icon(info.icon, color: color, size: 20),
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

  Widget _transactionTile(TxItem item) {
    final info = Categories.find(item.category, income: item.isIncome);
    final color = info.color;
    final title = item.note.isEmpty ? item.category : item.note;

    return Dismissible(
      key: ValueKey('home_tx_${item.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(item),
      onDismissed: (_) => _deleteItem(item, confirm: false, dismissed: true),
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
              child: Icon(info.icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: dark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${item.category} • ${item.walletName} • ${friendlyDate(item.date)}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${item.isIncome ? '+' : '-'}${money(item.amount)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: item.isIncome
                    ? const Color(0xFF26A69A)
                    : Colors.redAccent,
              ),
            ),
            IconButton(
              tooltip: 'Delete transaction',
              onPressed: () => _deleteItem(item),
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.redAccent,
                size: 21,
              ),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
