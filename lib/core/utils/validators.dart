abstract final class Validators {
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final regex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Must contain at least one number';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number is required';
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.length < 10) return 'Enter a valid phone number';
    return null;
  }

  static String? unitNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'Unit number is required';
    final regex = RegExp(r'^[A-Za-z0-9\-\/\s]+$');
    if (!regex.hasMatch(value.trim())) return 'Enter a valid unit number';
    return null;
  }

  static String? idNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'ID number is required';
    if (value.trim().length < 6) return 'Enter a valid ID number';
    return null;
  }

  static String? vehicleReg(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final regex = RegExp(r'^[A-Za-z0-9\s\-]+$');
    if (!regex.hasMatch(value.trim())) return 'Invalid vehicle registration';
    return null;
  }

  static String? otpCode(String? value) {
    if (value == null || value.trim().isEmpty) return 'OTP is required';
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return 'Enter the 6-digit OTP';
    }
    return null;
  }
}
