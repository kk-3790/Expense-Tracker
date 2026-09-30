import 'dart:async';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/paisa_theme.dart';
import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  StreamSubscription<User?>? _authSubscription;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Auto-redirect to home page immediately when user signs in
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null && mounted) {
        _goToHome();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  bool _hasNavigated = false;

  void _goToHome() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigation()),
      (route) => false,
    );
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.signInWithGoogle();

      if (!mounted) return;

      if (result == null) {
        setState(() {
          _errorMessage = 'Sign-in was cancelled.';
        });
      } else {
        // Immediate redirect to home page
        _goToHome();
        return;
      }
    } catch (e, stack) {
      debugPrint('Google sign-in error: $e\n$stack');
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Google sign-in error:\n$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _continueOffline() {
    AuthService.switchUserSession('guest');
    _goToHome();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: PaisaTheme.background,
      body: Stack(
        children: [
          // Slanted Green Ribbon at top left: * AI Powered * AI Powered *
          Positioned(
            top: 40,
            left: -60,
            child: Transform.rotate(
              angle: -math.pi / 7,
              child: Container(
                width: size.width * 1.3,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: const BoxDecoration(
                  color: PaisaTheme.primaryGreen,
                ),
                child: const Text(
                  '★ AI Powered ★ AI Powered ★ AI Powered ★ AI Powered ★',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),

                  // Floating UI preview cards matching Behance
                  Center(
                    child: SizedBox(
                      height: 180,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Goals preview card (tilted)
                          Transform.translate(
                            offset: const Offset(45, 10),
                            child: Transform.rotate(
                              angle: 0.1,
                              child: Container(
                                width: 140,
                                height: 140,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: PaisaTheme.surface,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                      color: PaisaTheme.surfaceBorder),
                                ),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    const Text('Goals',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11)),
                                    SizedBox(
                                      width: 44,
                                      height: 44,
                                      child: CircularProgressIndicator(
                                        value: 0.2,
                                        strokeWidth: 3.5,
                                        backgroundColor:
                                            PaisaTheme.surfaceBorder,
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                          PaisaTheme.primaryGreen,
                                        ),
                                      ),
                                    ),
                                    const Text('New Bicycle',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // AI Assistant preview card (tilted)
                          Transform.translate(
                            offset: const Offset(-45, -10),
                            child: Transform.rotate(
                              angle: -0.1,
                              child: Container(
                                width: 150,
                                height: 150,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: PaisaTheme.card,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                      color: PaisaTheme.surfaceBorder),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(80),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        RichText(
                                          text: const TextSpan(
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white),
                                            children: [
                                              TextSpan(
                                                text: 'AI ',
                                                style: TextStyle(
                                                    color:
                                                        PaisaTheme.primaryGreen),
                                              ),
                                              TextSpan(text: 'Assistant'),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.chat_bubble_outline,
                                            size: 13,
                                            color: PaisaTheme.textGray),
                                      ],
                                    ),
                                    const Text(
                                      'Get free personal finance assistant from AI.',
                                      style: TextStyle(
                                          fontSize: 9.5,
                                          color: PaisaTheme.textGray),
                                    ),
                                    const Row(
                                      children: [
                                        Text('Start new chat',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.bold)),
                                        Spacer(),
                                        Icon(Icons.north_east_rounded,
                                            size: 12, color: Colors.white),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Headline matching Behance
                  const Text(
                    'Manage your money',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Subtitle matching Behance
                  const Text(
                    "Discover a smarter, goal-driven approach to financial success with Paisa. Let's unlock your financial potential.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: PaisaTheme.textGray,
                    ),
                  ),

                  const Spacer(),

                  // Primary Button matching Behance: Start managing your money now →
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _continueOffline,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Start managing your money now',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded,
                              size: 18, color: Colors.black),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Google Sign-In button
                  Center(
                    child: TextButton.icon(
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      icon: const Text(
                        'G',
                        style: TextStyle(
                          color: Color(0xFF4285F4),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      label: Text(
                        _isLoading ? 'Signing in...' : 'Sign in with Google',
                        style: const TextStyle(
                          color: PaisaTheme.textLightGray,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: PaisaTheme.danger,
                        fontSize: 12,
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}