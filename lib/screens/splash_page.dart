import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:expense_tracker/screens/dashboard_page.dart';
import 'package:expense_tracker/services/auth_service.dart';
import 'package:expense_tracker/services/currency_service.dart';
import 'package:expense_tracker/services/finance_service.dart';

import 'login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  static const _minimumDuration = Duration(seconds: 5);
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  final Stopwatch _splashTimer = Stopwatch()..start();
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    // Logo ki animation: halka sa fade in aur bara hona
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scale = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      final user = await AuthService.instance.restoreSession();
      if (!mounted) return;

      if (user == null) {
        await _open(const LoginPage());
        return;
      }

      await CurrencyService.instance.initialize(
        user['currency_code'] as String? ?? 'PKR',
      );
      Session.userId = user['id'] as int;
      Session.userName = user['name'] as String;
      Session.userEmail = user['email'] as String;
      if (mounted) await _open(const DashboardPage());
    } catch (error) {
      if (!mounted) return;
      await _waitForMinimumDuration();
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _open(Widget page) async {
    await _waitForMinimumDuration();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _waitForMinimumDuration() async {
    final remaining = _minimumDuration - _splashTimer.elapsed;
    if (remaining > Duration.zero) await Future<void>.delayed(remaining);
  }

  Future<void> _retry() async {
    setState(() {
      _error = null;
      _loading = true;
      _splashTimer
        ..reset()
        ..start();
    });
    await _bootstrap();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF191342),
                  Color(0xFF4535C7),
                  Color(0xFF7957DB),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SizedBox.expand(),
          ),
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.045),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -110,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1.5,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      scale: _scale,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(19),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.13),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.24),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF120C3A)
                                      .withValues(alpha: 0.2),
                                  blurRadius: 32,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            child: Container(
                              width: 102,
                              height: 102,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                size: 52,
                                color: Color(0xFF5B4BFF),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          const Text(
                            'Expense Tracker',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 31,
                              letterSpacing: -0.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 9),
                          Text(
                            'Make every rupee count.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.78),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                  if (_loading)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 17,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 23,
                            height: 23,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Getting things ready',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Your finances, all in one place',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.cloud_off_rounded,
                            color: Color(0xFF5B4BFF),
                            size: 30,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Setup needed',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Firebase is required to sign in and sync groups.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _error ??
                                'Please check your Firebase configuration.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black45,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _retry,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Try again'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF5B4BFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 34),
                  Text(
                    'PLAN  •  TRACK  •  GROW',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.58),
                      letterSpacing: 2.1,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
