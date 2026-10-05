import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/phone_number_formatter.dart';
import '../../../core/widgets/protegeela_brand.dart';
import '../data/auth_repository.dart';
import '../data/demo_session_repository.dart';
import 'widgets/authentication_fields.dart';
import 'widgets/login_illustration_panel.dart';

enum AuthenticationView { login, register }

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({
    super.key,
    this.initialView = AuthenticationView.login,
  });

  final AuthenticationView initialView;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;
  bool _rememberMe = false;
  bool _loading = false;
  String? _error;

  bool get _registering => widget.initialView == AuthenticationView.register;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signIn(
            email: _email.text,
            password: _password.text,
            rememberMe: _rememberMe,
          );
      await ref.read(demoSessionRepositoryProvider).end();
      ref.invalidate(demoSessionProvider);
      if (mounted) context.go('/home');
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error is AppException
              ? error.message
              : 'Não foi possível entrar. Confira o e-mail e a senha.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms || !_acceptedPrivacy) {
      setState(() {
        _error = 'Aceite os termos de uso e a política de privacidade.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signUp(
            name: _name.text,
            email: _email.text,
            phone: _phone.text,
            password: _password.text,
          );
      await ref.read(demoSessionRepositoryProvider).end();
      ref.invalidate(demoSessionProvider);
      if (mounted) {
        context.go('/home');
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error is AppException
              ? error.message
              : 'Não foi possível criar sua conta. Tente novamente.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SizedBox.expand(
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            const Positioned(
              left: 22,
              bottom: 22,
              child: AuthDecorativeCircle(size: 270),
            ),
            const Positioned(
              right: 22,
              top: 42,
              child: AuthDecorativeCircle(size: 300),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final desktop = constraints.maxWidth >= 960;
                  final horizontalPadding = desktop ? 52.0 : 20.0;
                  final verticalPadding = desktop ? 30.0 : 20.0;
                  final availableHeight =
                      constraints.maxHeight - (verticalPadding * 2);
                  final pageContent = Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 1420,
                        minHeight: availableHeight,
                      ),
                      child: desktop
                          ? SizedBox(
                              height: availableHeight,
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 11,
                                    child: RepaintBoundary(
                                      child: LoginIllustrationPanel(
                                        registering: _registering,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 44),
                                  Expanded(
                                    flex: 9,
                                    child: Align(
                                      child: _buildAuthCard(
                                        context,
                                        compact: false,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: ProtegeElaBrand(showTagline: true),
                                ),
                                const SizedBox(height: 24),
                                _buildAuthCard(context, compact: true),
                              ],
                            ),
                    ),
                  );

                  final pagePadding = EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  );
                  if (desktop) {
                    return Padding(
                      padding: pagePadding,
                      child: pageContent,
                    );
                  }
                  return SingleChildScrollView(
                    padding: pagePadding,
                    child: pageContent,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthCard(BuildContext context, {required bool compact}) {
    final cardPadding = compact
        ? const EdgeInsets.all(24)
        : _registering
            ? const EdgeInsets.symmetric(horizontal: 24, vertical: 18)
            : const EdgeInsets.all(36);
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 600),
      padding: cardPadding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x164E1C40),
            blurRadius: 38,
            offset: Offset(0, 17),
          ),
        ],
      ),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _registering ? 'Criar conta' : 'Entrar',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontSize: compact ? 34 : (_registering ? 37 : 40),
                    ),
              ),
              const SizedBox(height: 5),
              Text(
                _registering
                    ? 'Preencha seus dados para começar com segurança.'
                    : 'Use seu e-mail e senha para acessar sua conta.',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 15,
                ),
              ),
              SizedBox(height: _registering ? 12 : 26),
              if (_registering) ..._registrationFields() else ..._loginFields(),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDECEC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.emergency),
                  ),
                ),
              ],
              SizedBox(height: _registering ? 12 : 18),
              FilledButton.icon(
                onPressed: _loading ? null : (_registering ? _signUp : _signIn),
                iconAlignment: IconAlignment.end,
                icon: _loading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        _registering
                            ? Icons.person_add_alt_1_rounded
                            : Icons.arrow_forward_rounded,
                      ),
                label: Text(
                  _loading
                      ? (_registering ? 'Criando conta...' : 'Entrando...')
                      : (_registering ? 'Criar conta' : 'Entrar'),
                ),
                style: _registering
                    ? FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      )
                    : null,
              ),
              SizedBox(height: _registering ? 14 : 20),
              AuthenticationModeSwitch(registering: _registering),
              SizedBox(height: _registering ? 14 : 20),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_rounded, color: AppColors.primary, size: 17),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Seus dados são protegidos e usados apenas para sua segurança.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _loginFields() {
    return [
      const Text('E-mail', style: TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      TextFormField(
        controller: _email,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.email],
        decoration: const InputDecoration(
          hintText: 'seuemail@exemplo.com',
          prefixIcon: Icon(Icons.mail_outline_rounded),
        ),
        validator: Validators.email,
      ),
      const SizedBox(height: 18),
      const Text('Senha', style: TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      TextFormField(
        controller: _password,
        obscureText: _obscurePassword,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.password],
        onFieldSubmitted: (_) => _signIn(),
        decoration: InputDecoration(
          hintText: '••••••••',
          prefixIcon: const Icon(Icons.lock_outline_rounded),
          suffixIcon: IconButton(
            onPressed: () => setState(
              () => _obscurePassword = !_obscurePassword,
            ),
            tooltip: _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
          ),
        ),
        validator: Validators.password,
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Checkbox(
            value: _rememberMe,
            onChanged: _loading
                ? null
                : (value) => setState(() => _rememberMe = value ?? false),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: InkWell(
              onTap: _loading
                  ? null
                  : () => setState(() => _rememberMe = !_rememberMe),
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Lembrar de mim',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: null,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 42),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              alignment: Alignment.centerRight,
            ),
            child: const Text('Esqueci minha senha'),
          ),
        ],
      ),
    ];
  }

  List<Widget> _registrationFields() {
    return [
      RegistrationField(
        controller: _name,
        label: 'Nome completo',
        icon: Icons.person_outline_rounded,
        action: TextInputAction.next,
        autofillHints: const [AutofillHints.name],
        validator: (value) => Validators.required(value, field: 'Nome'),
      ),
      const SizedBox(height: 10),
      RegistrationField(
        controller: _email,
        label: 'E-mail',
        icon: Icons.mail_outline_rounded,
        keyboardType: TextInputType.emailAddress,
        action: TextInputAction.next,
        autofillHints: const [AutofillHints.email],
        validator: Validators.email,
      ),
      const SizedBox(height: 10),
      RegistrationField(
        controller: _phone,
        label: 'Telefone',
        icon: Icons.phone_outlined,
        keyboardType: TextInputType.phone,
        inputFormatters: const [BrazilianPhoneInputFormatter()],
        action: TextInputAction.next,
        autofillHints: const [AutofillHints.telephoneNumber],
        validator: Validators.phone,
      ),
      const SizedBox(height: 10),
      RegistrationField(
        controller: _password,
        label: 'Senha',
        icon: Icons.lock_outline_rounded,
        obscureText: _obscurePassword,
        action: TextInputAction.next,
        autofillHints: const [AutofillHints.newPassword],
        validator: Validators.password,
        suffixIcon: IconButton(
          onPressed: () => setState(
            () => _obscurePassword = !_obscurePassword,
          ),
          tooltip: _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 44, height: 44),
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
      ),
      const SizedBox(height: 10),
      RegistrationField(
        controller: _confirmPassword,
        label: 'Confirmar senha',
        icon: Icons.verified_user_outlined,
        obscureText: _obscureConfirmation,
        action: TextInputAction.done,
        autofillHints: const [AutofillHints.newPassword],
        validator: (value) =>
            value == _password.text ? null : 'As senhas não conferem.',
        suffixIcon: IconButton(
          onPressed: () => setState(
            () => _obscureConfirmation = !_obscureConfirmation,
          ),
          tooltip: _obscureConfirmation
              ? 'Mostrar confirmação'
              : 'Ocultar confirmação',
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 44, height: 44),
          icon: Icon(
            _obscureConfirmation
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
        onSubmitted: (_) => _signUp(),
      ),
      const SizedBox(height: 8),
      ConsentRow(
        value: _acceptedTerms,
        label: 'Aceito os termos de uso',
        onChanged: (value) => setState(() => _acceptedTerms = value),
      ),
      ConsentRow(
        value: _acceptedPrivacy,
        label: 'Aceito a política de privacidade',
        onChanged: (value) => setState(() => _acceptedPrivacy = value),
      ),
    ];
  }
}
