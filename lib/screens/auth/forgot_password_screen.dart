import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../providers/auth_provider.dart';
import '../../core/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  Timer? _timer;
  int _remainingTime = 120; // 2 minutes in seconds
  bool _isCodeSent = false;
  bool _canResendCode = true;
  bool _isEmailValid = true;

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  void _validateEmail() {
    setState(() {
      _isEmailValid = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
          .hasMatch(_emailController.text);
    });
  }

  void _startTimer() {
    setState(() {
      _remainingTime = 120;
      _canResendCode = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() => _remainingTime--);
      } else {
        setState(() => _canResendCode = true);
        timer.cancel();
      }
    });
  }

  Future<void> _sendResetCode() async {
    if (!_formKey.currentState!.validate() || !_isEmailValid) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success =
        await authProvider.sendPasswordResetEmail(_emailController.text.trim());

    if (success) {
      setState(() => _isCodeSent = true);
      _startTimer();

      Get.snackbar(
        'Reset Code Sent',
        'A password reset link has been sent to ${_emailController.text}. Please check your email and follow the instructions.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } else {
      Get.snackbar(
        'Error',
        authProvider.errorMessage ?? 'Failed to send reset code',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _resendCode() async {
    if (_canResendCode) {
      await _sendResetCode();
    }
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),

                    // Icon and Title
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isCodeSent ? Icons.email_outlined : Icons.lock_reset,
                        size: 64,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      _isCodeSent ? 'Check Your Email' : 'Reset Password',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    Text(
                      _isCodeSent
                          ? 'We\'ve sent a password reset link to your email address. Click the link in your email to reset your password.'
                          : 'Enter your email address and we\'ll send you a link to reset your password.',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email Address *',
                        prefixIcon: const Icon(Icons.email),
                        suffixIcon: _emailController.text.isNotEmpty
                            ? Icon(
                                _isEmailValid
                                    ? Icons.check_circle
                                    : Icons.error,
                                color:
                                    _isEmailValid ? Colors.green : Colors.red,
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: _isEmailValid
                                  ? AppTheme.primaryColor
                                  : Colors.red,
                              width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!_isEmailValid) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (value) => _validateEmail(),
                      enabled: !_isCodeSent,
                    ),
                    const SizedBox(height: 24),

                    if (!_isCodeSent) ...[
                      // Send Reset Code Button
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed:
                              authProvider.isLoading ? null : _sendResetCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: authProvider.isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  'Send Reset Link',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ] else ...[
                      // Timer Display
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _remainingTime > 0
                              ? Colors.orange.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _remainingTime > 0
                                ? Colors.orange.withOpacity(0.3)
                                : Colors.green.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _remainingTime > 0
                                  ? Icons.timer
                                  : Icons.check_circle,
                              color: _remainingTime > 0
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _remainingTime > 0
                                  ? 'Link expires in ${_formatTime(_remainingTime)}'
                                  : 'You can now request a new link',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: _remainingTime > 0
                                    ? Colors.orange[700]
                                    : Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Resend Link Button
                      SizedBox(
                        height: 56,
                        child: OutlinedButton(
                          onPressed: _canResendCode ? _resendCode : null,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: _canResendCode
                                  ? AppTheme.primaryColor
                                  : Colors.grey,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _canResendCode
                                ? 'Resend Reset Link'
                                : 'Wait ${_formatTime(_remainingTime)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: _canResendCode
                                  ? AppTheme.primaryColor
                                  : Colors.grey,
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
                          borderRadius: BorderRadius.circular(12),
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
                              '• The reset link expires in 2 minutes\n'
                              '• Click the link in your email to reset password',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Back to Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Remember your password?'),
                        TextButton(
                          onPressed: () => Get.back(),
                          child: const Text(
                            'Back to Login',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
