import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/user_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final currentController = TextEditingController();
  final newController = TextEditingController();
  final confirmController = TextEditingController();

  final UserService _userService = UserService();

  bool hideCurrent = true;
  bool hideNew = true;
  bool hideConfirm = true;
  bool isLoading = false;

  @override
  void dispose() {
    currentController.dispose();
    newController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    final result = await _userService.changePassword(
      currentPassword: currentController.text,
      newPassword: newController.text,
      confirmPassword: confirmController.text,
    );

    setState(() {
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']),
        backgroundColor: result['success'] ? AppColors.green : AppColors.red,
      ),
    );

    if (result['success'] == true) {
      Navigator.pop(context);
    }
  }

  InputDecoration input(String text, bool hide, VoidCallback toggle) {
    return InputDecoration(
      labelText: text,
      labelStyle: const TextStyle(
        color: AppColors.textGrey,
        fontSize: 14,
      ),
      prefixIcon: const Icon(
        Icons.lock_outline,
        color: AppColors.textLight,
      ),
      suffixIcon: IconButton(
        icon: Icon(
          hide ? Icons.visibility_off : Icons.visibility,
          color: AppColors.textLight,
        ),
        onPressed: toggle,
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
          'Change Password',
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
                controller: currentController,
                obscureText: hideCurrent,
                decoration: input('Current Password', hideCurrent, () {
                  setState(() => hideCurrent = !hideCurrent);
                }),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Enter current password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: newController,
                obscureText: hideNew,
                decoration: input('New Password', hideNew, () {
                  setState(() => hideNew = !hideNew);
                }),
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
                obscureText: hideConfirm,
                decoration: input('Confirm Password', hideConfirm, () {
                  setState(() => hideConfirm = !hideConfirm);
                }),
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
                  onPressed: isLoading ? null : _changePassword,
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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