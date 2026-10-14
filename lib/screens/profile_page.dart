import 'package:flutter/material.dart';

import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  final String name;
  final String email;
  final int transactionCount;
  final String incomeText;
  final String expenseText;

  const ProfilePage({
    super.key,
    required this.name,
    required this.email,
    required this.transactionCount,
    required this.incomeText,
    required this.expenseText,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color primary = Color(0xFF5B4BFF);
  static const Color dark = Color(0xFF1B1B2F);
  static const Color background = Color(0xFFF5F6FA);

  late String _name;
  late String _email;
  bool _notifications = true;

  @override
  void initState() {
    super.initState();
    // Dashboard se aaya hua data yahan copy kar liya taake edit ho sake
    _name = widget.name;
    _email = widget.email;
  }

  // ---------- Actions ----------

  InputDecoration _fieldStyle(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey.shade600),
      filled: true,
      fillColor: const Color(0xFFF3F4F8),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
    );
  }

  Future<void> _editProfile() async {
    String newName = _name;
    String newEmail = _email;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Edit profile',
          style: TextStyle(fontWeight: FontWeight.w800, color: dark),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: _name,
              textCapitalization: TextCapitalization.words,
              onChanged: (v) => newName = v,
              decoration: _fieldStyle('Full name', Icons.person_outline),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _email,
              keyboardType: TextInputType.emailAddress,
              onChanged: (v) => newEmail = v,
              decoration: _fieldStyle('Email address', Icons.mail_outline),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true &&
        newName.trim().isNotEmpty &&
        newEmail.trim().isNotEmpty) {
      setState(() {
        _name = newName.trim();
        _email = newEmail.trim();
      });
    }
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Log out?',
          style: TextStyle(fontWeight: FontWeight.w800, color: dark),
        ),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    // Purani saari screens hata kar sirf Login rakho,
    // taake back dabane par dashboard wapas na aaye
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final initial = _name.isNotEmpty ? _name[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _header(initial),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _statsRow(),
                      const SizedBox(height: 28),
                      _sectionTitle('Account'),
                      const SizedBox(height: 12),
                      _settingsCard([
                        _tile(
                          icon: Icons.person_outline_rounded,
                          title: 'Edit profile',
                          onTap: _editProfile,
                        ),
                        _tile(
                          icon: Icons.lock_outline_rounded,
                          title: 'Change password',
                          onTap: () => _comingSoon('Change password'),
                        ),
                        _tile(
                          icon: Icons.payments_outlined,
                          title: 'Currency',
                          trailingText: 'PKR (Rs)',
                          onTap: () => _comingSoon('Currency'),
                        ),
                      ]),
                      const SizedBox(height: 28),
                      _sectionTitle('Preferences'),
                      const SizedBox(height: 12),
                      _settingsCard([
                        _tile(
                          icon: Icons.notifications_none_rounded,
                          title: 'Notifications',
                          trailing: Switch(
                            value: _notifications,
                            onChanged: (v) =>
                                setState(() => _notifications = v),
                          ),
                          onTap: () =>
                              setState(() => _notifications = !_notifications),
                        ),
                        _tile(
                          icon: Icons.help_outline_rounded,
                          title: 'Help & support',
                          onTap: () => _comingSoon('Help & support'),
                        ),
                        _tile(
                          icon: Icons.info_outline_rounded,
                          title: 'About',
                          trailingText: 'v1.0.0',
                          onTap: () => _comingSoon('About'),
                        ),
                      ]),
                      const SizedBox(height: 28),

                      // Logout button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text(
                            'Log out',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(
                              color: Colors.redAccent,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(String initial) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5B4BFF), Color(0xFF9B6BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
          child: Column(
            children: [
              // Back button aur title
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _editProfile,
                    icon: const Icon(Icons.edit_rounded, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Avatar
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 46,
                  backgroundColor: primary.withValues(alpha: 0.15),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _email,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statsRow() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.receipt_long_rounded,
            color: primary,
            label: 'Transactions',
            value: '${widget.transactionCount}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            icon: Icons.arrow_downward_rounded,
            color: const Color(0xFF26A69A),
            label: 'Income',
            value: widget.incomeText,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            icon: Icons.arrow_upward_rounded,
            color: Colors.redAccent,
            label: 'Expenses',
            value: widget.expenseText,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: dark,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
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

  Widget _settingsCard(List<Widget> tiles) {
    final children = <Widget>[];
    for (int i = 0; i < tiles.length; i++) {
      children.add(tiles[i]);
      // Tiles ke beech patli line
      if (i != tiles.length - 1) {
        children.add(
          Divider(height: 1, indent: 68, color: Colors.grey.shade200),
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? trailingText,
    Widget? trailing,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: primary, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, color: dark),
      ),
      trailing:
          trailing ??
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trailingText != null)
                Text(
                  trailingText,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade500),
            ],
          ),
    );
  }
}
