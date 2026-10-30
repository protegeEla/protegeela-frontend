import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/phone_number_formatter.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/protegeela_brand.dart';
import '../../authentication/data/auth_repository.dart';
import '../../authentication/data/demo_session_repository.dart';
import '../data/profile_repository.dart';

class ProfileSetupPage extends ConsumerStatefulWidget {
  const ProfileSetupPage({super.key, this.editing = false});

  final bool editing;

  @override
  ConsumerState<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends ConsumerState<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _privacyMode = false;
  bool _loading = false;
  bool _initializing = false;
  bool _isDemo = false;
  String? _email;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.editing) {
      _initializing = true;
      Future<void>.microtask(_loadProfile);
    }
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ref.read(currentProfileProvider.future);
      final demoActive = await ref.read(demoSessionProvider.future);
      final userEmail = ref.read(authRepositoryProvider).currentUser?.email;
      if (!mounted) return;
      _name.text = profile?.fullName ?? '';
      _phone.text = PhoneNumberFormatter.format(profile?.phone ?? '');
      setState(() {
        _isDemo = demoActive || profile?.id == 'demo-user';
        _email = demoActive ? 'demonstracao@protegeela.app' : userEmail;
        _privacyMode = profile?.privacyMode == 'discreet';
        _initializing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = 'Não foi possível carregar os dados do perfil.';
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_isDemo) {
        final current = ref.read(demoProfileProvider);
        ref.read(demoProfileProvider.notifier).state = current.copyWith(
          fullName: _name.text.trim(),
          phone: _phone.text.trim(),
          privacyMode: _privacyMode ? 'discreet' : 'standard',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Prévia atualizada. Alterações do modo temporário duram somente nesta sessão.',
            ),
          ),
        );
        context.go('/perfil');
        return;
      }
      await ref.read(profileRepositoryProvider).upsertProfile(
            fullName: _name.text,
            phone: _phone.text,
            privacyMode: _privacyMode ? 'discreet' : 'standard',
          );
      ref.invalidate(currentProfileProvider);
      if (mounted) {
        context.go(widget.editing ? '/perfil' : '/primeiro-contato');
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Não foi possível salvar o perfil. Tente novamente.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageTitle = widget.editing ? 'Editar perfil' : 'Criar perfil';
    final compactLayout =
        widget.editing && MediaQuery.sizeOf(context).width >= 700;
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(
          fallbackLocation: widget.editing ? '/perfil' : '/login',
        ),
        title: Text(pageTitle),
      ),
      body: SafeArea(
        child: _initializing
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    compactLayout ? 16 : 24,
                    20,
                    compactLayout ? 24 : 40,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      children: [
                        const ProtegeElaBrand(compact: true),
                        SizedBox(height: compactLayout ? 20 : 28),
                        Container(
                          padding: EdgeInsets.all(compactLayout ? 30 : 34),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: AppColors.border),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x124E1C40),
                                blurRadius: 28,
                                offset: Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (widget.editing) ...[
                                  Align(
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          width: compactLayout ? 64 : 84,
                                          height: compactLayout ? 64 : 84,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceSoft,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: AppColors.secondary
                                                  .withValues(alpha: 0.24),
                                              width: compactLayout ? 2 : 3,
                                            ),
                                          ),
                                          child: Text(
                                            _name.text.trim().isEmpty
                                                ? 'P'
                                                : _name.text
                                                    .trim()
                                                    .characters
                                                    .first
                                                    .toUpperCase(),
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontSize: compactLayout ? 24 : 30,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          right: -4,
                                          bottom: 0,
                                          child: Container(
                                            width: compactLayout ? 26 : 30,
                                            height: compactLayout ? 26 : 30,
                                            decoration: const BoxDecoration(
                                              color: AppColors.primary,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.edit_rounded,
                                              size: compactLayout ? 14 : 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: compactLayout ? 22 : 26),
                                ],
                                Text(
                                  widget.editing
                                      ? 'Seus dados pessoais'
                                      : 'Conte um pouco sobre você',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  widget.editing
                                      ? 'Mantenha suas informações atualizadas para sua segurança.'
                                      : 'Essas informações ajudam sua rede de apoio a reconhecer você.',
                                  style: const TextStyle(
                                      color: AppColors.textMuted),
                                ),
                                if (_isDemo) ...[
                                  SizedBox(height: compactLayout ? 8 : 14),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: compactLayout ? 8 : 11,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceSoft,
                                      borderRadius: BorderRadius.circular(12),
                                      border:
                                          Border.all(color: AppColors.border),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.visibility_outlined,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Modo demonstração: você pode explorar e editar esta prévia.',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                SizedBox(height: compactLayout ? 28 : 32),
                                TextFormField(
                                  controller: _name,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Nome completo',
                                    hintText:
                                        'Como você gostaria de ser chamada?',
                                    prefixIcon:
                                        Icon(Icons.person_outline_rounded),
                                  ),
                                  validator: (value) =>
                                      Validators.required(value, field: 'Nome'),
                                ),
                                SizedBox(height: compactLayout ? 24 : 26),
                                TextFormField(
                                  controller: _phone,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: const [
                                    BrazilianPhoneInputFormatter()
                                  ],
                                  textInputAction: TextInputAction.done,
                                  decoration: const InputDecoration(
                                    labelText: 'Telefone',
                                    hintText: '(92) 99999-9999',
                                    prefixIcon: Icon(Icons.phone_outlined),
                                  ),
                                  validator: Validators.phone,
                                ),
                                if (widget.editing && _email != null) ...[
                                  SizedBox(height: compactLayout ? 24 : 26),
                                  TextFormField(
                                    initialValue: _email,
                                    readOnly: true,
                                    decoration: const InputDecoration(
                                      labelText: 'E-mail da conta',
                                      prefixIcon:
                                          Icon(Icons.mail_outline_rounded),
                                      suffixIcon: Tooltip(
                                        message:
                                            'O e-mail não pode ser alterado aqui',
                                        child: Icon(Icons.lock_outline_rounded),
                                      ),
                                    ),
                                  ),
                                ],
                                SizedBox(height: compactLayout ? 28 : 30),
                                Container(
                                  padding: EdgeInsets.fromLTRB(
                                    16,
                                    compactLayout ? 14 : 16,
                                    8,
                                    compactLayout ? 14 : 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceSoft,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.notifications_none_rounded,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Notificações discretas',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            Text(
                                              'Oculta detalhes sensíveis nas mensagens.',
                                              style: TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Switch(
                                        value: _privacyMode,
                                        onChanged: (value) => setState(
                                            () => _privacyMode = value),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_error != null) ...[
                                  const SizedBox(height: 14),
                                  Text(
                                    _error!,
                                    style: const TextStyle(
                                      color: AppColors.emergency,
                                    ),
                                  ),
                                ],
                                SizedBox(height: compactLayout ? 28 : 32),
                                FilledButton.icon(
                                  onPressed: _loading ? null : _submit,
                                  iconAlignment: IconAlignment.end,
                                  icon: _loading
                                      ? const SizedBox.square(
                                          dimension: 18,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.arrow_forward_rounded),
                                  label: Text(
                                    _loading ? 'Salvando...' : 'Salvar perfil',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
