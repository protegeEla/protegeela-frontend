import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/protegeela_brand.dart';
import '../data/contact_invitation_repository.dart';

class ContactInvitationPage extends ConsumerStatefulWidget {
  const ContactInvitationPage({super.key, required this.token});

  final String token;

  @override
  ConsumerState<ContactInvitationPage> createState() =>
      _ContactInvitationPageState();
}

class _ContactInvitationPageState extends ConsumerState<ContactInvitationPage> {
  bool _busy = false;
  String? _response;

  Future<void> _respond(String response) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(contactInvitationRepositoryProvider)
          .respond(widget.token, response);
      if (mounted) setState(() => _response = result);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Não foi possível responder ao convite.'),
        ));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final invitation = ref.watch(contactInvitationProvider(widget.token));
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: ProtegeElaBrand(showTagline: true)),
                  const SizedBox(height: 26),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: invitation.when(
                        loading: () => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        error: (_, __) => const AppStateView(
                          title: 'Convite indisponível',
                          message:
                              'O link pode ter expirado ou já ter sido substituído.',
                        ),
                        data: (value) {
                          final status = _response ?? value.status;
                          if (status != 'pending') {
                            final accepted = status == 'accepted';
                            return Column(
                              children: [
                                Icon(
                                  accepted
                                      ? Icons.verified_user_rounded
                                      : Icons.person_off_outlined,
                                  color: accepted
                                      ? AppColors.safe
                                      : AppColors.textMuted,
                                  size: 58,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  accepted
                                      ? 'Convite confirmado'
                                      : 'Convite recusado',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  accepted
                                      ? 'Você agora faz parte da rede de apoio de ${value.ownerName}.'
                                      : 'Sua decisão foi registrada.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              const Icon(
                                Icons.people_outline_rounded,
                                color: AppColors.primary,
                                size: 54,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Convite para rede de apoio',
                                style:
                                    Theme.of(context).textTheme.headlineMedium,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${value.ownerName} convidou ${value.contactName} para ser um contato de confiança no ProtegeEla.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Válido até ${DateFormat('dd/MM/yyyy HH:mm').format(value.expiresAt.toLocal())}.',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'Ao aceitar, você confirma que concorda em receber pedidos de ajuda. Nenhuma localização é compartilhada automaticamente nesta versão.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 24),
                              FilledButton.icon(
                                onPressed:
                                    _busy ? null : () => _respond('accepted'),
                                icon: const Icon(Icons.check_rounded),
                                label: const Text('Aceitar convite'),
                              ),
                              const SizedBox(height: 9),
                              TextButton(
                                onPressed:
                                    _busy ? null : () => _respond('declined'),
                                child: const Text('Recusar'),
                              ),
                              if (_busy) ...[
                                const SizedBox(height: 8),
                                const LinearProgressIndicator(),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Conhecer o ProtegeEla'),
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
