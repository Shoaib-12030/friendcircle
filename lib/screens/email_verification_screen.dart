import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../providers/auth_provider.dart';
import '../core/app_theme.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _timer;
  bool _isEmailVerified = false;
  bool _canResendEmail = true;
  int _resendCooldown = 0;

  @override
  void initState() {
    super.initState();
    _checkEmailVerification();
    _startEmailVerificationTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startEmailVerificationTimer() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isVerified = await authProvider.checkEmailVerification();

      if (isVerified && !_isEmailVerified) {
        setState(() => _isEmailVerified = true);
        _timer?.cancel();

        Get.snackbar(
          'Email Verified!',
          'Your email has been verified successfully.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Redirect to main screen after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          Get.offAllNamed('/main');
        });
      }
    });
  }

  Future<void> _checkEmailVerification() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isVerified = await authProvider.checkEmailVerification();
    setState(() => _isEmailVerified = isVerified);

    if (isVerified) {
      Get.offAllNamed('/main');
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResendEmail) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.sendEmailVerification();

    setState(() {
      _canResendEmail = false;
      _resendCooldown = 60; // 60 seconds cooldown
    });

    Get.snackbar(
      'Email Sent',
      'Verification email has been sent to your email address.',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );

    // Start cooldown timer
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        setState(() => _canResendEmail = true);
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Verify Email'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Prevent back navigation
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    kToolbarHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Email verification icon
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _isEmailVerified
                            ? Colors.green.withOpacity(0.1)
                            : AppTheme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isEmailVerified
                            ? Icons.check_circle
                            : Icons.email_outlined,
                        size: 64,
                        color: _isEmailVerified
                            ? Colors.green
                            : AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      _isEmailVerified
                          ? 'Email Verified!'
                          : 'Verify Your Email',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // Description
                    Text(
                      _isEmailVerified
                          ? 'Your email has been successfully verified. You can now access all features of Friend Circle.'
                          : 'We\'ve sent a verification email to your email address. Please check your inbox and click the verification link.',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // User email
                    if (authProvider.currentUser?.email != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          authProvider.currentUser!.email,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    if (!_isEmailVerified) ...[
                      // Checking animation
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryColor),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Checking verification status...',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Resend email button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed:
                              _canResendEmail ? _resendVerificationEmail : null,
                          style: OutlinedButton.styleFrom(
                            side:
                                const BorderSide(color: AppTheme.primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            _canResendEmail
                                ? 'Resend Verification Email'
                                : 'Resend in ${_resendCooldown}s',
                            style: TextStyle(
                              color: _canResendEmail
                                  ? AppTheme.primaryColor
                                  : Colors.grey,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tips
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.blue, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Tips:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '• Check your spam or junk folder\n'
                              '• Make sure your email address is correct\n'
                              '• The verification link expires in 24 hours\n'
                              '• Close and reopen your email app if needed',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Success message with continue button
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Redirecting to your dashboard...',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Sign out option
                    TextButton(
                      onPressed: () async {
                        await authProvider.signOut();
                        Get.offAllNamed('/login');
                      },
                      child: const Text(
                        'Sign Out',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
