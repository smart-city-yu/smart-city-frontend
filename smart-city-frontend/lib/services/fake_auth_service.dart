class FakeAuthService {
  static const String correctEmail = 'leen@test.com';
  static const String correctPassword = '123456L';
  static const String takenEmail = 'used@test.com';

  Future<Map<String, dynamic>> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 2));

    String cleanEmail = email.trim().toLowerCase();

    if (cleanEmail == correctEmail && password == correctPassword) {
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
}