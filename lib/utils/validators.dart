/// Form field validation helpers matching Criterion 5 rules.
class Validators {
  Validators._();

  static String? requiredField(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? email(String? value) {
    final req = requiredField(value, 'Email');
    if (req != null) return req;
    final regex = RegExp(r'^[\w\.-]+@[\w\.-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(value!.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    final req = requiredField(value, 'Password');
    if (req != null) return req;
    if (value!.trim().length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? studentId(String? value) {
    final req = requiredField(value, 'Student ID');
    if (req != null) return req;
    final trimmed = value!.trim();
    final regex = RegExp(r'^[A-Za-z0-9\-/]{3,20}$');
    if (!regex.hasMatch(trimmed)) {
      return 'Use 3-20 letters, digits, "-" or "/"';
    }
    return null;
  }

  static String? personName(String? value, String fieldName) {
    final req = requiredField(value, fieldName);
    if (req != null) return req;
    final trimmed = value!.trim();
    final regex = RegExp(r'^[A-Za-z\s]{2,30}$');
    if (!regex.hasMatch(trimmed)) {
      return '$fieldName must contain letters only (2-30 characters)';
    }
    return null;
  }

  static String? moduleCode(String? value) {
    final req = requiredField(value, 'Module code');
    if (req != null) return req;
    final trimmed = value!.trim().toUpperCase();
    final regex = RegExp(r'^[A-Z]{2,6}[0-9]{2,4}$');
    if (!regex.hasMatch(trimmed)) {
      return 'Format: letters then digits, e.g. PROG202';
    }
    return null;
  }

  static String? moduleName(String? value) {
    final req = requiredField(value, 'Module name');
    if (req != null) return req;
    if (value!.trim().length < 3) {
      return 'Module name is too short';
    }
    return null;
  }

  static String? mark(String? value) {
    final req = requiredField(value, 'Mark');
    if (req != null) return req;
    final parsed = double.tryParse(value!.trim());
    if (parsed == null || parsed.isNaN || parsed.isInfinite) {
      return 'Enter a valid number';
    }
    if (parsed < 0 || parsed > 100) {
      return 'Mark must be between 0 and 100';
    }
    return null;
  }

  static String? dropdown(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please select $fieldName';
    }
    return null;
  }
}