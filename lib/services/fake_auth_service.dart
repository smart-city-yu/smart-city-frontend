class FakeAuthService {
  static String currentEmail = 'leen@test.com';
  static String currentPassword = '123456L';

  static const String takenEmail = 'used@test.com';
  static const String usedNationalId = '1234567890';
  static const String usedPhone = '0791234567';
  static const String resetCode = '123456';

  Future<Map<String, dynamic>> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 2));

    String cleanEmail = email.trim().toLowerCase();

    if (cleanEmail == currentEmail && password == currentPassword) {
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
      String nationalId,
      String phone,
      String email,
      String password,
      ) async {
    await Future.delayed(const Duration(seconds: 2));

    String cleanName = name.trim();
    String cleanNationalId = nationalId.trim();
    String cleanPhone = phone.trim();
    String cleanEmail = email.trim().toLowerCase();

    if (cleanName.isEmpty) {
      return {
        'success': false,
        'message': 'Name is required.',
        'data': null,
      };
    }

    if (cleanNationalId.isEmpty) {
      return {
        'success': false,
        'message': 'National ID is required.',
        'data': null,
      };
    }

    if (!RegExp(r'^[0-9]{10}$').hasMatch(cleanNationalId)) {
      return {
        'success': false,
        'message': 'National ID must be 10 digits.',
        'data': null,
      };
    }

    if (cleanNationalId == usedNationalId) {
      return {
        'success': false,
        'message': 'National ID already used.',
        'data': null,
      };
    }

    if (cleanPhone.isEmpty) {
      return {
        'success': false,
        'message': 'Phone number is required.',
        'data': null,
      };
    }

    if (!RegExp(r'^07[789][0-9]{7}$').hasMatch(cleanPhone)) {
      return {
        'success': false,
        'message': 'Phone number must be a valid Jordanian number.',
        'data': null,
      };
    }

    if (cleanPhone == usedPhone) {
      return {
        'success': false,
        'message': 'Phone number already used.',
        'data': null,
      };
    }

    if (cleanEmail.isEmpty) {
      return {
        'success': false,
        'message': 'Email is required.',
        'data': null,
      };
    }

    if (!cleanEmail.contains('@')) {
      return {
        'success': false,
        'message': 'Enter a valid email.',
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

    if (password.isEmpty) {
      return {
        'success': false,
        'message': 'Password is required.',
        'data': null,
      };
    }

    if (password.length < 7) {
      return {
        'success': false,
        'message': 'At least 7 characters',
        'data': null,
      };
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return {
        'success': false,
        'message': 'Must contain uppercase letter',
        'data': null,
      };
    }

    currentEmail = cleanEmail;
    currentPassword = password;

    return {
      'success': true,
      'message': 'Account created! Please sign in.',
      'data': {
        'name': cleanName,
        'nationalId': cleanNationalId,
        'phone': cleanPhone,
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

    if (cleanEmail != currentEmail) {
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

    if (cleanEmail != currentEmail) {
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

    if (cleanEmail != currentEmail) {
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