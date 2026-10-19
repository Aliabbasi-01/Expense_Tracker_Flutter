import 'package:flutter/material.dart';

import 'package:expense_tracker/services/currency_service.dart';
import 'package:expense_tracker/services/finance_service.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final _svc = FinanceService.instance;

  List<Wallet> _wallets = [];
  List<TxItem> _txs = [];
  int? _selectedWalletId;
  bool _loading = true;

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

  Future<void> _load() async {
    try {
      final wallets = await _svc.getWallets();
      if (_selectedWalletId != null &&
          !wallets.any((w) => w.id == _selectedWalletId)) {
        _selectedWalletId = null;
      }
      final txs = await _svc.getTransactions(walletId: _selectedWalletId);
      if (!mounted) return;
      setState(() {
        _wallets = wallets;
        _txs = txs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack('Could not load data: $e', error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? Colors.redAccent : null,
        ),
      );
  }

  Future<bool?> _confirm(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- sheets ----------
  Future<void> _openTxSheet() async {
    if (_wallets.isEmpty) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _TxSheet(
        wallets: _wallets,
        initialWalletId: _selectedWalletId ?? _wallets.first.id,
      ),
    );
    if (saved == true && mounted) _snack('Transaction added');
  }

  Future<void> _openWalletSheet([Wallet? wallet]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _WalletSheet(wallet: wallet),
    );
    if (saved == true && mounted) {
      _snack(wallet == null ? 'Wallet added' : 'Wallet updated');
    }
  }

  Future<void> _deleteWallet(Wallet w) async {
    if (_wallets.length <= 1) {
      _snack('You need at least one wallet', error: true);
      return;
    }
    final ok = await _confirm(
      'Delete "${w.name}"?',
      'All transactions in this wallet will be deleted too.',
    );
    if (ok != true) return;
    await _svc.deleteWallet(w.id);
  }

  Future<void> _deleteTransaction(
    TxItem transaction, {
    bool confirm = true,
    bool dismissed = false,
  }) async {
    if (confirm &&
        await _confirm(
              'Delete transaction?',
              'This transaction will be permanently deleted.',
            ) !=
            true) {
      return;
    }
    if (dismissed && mounted) {
      setState(() => _txs.removeWhere((item) => item.id == transaction.id));
    }
    try {
      await _svc.deleteTransaction(transaction.id);
      if (mounted) _snack('Transaction deleted');
    } catch (error) {
      if (!mounted) return;
      _snack('Could not delete transaction: $error', error: true);
      _load();
    }
  }

  // ---------- build ----------
  @override
  Widget build(BuildContext context) {
    final total = _wallets.fold<double>(0, (s, w) => s + w.balance);
    final selected = _selectedWalletId == null
        ? null
        : _wallets.where((w) => w.id == _selectedWalletId).firstOrNull;

    return Scaffold(
      backgroundColor: kBackground,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openTxSheet,
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  children: [
                    // Header
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Wallet',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: kDark,
                                ),
                              ),
                              Text(
                                'Manage your money',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          tooltip: 'Add wallet',
                          onPressed: () => _openWalletSheet(),
                          icon: const Icon(Icons.add_card),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Total balance
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5B4BFF), Color(0xFF9B6BFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: kPrimary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total balance',
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              money(total),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${_wallets.length} ${_wallets.length == 1 ? 'wallet' : 'wallets'}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Wallet cards
                    const Text(
                      'Your wallets',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: kDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 140,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _wallets.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (_, i) {
                          if (i == _wallets.length) return _addWalletCard();
                          return _walletCard(_wallets[i]);
                        },
                      ),
                    ),
                    const SizedBox(height: 26),

                    // Transactions header
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selected == null
                                ? 'Recent transactions'
                                : '${selected.name} transactions',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: kDark,
                            ),
                          ),
                        ),
                        if (selected != null)
                          TextButton(
                            onPressed: () {
                              setState(() => _selectedWalletId = null);
                              _load();
                            },
                            child: const Text('Show all'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_txs.isEmpty) _emptyState() else ..._txs.map(_txTile),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _walletCard(Wallet w) {
    final isSelected = _selectedWalletId == w.id;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedWalletId = isSelected ? null : w.id);
        _load();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 210,
        padding: const EdgeInsets.fromLTRB(16, 12, 6, 16),
        decoration: BoxDecoration(
          color: Color(w.color),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? kDark : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(w.color).withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(w.icon, color: Colors.white, size: 20),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  iconColor: Colors.white,
                  onSelected: (v) {
                    if (v == 'edit') _openWalletSheet(w);
                    if (v == 'delete') _deleteWallet(w);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${w.name} · ${WalletTypes.label(w.type)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      money(w.balance),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _addWalletCard() {
    return GestureDetector(
      onTap: () => _openWalletSheet(),
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              color: Colors.grey.shade600,
              size: 30,
            ),
            const SizedBox(height: 6),
            Text(
              'New wallet',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.receipt_long, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'No transactions yet',
            style: TextStyle(fontWeight: FontWeight.w700, color: kDark),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap "Add" to record your first one',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _txTile(TxItem t) {
    final cat = Categories.find(t.category, income: t.isIncome);
    final color = t.isIncome ? kIncome : kExpense;

    return Dismissible(
      key: ValueKey('tx_${t.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) =>
          _confirm('Delete transaction?', 'This cannot be undone.'),
      onDismissed: (_) =>
          _deleteTransaction(t, confirm: false, dismissed: true),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cat.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(cat.icon, color: cat.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.note.isEmpty ? t.category : t.note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: kDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${t.category} · ${t.walletName} · ${friendlyDate(t.date)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${t.isIncome ? '+' : '-'}${money(t.amount)}',
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
            IconButton(
              tooltip: 'Delete transaction',
              onPressed: () => _deleteTransaction(t),
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

// ======================= Add transaction sheet =======================
class _TxSheet extends StatefulWidget {
  final List<Wallet> wallets;
  final int initialWalletId;

  const _TxSheet({required this.wallets, required this.initialWalletId});

  @override
  State<_TxSheet> createState() => _TxSheetState();
}

class _TxSheetState extends State<_TxSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  bool _isIncome = false;
  String _category = Categories.expense.first.name;
  late int _walletId = widget.initialWalletId;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _setType(bool income) {
    setState(() {
      _isIncome = income;
      _category = (income ? Categories.income : Categories.expense).first.name;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final amount = CurrencyService.instance.convertToBase(
        double.parse(_amountCtrl.text.trim().replaceAll(',', '')),
      );
      final now = DateTime.now();
      final dt = DateTime(
        _date.year,
        _date.month,
        _date.day,
        now.hour,
        now.minute,
        now.second,
      );

      await FinanceService.instance.addTransaction(
        walletId: _walletId,
        isIncome: _isIncome,
        amount: amount,
        category: _category,
        note: _noteCtrl.text,
        date: dt,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _typeButton(String label, bool income) {
    final active = _isIncome == income;
    final color = income ? kIncome : kExpense;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setType(income),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: active ? color : const Color(0xFFF3F4F8),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : kDark,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cats = _isIncome ? Categories.income : Categories.expense;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
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
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Add transaction',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: kDark,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _typeButton('Expense', false),
                  const SizedBox(width: 10),
                  _typeButton('Income', true),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration:
                    fieldDecoration(
                      'Amount (${CurrencyService.instance.selectedCode})',
                      Icons.payments_outlined,
                    ).copyWith(
                      prefixText:
                          '${CurrencyService.instance.selectedCurrency.symbol} ',
                    ),
                validator: (v) {
                  final n = double.tryParse(
                    (v ?? '').trim().replaceAll(',', ''),
                  );
                  if (n == null || n <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Category',
                style: TextStyle(fontWeight: FontWeight.w700, color: kDark),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: cats.map((c) {
                  final sel = _category == c.name;
                  return ChoiceChip(
                    avatar: Icon(
                      c.icon,
                      size: 18,
                      color: sel ? Colors.white : c.color,
                    ),
                    label: Text(c.name),
                    selected: sel,
                    showCheckmark: false,
                    selectedColor: c.color,
                    labelStyle: TextStyle(color: sel ? Colors.white : kDark),
                    onSelected: (_) => setState(() => _category = c.name),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _walletId,
                decoration: fieldDecoration(
                  'Wallet',
                  Icons.account_balance_wallet_outlined,
                ),
                items: widget.wallets
                    .map(
                      (w) => DropdownMenuItem(
                        value: w.id,
                        child: Text('${w.name} (${money(w.balance)})'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _walletId = v ?? _walletId),
              ),
              const SizedBox(height: 16),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        friendlyDate(_date),
                        style: const TextStyle(color: kDark),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: fieldDecoration(
                  'Note (optional)',
                  Icons.notes_outlined,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
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

// ======================= Add / edit wallet sheet =======================
class _WalletSheet extends StatefulWidget {
  final Wallet? wallet;
  const _WalletSheet({this.wallet});

  @override
  State<_WalletSheet> createState() => _WalletSheetState();
}

class _WalletSheetState extends State<_WalletSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(text: widget.wallet?.name ?? '');
  late final _balanceCtrl = TextEditingController(
    text: widget.wallet == null || widget.wallet!.initialBalance == 0
        ? ''
        : CurrencyService.instance
              .convertFromBase(widget.wallet!.initialBalance)
              .toStringAsFixed(
                CurrencyService.instance.selectedCurrency.decimalDigits,
              ),
  );

  late String _type = widget.wallet?.type ?? 'cash';
  late int _color = widget.wallet?.color ?? kWalletColors.first;
  bool _saving = false;

  bool get _editing => widget.wallet != null;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final balance =
          double.tryParse(_balanceCtrl.text.trim().replaceAll(',', '')) ?? 0;
      final svc = FinanceService.instance;
      final baseBalance = CurrencyService.instance.convertToBase(balance);

      if (_editing) {
        await svc.updateWallet(
          id: widget.wallet!.id,
          name: _nameCtrl.text,
          type: _type,
          initialBalance: baseBalance,
          color: _color,
        );
      } else {
        await svc.addWallet(
          name: _nameCtrl.text,
          type: _type,
          initialBalance: baseBalance,
          color: _color,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
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
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _editing ? 'Edit wallet' : 'New wallet',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: kDark,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: fieldDecoration(
                  'Wallet name (e.g. JazzCash)',
                  Icons.label_outline,
                ),
                validator: (v) {
                  if ((v ?? '').trim().isEmpty) return 'Enter a wallet name';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Type',
                style: TextStyle(fontWeight: FontWeight.w700, color: kDark),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: WalletTypes.keys.map((k) {
                  final sel = _type == k;
                  return ChoiceChip(
                    avatar: Icon(
                      WalletTypes.icon(k),
                      size: 18,
                      color: sel ? Colors.white : kDark,
                    ),
                    label: Text(WalletTypes.label(k)),
                    selected: sel,
                    showCheckmark: false,
                    selectedColor: kPrimary,
                    labelStyle: TextStyle(color: sel ? Colors.white : kDark),
                    onSelected: (_) => setState(() => _type = k),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _balanceCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration:
                    fieldDecoration(
                      'Starting balance (${CurrencyService.instance.selectedCode})',
                      Icons.savings_outlined,
                    ).copyWith(
                      prefixText:
                          '${CurrencyService.instance.selectedCurrency.symbol} ',
                    ),
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return null;
                  if (double.tryParse(t.replaceAll(',', '')) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Color',
                style: TextStyle(fontWeight: FontWeight.w700, color: kDark),
              ),
              const SizedBox(height: 10),
              Row(
                children: kWalletColors.map((c) {
                  final sel = _color == c;
                  return GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: sel ? kDark : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: sel
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _editing ? 'Update wallet' : 'Create wallet',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
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

/// Dashboard (Home) se bhi wahi "Add transaction" sheet kholne ke liye.
Future<bool?> showAddTransactionSheet(
  BuildContext context,
  List<Wallet> wallets, {
  int? initialWalletId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _TxSheet(
      wallets: wallets,
      initialWalletId: initialWalletId ?? wallets.first.id,
    ),
  );
}
