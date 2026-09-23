import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/protegeela_brand.dart';
import '../data/auth_repository.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sent = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).resetPassword(_email.text);
      if (mounted) setState(() => _sent = true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error =
              'Não foi possível enviar as instruções agora. Tente novamente.';
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
            left: -100,
            bottom: -130,
            child: _DecorativeCircle(size: 330),
          ),
          const Positioned(
            right: -75,
            top: 45,
            child: _DecorativeCircle(size: 265),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final desktop = constraints.maxWidth >= 900;
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: desktop ? 64 : 20,
                    vertical: 22,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 44,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            AppBackButton(fallbackLocation: '/login'),
                            SizedBox(width: 10),
                            ProtegeElaBrand(
                              compact: true,
                              showTagline: true,
                            ),
                          ],
                        ),
                        SizedBox(height: desktop ? 46 : 28),
                        if (desktop)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Expanded(child: _RecoveryIntroduction()),
                              const SizedBox(width: 70),
                              Expanded(
                                child: Align(
                                  child: _RecoveryCard(
                                    formKey: _formKey,
                                    email: _email,
                                    sent: _sent,
                                    loading: _loading,
                                    error: _error,
                                    onSubmit: _submit,
                                    onEditEmail: () =>
                                        setState(() => _sent = false),
                                  ),
                                ),
                              ),
                            ],
                          )
                        else ...[
                          const _RecoveryIntroduction(compact: true),
                          const SizedBox(height: 26),
                          _RecoveryCard(
                            formKey: _formKey,
                            email: _email,
                            sent: _sent,
                            loading: _loading,
                            error: _error,
                            onSubmit: _submit,
                            onEditEmail: () => setState(() => _sent = false),
                          ),
                        ],
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
}

class _RecoveryIntroduction extends StatelessWidget {
  const _RecoveryIntroduction({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 60 : 78,
            height: compact ? 60 : 78,
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              Icons.lock_reset_rounded,
              color: AppColors.primary,
              size: compact ? 32 : 42,
            ),
          ),
          SizedBox(height: compact ? 18 : 28),
          Text(
            'Recupere seu\nacesso com segurança',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                  fontSize: compact ? 34 : 50,
                ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Vamos enviar um link para você criar uma nova senha e voltar à sua conta.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 17,
              height: 1.45,
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 30),
            const _SafetyLine(
              icon: Icons.mark_email_read_outlined,
              text: 'Confira também a pasta de spam ou lixo eletrônico.',
            ),
            const SizedBox(height: 14),
            const _SafetyLine(
              icon: Icons.shield_outlined,
              text: 'Nunca compartilhe o link de recuperação com outra pessoa.',
            ),
          ],
        ],
      ),
    );
  }
}

class _RecoveryCard extends StatelessWidget {
  const _RecoveryCard({
    required this.formKey,
    required this.email,
    required this.sent,
    required this.loading,
    required this.error,
    required this.onSubmit,
    required this.onEditEmail,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController email;
  final bool sent;
  final bool loading;
  final String? error;
  final VoidCallback onSubmit;
  final VoidCallback onEditEmail;

  @override
  Widget build(BuildContext context) {
    return Container(
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
        duration: const Duration(milliseconds: 260),
        child: sent ? _success(context) : _form(context),
      ),
    );
  }

  Widget _form(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        key: const ValueKey('recovery-form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Esqueceu sua senha?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Informe o e-mail usado no cadastro.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 16),
          ),
          const SizedBox(height: 28),
          const Text('E-mail', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextFormField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            onFieldSubmitted: (_) => onSubmit(),
            decoration: const InputDecoration(
              hintText: 'seuemail@exemplo.com',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
            validator: Validators.email,
          ),
          if (error != null) ...[
            const SizedBox(height: 14),
            Text(
              error!,
              style: const TextStyle(color: AppColors.emergency),
            ),
          ],
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: loading ? null : onSubmit,
            iconAlignment: IconAlignment.end,
            icon: loading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.arrow_forward_rounded),
            label: Text(loading ? 'Enviando...' : 'Enviar instruções'),
          ),
          const SizedBox(height: 18),
          TextButton.icon(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.arrow_back_rounded, size: 19),
            label: const Text('Voltar para entrar'),
          ),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded, size: 16),
              SizedBox(width: 7),
              Flexible(
                child: Text(
                  'Sua privacidade é protegida durante todo o processo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _success(BuildContext context) {
    return Column(
      key: const ValueKey('recovery-success'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: const BoxDecoration(
            color: Color(0xFFE8F6EF),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_outlined,
            color: AppColors.safe,
            size: 38,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Confira seu e-mail',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.primaryDark,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          'Se houver uma conta associada a ${email.text.trim()}, você receberá as instruções em instantes.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textMuted, height: 1.45),
        ),
        const SizedBox(height: 26),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => context.go('/login'),
            child: const Text('Voltar para entrar'),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: onEditEmail,
          child: const Text('Usar outro e-mail'),
        ),
      ],
    );
  }
}

class _SafetyLine extends StatelessWidget {
  const _SafetyLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.textMuted, height: 1.35),
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
