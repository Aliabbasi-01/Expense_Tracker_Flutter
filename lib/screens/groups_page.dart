import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:expense_tracker/services/currency_service.dart';
import 'package:expense_tracker/services/group_service.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  static const _purple = Color(0xFF5B4BFF);
  static const _ink = Color(0xFF1B1B2F);
  final _groups = GroupService.instance;
  bool _working = false;

  Future<Map<String, String>?> _askForGroup({required bool joining}) async {
    final formKey = GlobalKey<FormState>();
    var name = '';
    var code = '';
    var amount = '0';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        scrollable: true,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        title: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                joining ? Icons.group_add_rounded : Icons.groups_rounded,
                color: _purple,
                size: 25,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    joining ? 'Join a group' : 'Create a group',
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    joining
                        ? 'Team up and share expenses'
                        : 'Make shared spending simple',
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (joining)
                TextFormField(
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 8,
                  decoration: const InputDecoration(
                    labelText: '8-character invite code',
                    prefixIcon: Icon(Icons.key_rounded),
                    counterText: '',
                    filled: true,
                    fillColor: Color(0xFFF6F5FF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                      borderSide: BorderSide(color: Color(0xFFE9E7F5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                      borderSide: BorderSide(color: _purple, width: 1.5),
                    ),
                  ),
                  onSaved: (value) => code = value?.trim().toUpperCase() ?? '',
                  validator: (value) {
                    if (value == null ||
                        !RegExp(r'^[A-HJ-NP-Z2-9]{8}$')
                            .hasMatch(value.trim().toUpperCase())) {
                      return 'Enter a valid 8-character code';
                    }
                    return null;
                  },
                )
              else
                TextFormField(
                  textCapitalization: TextCapitalization.words,
                  maxLength: 40,
                  decoration: const InputDecoration(
                    labelText: 'Group name',
                    prefixIcon: Icon(Icons.groups_rounded),
                    counterText: '',
                    filled: true,
                    fillColor: Color(0xFFF6F5FF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                      borderSide: BorderSide(color: Color(0xFFE9E7F5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                      borderSide: BorderSide(color: _purple, width: 1.5),
                    ),
                  ),
                  onSaved: (value) => name = value?.trim() ?? '',
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a name for the group'
                      : null,
                ),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: '0',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Contribution amount',
                  helperText: joining
                      ? null
                      : 'Optional - add it later if needed',
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                  filled: true,
                  fillColor: const Color(0xFFF6F5FF),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    borderSide: BorderSide(color: Color(0xFFE9E7F5)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    borderSide: BorderSide(color: _purple, width: 1.5),
                  ),
                ),
                onSaved: (value) => amount = value?.trim() ?? '0',
                validator: (value) {
                  final amount = double.tryParse(value?.trim() ?? '');
                  if (amount == null || !amount.isFinite || amount < 0) {
                    return 'Enter zero or a positive amount';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _ink,
                    side: const BorderSide(color: Color(0xFFE4E2ED)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    formKey.currentState!.save();
                    Navigator.pop(dialogContext, {
                      'name': name,
                      'code': code,
                      'amount': amount,
                    });
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(joining ? 'Join group' : 'Create group'),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return result;
  }

  Future<void> _createGroup() async {
    final input = await _askForGroup(joining: false);
    if (input == null || !mounted) return;
    await _perform(() async {
      await _groups.createGroup(
        name: input['name']!,
        currencyCode: CurrencyService.instance.selectedCurrency.code,
        contribution: double.parse(input['amount']!),
      );
    }, success: 'Group created. Share its invite code with your friends.');
  }

  Future<void> _joinGroup() async {
    final input = await _askForGroup(joining: true);
    if (input == null || !mounted) return;
    await _perform(() async {
      await _groups.joinGroup(
        inviteCode: input['code']!,
        contribution: double.parse(input['amount']!),
      );
    }, success: 'You joined the group.');
  }

  Future<void> _perform(
    Future<void> Function() action, {
    required String success,
  }) async {
    setState(() => _working = true);
    try {
      await action();
      if (mounted) _message(success);
    } on FirebaseException catch (error) {
      if (mounted) _message(error.message ?? 'Could not update the group.');
    } catch (error) {
      if (mounted) _message(error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _deleteGroup(GroupSummary group) async {
    if (_working) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this group?'),
        content: Text(
          '"${group.name}" and its shared expenses will be permanently '
          'deleted for every member.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete group',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _working) return;
    await _perform(
      () => _groups.deleteGroup(group.id),
      success: 'Group deleted for all members.',
    );
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shared groups',
                          style: TextStyle(
                            color: _ink,
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Keep everyone in the loop',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Join with an invite code',
                    onPressed: _working ? null : _joinGroup,
                    icon: const Icon(Icons.group_add_outlined),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Create a group',
                    onPressed: _working ? null : _createGroup,
                    style: IconButton.styleFrom(backgroundColor: _purple),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ),
            if (_working) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: StreamBuilder<List<GroupSummary>>(
                stream: _groups.watchGroups(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _messageView(
                      'Could not load your groups: ${snapshot.error}',
                      icon: Icons.cloud_off_outlined,
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final groups = snapshot.data!;
                  if (groups.isEmpty) {
                    return _emptyState();
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    itemCount: groups.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _groupCard(groups[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: _purple.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.groups_rounded, color: _purple, size: 42),
            ),
            const SizedBox(height: 20),
            const Text(
              'Share expenses with friends',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a group or join one with an invite code. Contributions '
              'and expenses update for everyone.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, height: 1.45),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _working ? null : _createGroup,
              icon: const Icon(Icons.add),
              label: const Text('Create your first group'),
              style: FilledButton.styleFrom(backgroundColor: _purple),
            ),
            TextButton(
              onPressed: _working ? null : _joinGroup,
              child: const Text('Join with an invite code'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _groupCard(GroupSummary group) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFEDEBFF),
          foregroundColor: _purple,
          child: Icon(Icons.groups_rounded),
        ),
        title: Text(
          group.name,
          style: const TextStyle(fontWeight: FontWeight.w700, color: _ink),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            '${group.currencyCode}  ·  Invite ${group.inviteCode}',
            style: const TextStyle(color: Colors.black54),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (group.creatorId == FirebaseAuth.instance.currentUser?.uid)
              PopupMenuButton<String>(
                tooltip: 'Group options',
                enabled: !_working,
                onSelected: (value) {
                  if (value == 'delete') _deleteGroup(group);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, color: Colors.red),
                        SizedBox(width: 10),
                        Text('Delete group'),
                      ],
                    ),
                  ),
                ],
              )
            else
              const Icon(Icons.chevron_right_rounded),
          ],
        ),
        onTap: () async {
          final deleted = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => GroupDetailPage(group: group)),
          );
          if (deleted == true && mounted) {
            _message('Group deleted for all members.');
          }
        },
      ),
    );
  }

  Widget _messageView(String text, {required IconData icon}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: Colors.black45),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class GroupDetailPage extends StatefulWidget {
  final GroupSummary group;

  const GroupDetailPage({super.key, required this.group});

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  static const _purple = Color(0xFF5B4BFF);
  final _groups = GroupService.instance;
  bool _working = false;

  String _format(double amount) {
    final value = amount.toStringAsFixed(2);
    return '${widget.group.currencyCode} ${value.endsWith('.00') ? value.substring(0, value.length - 3) : value}';
  }

  Future<void> _addContribution() async {
    final amount = await _askAmount('Add contribution');
    if (amount == null || !mounted) return;
    await _run(
      () => _groups.addContribution(groupId: widget.group.id, amount: amount),
      success: 'Contribution added.',
    );
  }

  Future<double?> _askAmount(String title) async {
    final formKey = GlobalKey<FormState>();
    var amount = '';
    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: Text(title),
        content: Form(
          key: formKey,
          child: TextFormField(
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Amount (${widget.group.currencyCode})',
            ),
            onSaved: (value) => amount = value?.trim() ?? '',
            validator: (value) {
              final amount = double.tryParse(value?.trim() ?? '');
              if (amount == null || !amount.isFinite || amount <= 0) {
                return 'Enter an amount greater than zero';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              formKey.currentState!.save();
              Navigator.pop(dialogContext, double.parse(amount));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    return result;
  }

  Future<void> _addExpense() async {
    final formKey = GlobalKey<FormState>();
    var title = '';
    var amount = '';
    var category = 'Food';

    final input = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          scrollable: true,
          title: const Text('Add a shared expense'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 60,
                  decoration: const InputDecoration(
                    labelText: 'What was it for?',
                    prefixIcon: Icon(Icons.receipt_long_outlined),
                  ),
                  onSaved: (value) => title = value?.trim() ?? '',
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter an expense name'
                      : null,
                ),
                TextFormField(
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount (${widget.group.currencyCode})',
                  ),
                  onSaved: (value) => amount = value?.trim() ?? '',
                  validator: (value) {
                    final amount = double.tryParse(value?.trim() ?? '');
                    if (amount == null || !amount.isFinite || amount <= 0) {
                      return 'Enter an amount greater than zero';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items:
                      const [
                        'Food',
                        'Transport',
                        'Shopping',
                        'Bills',
                        'Travel',
                        'Other',
                      ].map((value) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => category = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                formKey.currentState!.save();
                Navigator.pop(dialogContext, {
                  'title': title,
                  'amount': amount,
                  'category': category,
                });
              },
              child: const Text('Add expense'),
            ),
          ],
        ),
      ),
    );

    if (input == null || !mounted) return;
    await _run(
      () => _groups.addExpense(
        groupId: widget.group.id,
        title: input['title']!,
        category: input['category']!,
        amount: double.parse(input['amount']!),
      ),
      success: 'Shared expense added.',
    );
  }

  Future<void> _run(
    Future<void> Function() action, {
    required String success,
  }) async {
    setState(() => _working = true);
    try {
      await action();
      if (mounted) _showMessage(success);
    } on FirebaseException catch (error) {
      if (mounted) _showMessage(error.message ?? 'Could not update the group.');
    } catch (error) {
      if (mounted) {
        _showMessage(error.toString().replaceFirst('Bad state: ', ''));
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _deleteGroup() async {
    if (_working) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this group?'),
        content: Text(
          '"${widget.group.name}" and all shared expenses will be '
          'permanently deleted for every member.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete group',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _working) return;

    setState(() => _working = true);
    try {
      await _groups.deleteGroup(widget.group.id);
      if (mounted) Navigator.pop(context, true);
    } on FirebaseException catch (error) {
      if (mounted) _showMessage(error.message ?? 'Could not delete the group.');
    } catch (error) {
      if (mounted) {
        _showMessage(error.toString().replaceFirst('Bad state: ', ''));
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _copyInvite() async {
    await Clipboard.setData(ClipboardData(text: widget.group.inviteCode));
    if (mounted) _showMessage('Invite code copied. Send it to your friends.');
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6FA),
        title: Text(
          widget.group.name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          if (widget.group.creatorId == currentUid)
            IconButton(
              tooltip: 'Delete group',
              onPressed: _working ? null : _deleteGroup,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _working ? null : _addExpense,
        backgroundColor: _purple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add expense'),
      ),
      body: StreamBuilder<List<GroupMember>>(
        stream: _groups.watchMembers(widget.group.id),
        builder: (context, memberSnapshot) {
          if (memberSnapshot.hasError) {
            return _errorView('Could not load group members.');
          }
          if (!memberSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final members = memberSnapshot.data!;
          final contributed = members.fold<double>(
            0,
            (total, member) => total + member.contribution,
          );
          final myContribution = members
              .where((member) => member.id == currentUid)
              .fold<double>(0, (total, member) => total + member.contribution);

          return StreamBuilder<List<GroupExpense>>(
            stream: _groups.watchExpenses(widget.group.id),
            builder: (context, expenseSnapshot) {
              if (expenseSnapshot.hasError) {
                return _errorView('Could not load shared expenses.');
              }
              if (!expenseSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final expenses = expenseSnapshot.data!;
              final spent = expenses.fold<double>(
                0,
                (total, expense) => total + expense.amount,
              );
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                children: [
                  _balanceCard(contributed, spent),
                  const SizedBox(height: 14),
                  Card(
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFEDEBFF),
                        foregroundColor: _purple,
                        child: Icon(Icons.key_rounded),
                      ),
                      title: const Text(
                        'Invite friends',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        'Code: ${widget.group.inviteCode}',
                        style: const TextStyle(letterSpacing: 1.2),
                      ),
                      trailing: IconButton(
                        tooltip: 'Copy invite code',
                        onPressed: _copyInvite,
                        icon: const Icon(Icons.copy_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Members',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text('${members.length} people'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...members.map(
                    (member) => ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFEDEBFF),
                        foregroundColor: _purple,
                        child: Text(
                          member.name.isEmpty
                              ? '?'
                              : member.name[0].toUpperCase(),
                        ),
                      ),
                      title: Text(
                        member.id == currentUid
                            ? '${member.name} (you)'
                            : member.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: Text(
                        _format(member.contribution),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _working ? null : _addContribution,
                      icon: const Icon(Icons.add_circle_outline),
                      label: Text(
                        'Add to your contribution (${_format(myContribution)})',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Shared expenses (${expenses.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (expenses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No expenses yet. Add the first one for everyone.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    ...expenses.map(
                      (expense) => Card(
                        color: Colors.white,
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFFFF0E8),
                            foregroundColor: Color(0xFFE87932),
                            child: Icon(Icons.receipt_long_outlined),
                          ),
                          title: Text(
                            expense.title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${expense.category} · ${expense.paidByName} · ${_dateLabel(expense.date)}',
                          ),
                          trailing: Text(
                            _format(expense.amount),
                            style: const TextStyle(
                              color: Color(0xFFE05252),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _balanceCard(double contributed, double spent) {
    final remaining = contributed - spent;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_purple, Color(0xFF9B6BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Group balance',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 5),
          Text(
            _format(remaining),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _balanceStat('Contributed', contributed)),
              Expanded(child: _balanceStat('Spent', spent)),
            ],
          ),
          if (remaining < 0) ...[
            const SizedBox(height: 10),
            const Text(
              'The group has spent more than its contributions.',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _balanceStat(String label, double amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 3),
        Text(
          _format(amount),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _errorView(String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );

  String _dateLabel(DateTime date) => '${date.day}/${date.month}/${date.year}';
}
