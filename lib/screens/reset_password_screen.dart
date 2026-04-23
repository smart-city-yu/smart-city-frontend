import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/fake_auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final codeController = TextEditingController();
  final newController = TextEditingController();
  final confirmController = TextEditingController();

  final FakeAuthService _authService = FakeAuthService();

  bool isVerified = false;
  bool isVerifying = false;
  bool isLoading = false;

  @override
  void dispose() {
    codeController.dispose();
    newController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    setState(() {
      isVerifying = true;
    });

    final result = await _authService.verifyResetCode(
      email: widget.email,
      code: codeController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      isVerifying = false;
      isVerified = result['success'];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']),
        backgroundColor: result['success'] ? AppColors.green : AppColors.red,
      ),
    );
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    if (!isVerified) return;

    setState(() {
      isLoading = true;
    });

    final result = await _authService.resetPassword(
      email: widget.email,
      newPassword: newController.text,
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']),
        backgroundColor: result['success'] ? AppColors.green : AppColors.red,
      ),
    );

    if (result['success']) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
            (route) => false,
      );
    }
  }

  InputDecoration input(String text, IconData icon) {
    return InputDecoration(
      labelText: text,
      labelStyle: const TextStyle(
        color: AppColors.textGrey,
        fontSize: 14,
      ),
      prefixIcon: Icon(
        icon,
        color: AppColors.textLight,
      ),
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        title: const Text(
          'Reset Password',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: codeController,
                keyboardType: TextInputType.number,
                decoration: input(
                  'Verification Code',
                  Icons.verified_outlined,
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isVerifying ? null : _verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isVerifying
                      ? const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  )
                      : const Text(
                    'Verify Code',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (isVerified) ...[
                const SizedBox(height: 25),
                TextFormField(
                  controller: newController,
                  obscureText: true,
                  decoration: input(
                    'New Password',
                    Icons.lock_outline,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Enter new password';
                    }
                    if (v.length < 7) {
                      return 'At least 7 characters';
                    }
                    if (!RegExp(r'[A-Z]').hasMatch(v)) {
                      return 'Must contain uppercase letter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: input(
                    'Confirm Password',
                    Icons.lock_outline,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Confirm your password';
                    }
                    if (v != newController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    )
                        : const Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}