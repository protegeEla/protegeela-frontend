class Validators {
  static String? required(String? value, {String field = 'Campo'}) {
    if (value == null || value.trim().isEmpty) return '$field é obrigatório.';
    return null;
  }

  static String? email(String? value) {
    final base = required(value, field: 'E-mail');
    if (base != null) return base;
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value!.trim());
    return ok ? null : 'Informe um e-mail válido.';
  }

  static String? password(String? value) {
    final base = required(value, field: 'Senha');
    if (base != null) return base;
    if (value!.length < 8) return 'Use pelo menos 8 caracteres.';
    return null;
  }

  static String? phone(String? value) {
    final base = required(value, field: 'Telefone');
    if (base != null) return base;
    final digits = value!.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return 'Informe um telefone com DDD.';
    return null;
  }
}
