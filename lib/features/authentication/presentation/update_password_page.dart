import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/protegeela_brand.dart';
import '../data/auth_repository.dart';

class UpdatePasswordPage extends ConsumerStatefulWidget {
  const UpdatePasswordPage({super.key});

  @override
  ConsumerState<UpdatePasswordPage> createState() => _UpdatePasswordPageState();
}

class _UpdatePasswordPageState extends ConsumerState<UpdatePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _loading = false;
  bool _updated = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).updatePassword(_password.text);
      if (mounted) setState(() => _updated = true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error =
              'Não foi possível atualizar a senha. Solicite um novo link de recuperação.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned(
            left: -110,
            bottom: -140,
            child: _DecorativeCircle(size: 350),
          ),
          const Positioned(
            right: -90,
            top: 35,
            child: _DecorativeCircle(size: 285),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 22,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 44,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ProtegeElaBrand(
                          compact: true,
                          showTagline: true,
                        ),
                        const SizedBox(height: 30),
                        Center(
                          child: Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(maxWidth: 560),
                            padding: const EdgeInsets.all(34),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.97),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: AppColors.border),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x184E1C40),
                                  blurRadius: 42,
                                  offset: Offset(0, 18),
                                ),
                              ],
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 240),
                              child: _updated ? _success() : _form(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _form() {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('update-password-form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.password_rounded,
            color: AppColors.primary,
            size: 44,
          ),
          const SizedBox(height: 18),
          Text(
            'Crie uma nova senha',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Use pelo menos 8 caracteres e evite reutilizar uma senha antiga.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, height: 1.4),
          ),
          const SizedBox(height: 26),
          TextFormField(
            controller: _password,
            obscureText: _obscurePassword,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Nova senha',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
                onPressed: () => setState(
                  () => _obscurePassword = !_obscurePassword,
                ),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: Validators.password,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmation,
            obscureText: _obscureConfirmation,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Confirmar nova senha',
              prefixIcon: const Icon(Icons.verified_user_outlined),
              suffixIcon: IconButton(
                tooltip:
                    _obscureConfirmation ? 'Mostrar senha' : 'Ocultar senha',
                onPressed: () => setState(
                  () => _obscureConfirmation = !_obscureConfirmation,
                ),
                icon: Icon(
                  _obscureConfirmation
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (value) {
              final required = Validators.required(
                value,
                field: 'Confirmação de senha',
              );
              if (required != null) return required;
              if (value != _password.text) return 'As senhas não coincidem.';
              return null;
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.emergency),
            ),
          ],
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: _loading ? null : _submit,
            iconAlignment: IconAlignment.end,
            icon: _loading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(_loading ? 'Salvando...' : 'Salvar nova senha'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => context.go('/recuperar-senha'),
            child: const Text('Solicitar outro link'),
          ),
        ],
      ),
    );
  }

  Widget _success() {
    return Column(
      key: const ValueKey('update-password-success'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircleAvatar(
          radius: 38,
          backgroundColor: Color(0xFFE8F6EF),
          child: Icon(Icons.check_rounded, color: AppColors.safe, size: 42),
        ),
        const SizedBox(height: 22),
        Text(
          'Senha atualizada',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Seu acesso foi recuperado com segurança.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted),
        ),
        const SizedBox(height: 26),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => context.go('/home'),
            child: const Text('Continuar para o app'),
          ),
        ),
      ],
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFFF9E4F0),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
