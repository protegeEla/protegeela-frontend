import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/protegeela_brand.dart';
import '../../../shared/models/trusted_contact.dart';
import '../../authentication/data/demo_session_repository.dart';
import '../data/trusted_contacts_repository.dart';
import 'contact_dialogs.dart';

class TrustedContactsPage extends ConsumerWidget {
  const TrustedContactsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contacts = ref.watch(trustedContactsProvider);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 760;
            return Padding(
              padding: EdgeInsets.fromLTRB(
                desktop ? 38 : 18,
                desktop ? 28 : 16,
                desktop ? 38 : 18,
                24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!desktop) ...[
                        const ProtegeElaBrand(compact: true),
                        const SizedBox(height: 20),
                      ],
                      AppPageHeader(
                        title: 'Rede de apoio',
                        subtitle:
                            'Pessoas que podem te ajudar em um momento de necessidade.',
                        action: FilledButton.icon(
                          onPressed: () => _addContact(context, ref),
                          icon: const Icon(Icons.add_rounded),
                          label:
                              Text(desktop ? 'Adicionar contato' : 'Adicionar'),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Expanded(
                        child: contacts.when(
                          loading: () => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          error: (_, __) => AppStateView(
                            title: 'Erro',
                            message: 'Não foi possível carregar contatos.',
                            actionLabel: 'Tentar novamente',
                            onAction: () =>
                                ref.invalidate(trustedContactsProvider),
                          ),
                          data: (items) {
                            if (items.isEmpty) {
                              return AppStateView(
                                title: 'Nenhum contato cadastrado',
                                message:
                                    'Convide pessoas de confiança. Um contato só fica ativo após consentimento.',
                                actionLabel: 'Adicionar contato',
                                onAction: () => _addContact(context, ref),
                              );
                            }
                            return ListView.separated(
                              padding: const EdgeInsets.only(bottom: 18),
                              itemCount: items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final contact = items[index];
                                return _ContactCard(
                                  contact: contact,
                                  onEdit: () =>
                                      _editContact(context, ref, contact),
                                  onManageAccess: () =>
                                      _manageAccess(context, ref, contact),
                                  onRemove: () =>
                                      _removeContact(context, ref, contact),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Durante um alerta, seus contatos autorizados recebem sua localização exata.',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _addContact(BuildContext context, WidgetRef ref) async {
    final value = await showContactFormDialog(context);
    if (value == null || !context.mounted) return;

    final demoActive = await ref.read(demoSessionProvider.future);
    if (!context.mounted) return;

    if (demoActive) {
      final notifier = ref.read(demoTrustedContactsProvider.notifier);
      notifier.state = [
        ...notifier.state,
        TrustedContact(
          id: 'demo-${DateTime.now().microsecondsSinceEpoch}',
          ownerUserId: 'demo-user',
          name: value.name,
          phone: value.phone,
          email: value.email.isEmpty ? null : value.email,
          relationship: value.relationship,
          invitationStatus: 'accepted',
          canViewExactLocation: value.canViewExactLocation,
          isPrimary: notifier.state.isEmpty,
        ),
      ];
      _showMessage(
        context,
        'Contato adicionado nesta demonstração. Ele não será salvo ao sair.',
      );
      return;
    }

    await _runMutation(
      context,
      ref,
      successMessage: 'Contato adicionado. O convite está pendente.',
      mutation: () => ref.read(trustedContactsRepositoryProvider).addContact(
            name: value.name,
            phone: value.phone,
            email: value.email,
            relationship: value.relationship,
            canViewExactLocation: value.canViewExactLocation,
          ),
    );
  }

  Future<void> _editContact(
    BuildContext context,
    WidgetRef ref,
    TrustedContact contact,
  ) async {
    final value = await showContactFormDialog(context, contact: contact);
    if (value == null || !context.mounted) return;

    final demoActive = await ref.read(demoSessionProvider.future);
    if (!context.mounted) return;

    if (demoActive) {
      final notifier = ref.read(demoTrustedContactsProvider.notifier);
      notifier.state = [
        for (final item in notifier.state)
          if (item.id == contact.id)
            item.copyWith(
              name: value.name,
              phone: value.phone,
              email: value.email,
              clearEmail: value.email.isEmpty,
              relationship: value.relationship,
            )
          else
            item,
      ];
      _showMessage(context, 'Alterações aplicadas nesta demonstração.');
      return;
    }

    await _runMutation(
      context,
      ref,
      successMessage: 'Contato atualizado com sucesso.',
      mutation: () => ref.read(trustedContactsRepositoryProvider).updateContact(
            id: contact.id,
            name: value.name,
            phone: value.phone,
            email: value.email,
            relationship: value.relationship,
          ),
    );
  }

  Future<void> _manageAccess(
    BuildContext context,
    WidgetRef ref,
    TrustedContact contact,
  ) async {
    final permission = await showContactAccessDialog(
      context,
      contact: contact,
    );
    if (permission == null || !context.mounted) return;

    final demoActive = await ref.read(demoSessionProvider.future);
    if (!context.mounted) return;

    if (demoActive) {
      final notifier = ref.read(demoTrustedContactsProvider.notifier);
      notifier.state = [
        for (final item in notifier.state)
          if (item.id == contact.id)
            item.copyWith(canViewExactLocation: permission)
          else
            item,
      ];
      _showMessage(context, 'Permissão atualizada nesta demonstração.');
      return;
    }

    await _runMutation(
      context,
      ref,
      successMessage: 'Permissão de localização atualizada.',
      mutation: () =>
          ref.read(trustedContactsRepositoryProvider).updateLocationPermission(
                id: contact.id,
                canViewExactLocation: permission,
              ),
    );
  }

  Future<void> _removeContact(
    BuildContext context,
    WidgetRef ref,
    TrustedContact contact,
  ) async {
    final confirmed = await showRemoveContactDialog(
      context,
      contact: contact,
    );
    if (!confirmed || !context.mounted) return;

    final demoActive = await ref.read(demoSessionProvider.future);
    if (!context.mounted) return;

    if (demoActive) {
      final notifier = ref.read(demoTrustedContactsProvider.notifier);
      notifier.state = [
        for (final item in notifier.state)
          if (item.id != contact.id) item,
      ];
      _showMessage(context, 'Contato removido desta demonstração.');
      return;
    }

    await _runMutation(
      context,
      ref,
      successMessage: 'Contato removido da sua rede de apoio.',
      mutation: () =>
          ref.read(trustedContactsRepositoryProvider).remove(contact.id),
    );
  }

  Future<void> _runMutation(
    BuildContext context,
    WidgetRef ref, {
    required Future<void> Function() mutation,
    required String successMessage,
  }) async {
    try {
      await mutation();
      ref.invalidate(trustedContactsProvider);
      if (context.mounted) _showMessage(context, successMessage);
    } catch (_) {
      if (context.mounted) {
        _showMessage(
          context,
          'Não foi possível concluir a ação. Tente novamente.',
          error: true,
        );
      }
    }
  }

  void _showMessage(
    BuildContext context,
    String message, {
    bool error = false,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? AppColors.emergency : null,
        ),
      );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.contact,
    required this.onEdit,
    required this.onManageAccess,
    required this.onRemove,
  });

  final TrustedContact contact;
  final VoidCallback onEdit;
  final VoidCallback onManageAccess;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final accepted = contact.invitationStatus == 'accepted';
    final initial = contact.name.trim().isEmpty
        ? '?'
        : contact.name.trim()[0].toUpperCase();

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: AppColors.accent,
              child: Text(
                initial,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        contact.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (contact.isPrimary)
                        const _ContactBadge(
                          icon: Icons.star_rounded,
                          text: 'Contato principal',
                          color: AppColors.primary,
                        ),
                      _ContactBadge(
                        icon: accepted
                            ? Icons.check_rounded
                            : Icons.schedule_rounded,
                        text: accepted ? 'Ativo' : 'Pendente',
                        color: accepted ? AppColors.safe : AppColors.textMuted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_relationshipLabel(contact.relationship)} • ${contact.phone}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            _ContactMenuButton(
              onEdit: onEdit,
              onManageAccess: onManageAccess,
              onRemove: onRemove,
            ),
          ],
        ),
      ),
    );
  }

  String _relationshipLabel(String value) {
    const labels = {
      'familia': 'Família',
      'amiga': 'Amiga(o)',
      'vizinha': 'Vizinha(o)',
      'demo': 'Amiga(o)',
    };
    return labels[value] ?? 'Contato';
  }
}

class _ContactMenuButton extends StatelessWidget {
  const _ContactMenuButton({
    required this.onEdit,
    required this.onManageAccess,
    required this.onRemove,
  });

  final VoidCallback onEdit;
  final VoidCallback onManageAccess;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ContactMenuAction>(
      tooltip: 'Mais opções',
      position: PopupMenuPosition.under,
      offset: const Offset(0, 6),
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 10,
      constraints: const BoxConstraints(minWidth: 250, maxWidth: 280),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      onSelected: (action) {
        switch (action) {
          case _ContactMenuAction.edit:
            onEdit();
            break;
          case _ContactMenuAction.permissions:
            onManageAccess();
            break;
          case _ContactMenuAction.remove:
            onRemove();
            break;
        }
      },
      itemBuilder: (context) => const [
        _ContactMenuItem(
          value: _ContactMenuAction.edit,
          icon: Icons.edit_outlined,
          title: 'Editar contato',
          subtitle: 'Nome, telefone e relação',
        ),
        _ContactMenuItem(
          value: _ContactMenuAction.permissions,
          icon: Icons.location_on_outlined,
          title: 'Gerenciar acesso',
          subtitle: 'Permissão de localização',
        ),
        PopupMenuDivider(height: 9),
        _ContactMenuItem(
          value: _ContactMenuAction.remove,
          icon: Icons.delete_outline_rounded,
          title: 'Remover contato',
          destructive: true,
        ),
      ],
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.more_horiz_rounded,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

enum _ContactMenuAction { edit, permissions, remove }

class _ContactMenuItem extends PopupMenuItem<_ContactMenuAction> {
  const _ContactMenuItem({
    required _ContactMenuAction value,
    required this.icon,
    required this.title,
    this.subtitle,
    this.destructive = false,
  }) : super(value: value, child: const SizedBox.shrink());

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool destructive;

  @override
  PopupMenuItemState<_ContactMenuAction, _ContactMenuItem> createState() =>
      _ContactMenuItemState();
}

class _ContactMenuItemState
    extends PopupMenuItemState<_ContactMenuAction, _ContactMenuItem> {
  @override
  Widget buildChild() {
    final color = widget.destructive ? AppColors.emergency : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(widget.icon, color: color, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    color: widget.destructive
                        ? AppColors.emergency
                        : AppColors.text,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    widget.subtitle!,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactBadge extends StatelessWidget {
  const _ContactBadge({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
