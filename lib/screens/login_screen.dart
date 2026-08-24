import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result =
      await _authService.signInWithGoogle();

      if (!mounted) return;

      if (result == null) {
        setState(() {
          _errorMessage =
          'Sign-in was cancelled.';
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
        'Google sign-in failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final foreground =
        Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
            const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment.center,
              children: [
                // LOGO
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB7F23D),
                    borderRadius:
                    BorderRadius.circular(30),
                  ),
                  padding:
                  const EdgeInsets.all(12),
                  child: ClipRRect(
                    borderRadius:
                    BorderRadius.circular(22),
                    child: Image.asset(
                      'assets/icon/expense_tracker_logo.png',
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) {
                        return const Icon(
                          Icons
                              .account_balance_wallet_rounded,
                          size: 52,
                          color: Color(0xFF172A35),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  'Expense Tracker',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: foreground,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Take control of your money.\n'
                      'Track every expense with ease.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark
                        ? const Color(0xFFB7C0B5)
                        : const Color(0xFF737B6E),
                  ),
                ),

                const SizedBox(height: 48),

                // GOOGLE BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : _signInWithGoogle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF24332F)
                          : Colors.white,
                      foregroundColor: foreground,
                      disabledBackgroundColor:
                      isDark
                          ? const Color(0xFF202C29)
                          : const Color(0xFFE6E9E0),
                      elevation: 0,
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(18),
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF34433F)
                              : const Color(0xFFDCE2D4),
                        ),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 23,
                      height: 23,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2.5,
                      ),
                    )
                        : Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        const Text(
                          'G',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight:
                            FontWeight.w700,
                            color:
                            Color(0xFF4285F4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Continue with Google',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 18),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFB3261E),
                      fontSize: 13,
                    ),
                  ),
                ],

                const SizedBox(height: 40),

                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 15,
                      color: isDark
                          ? const Color(0xFF899A91)
                          : const Color(0xFF899181),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Secure authentication with Google',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? const Color(0xFF899A91)
                            : const Color(0xFF899181),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}