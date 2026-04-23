class FakeAuthService {
  static const String correctEmail = 'leen@test.com';
  static const String takenEmail = 'used@test.com';
  static const String resetCode = '123456';

  static String currentPassword = '123456L';

  Future<Map<String, dynamic>> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 2));

    String cleanEmail = email.trim().toLowerCase();

    if (cleanEmail == correctEmail && password == currentPassword) {
      return {
        'success': true,
        'message': 'Logged in successfully.',
        'data': {
          'email': cleanEmail,
        },
      };
    }

    return {
      'success': false,
      'message': 'Incorrect email or password.',
      'data': null,
    };
  }

  Future<Map<String, dynamic>> register(
      String name,
      String email,
      String password,
      ) async {
    await Future.delayed(const Duration(seconds: 2));

    String cleanEmail = email.trim().toLowerCase();

    if (name.trim().isEmpty) {
      return {
        'success': false,
        'message': 'Name is required.',
        'data': null,
      };
    }

    if (cleanEmail == takenEmail) {
      return {
        'success': false,
        'message': 'This email is already registered.',
        'data': null,
      };
    }

    return {
      'success': true,
      'message': 'Account created! Please sign in.',
      'data': {
        'name': name.trim(),
        'email': cleanEmail,
      },
    };
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(seconds: 2));

    if (currentPassword.isEmpty || newPassword.isEmpty) {
      return {
        'success': false,
        'message': 'Please fill all fields',
        'data': null,
      };
    }

    if (currentPassword != FakeAuthService.currentPassword) {
      return {
        'success': false,
        'message': 'Current password is incorrect',
        'data': null,
      };
    }

    if (newPassword.length < 7) {
      return {
        'success': false,
        'message': 'At least 7 characters',
        'data': null,
      };
    }

    if (!RegExp(r'[A-Z]').hasMatch(newPassword)) {
      return {
        'success': false,
        'message': 'Must contain uppercase letter',
        'data': null,
      };
    }

    FakeAuthService.currentPassword = newPassword;

    return {
      'success': true,
      'message': 'Password changed successfully',
      'data': null,
    };
  }

  Future<Map<String, dynamic>> sendResetCode({
    required String email,
  }) async {
    await Future.delayed(const Duration(seconds: 2));

    String cleanEmail = email.trim().toLowerCase();

    if (cleanEmail.isEmpty) {
      return {
        'success': false,
        'message': 'Please enter your email',
        'data': null,
      };
    }

    if (!cleanEmail.contains('@')) {
      return {
        'success': false,
        'message': 'Enter a valid email',
        'data': null,
      };
    }

    if (cleanEmail != correctEmail) {
      return {
        'success': false,
        'message': 'Email not found',
        'data': null,
      };
    }

    return {
      'success': true,
      'message': 'Verification code sent successfully',
      'data': {
        'email': cleanEmail,
        'code': resetCode,
      },
    };
  }

  Future<Map<String, dynamic>> verifyResetCode({
    required String email,
    required String code,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    String cleanEmail = email.trim().toLowerCase();

    if (cleanEmail != correctEmail) {
      return {
        'success': false,
        'message': 'Email not found',
        'data': null,
      };
    }

    if (code.trim().isEmpty) {
      return {
        'success': false,
        'message': 'Enter verification code',
        'data': null,
      };
    }

    if (code.trim() != resetCode) {
      return {
        'success': false,
        'message': 'Invalid verification code',
        'data': null,
      };
    }

    return {
      'success': true,
      'message': 'Code verified successfully',
      'data': null,
    };
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(seconds: 2));

    String cleanEmail = email.trim().toLowerCase();

    if (cleanEmail != correctEmail) {
      return {
        'success': false,
        'message': 'Email not found',
        'data': null,
      };
    }

    if (newPassword.isEmpty) {
      return {
        'success': false,
        'message': 'Enter new password',
        'data': null,
      };
    }

    if (newPassword.length < 7) {
      return {
        'success': false,
        'message': 'At least 7 characters',
        'data': null,
      };
    }

    if (!RegExp(r'[A-Z]').hasMatch(newPassword)) {
      return {
        'success': false,
        'message': 'Must contain uppercase letter',
        'data': null,
      };
    }

    currentPassword = newPassword;

    return {
      'success': true,
      'message': 'Password updated successfully',
      'data': null,
    };
  }
}