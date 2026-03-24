class Validators {
  static String? validateName(String? value) {
 chatbox
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    if (value == null || value.isEmpty) {
      return "Name is required";
      main
    }
    return null;
  }

  static String? validateEmail(String? value) {
 chatbox
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!value.contains('@')) {
      return 'Enter valid email';
    if (value == null || value.isEmpty) {
      return "Email is required";
    }
    if (!value.contains("@")) {
      return "Enter valid email";
 main
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.length < 6) {
 chatbox
      return 'Password must be at least 6 characters';
      return "Password must be at least 6 characters";
main
    }
    return null;
  }
}
