import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/models/trusted_contact.dart';

class ContactFormValue {
  const ContactFormValue({
    required this.name,
    required this.phone,
    required this.email,
    required this.relationship,
    required this.canViewExactLocation,
  });

  final String name;
  final String phone;
  final String email;
  final String relationship;
  final bool canViewExactLocation;
}

Future<ContactFormValue?> showContactFormDialog(
  BuildContext context, {
  TrustedContact? contact,
}) {
  return showDialog<ContactFormValue>(
    context: context,
    builder: (_) => _ContactFormDialog(contact: contact),
  );
}

Future<bool?> showContactAccessDialog(
  BuildContext context, {
  required TrustedContact contact,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => _ContactAccessDialog(contact: contact),
  );
}

Future<bool> showRemoveContactDialog(
  BuildContext context, {
  required TrustedContact contact,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          _DialogIcon(
            icon: Icons.delete_outline_rounded,
            color: AppColors.emergency,
          ),
          SizedBox(width: 12),
          Expanded(child: Text('Remover contato?')),
        ],
      ),
      content: Text(
        '${contact.name} deixará de receber seus alertas e sua localização. '
        'Essa ação não pode ser desfeita.',
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: AppColors.emergency),
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text('Remover'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

class _ContactFormDialog extends StatefulWidget {
  const _ContactFormDialog({this.contact});

  final TrustedContact? contact;

  @override
  State<_ContactFormDialog> createState() => _ContactFormDialogState();
}

class _ContactFormDialogState extends State<_ContactFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late String _relationship;
  late bool _exactLocation;

  bool get _editing => widget.contact != null;

  @override
  void initState() {
    super.initState();
    final contact = widget.contact;
    _name = TextEditingController(text: contact?.name ?? '');
    _phone = TextEditingController(text: contact?.phone ?? '');
    _email = TextEditingController(text: contact?.email ?? '');
    _relationship = contact?.relationship == 'demo'
        ? 'amiga'
        : contact?.relationship ?? 'familia';
    _exactLocation = contact?.canViewExactLocation ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      ContactFormValue(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        relationship: _relationship,
        canViewExactLocation: _exactLocation,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 16, 8),
      title: Row(
        children: [
          Expanded(
              child: Text(_editing ? 'Editar contato' : 'Adicionar contato')),
          IconButton(
            onPressed: () => Navigator.pop(context),
            tooltip: 'Fechar',
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  autofocus: _editing,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    hintText: 'Digite o nome',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (value) =>
                      Validators.required(value, field: 'Nome'),
                ),
                const SizedBox(height: 13),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Telefone',
                    hintText: '(92) 99999-9999',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: Validators.phone,
                ),
                const SizedBox(height: 13),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'E-mail opcional',
                    hintText: 'email@exemplo.com',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    return Validators.email(value);
                  },
                ),
                const SizedBox(height: 13),
                _RelationshipSelector(
                  value: _relationship,
                  onChanged: (value) => setState(() => _relationship = value),
                ),
                if (!_editing) ...[
                  const SizedBox(height: 14),
                  _LocationPermissionTile(
                    value: _exactLocation,
                    onChanged: (value) =>
                        setState(() => _exactLocation = value),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: Icon(_editing ? Icons.check_rounded : Icons.person_add_alt_1),
          label: Text(_editing ? 'Salvar alterações' : 'Salvar contato'),
        ),
      ],
    );
  }
}

class _ContactAccessDialog extends StatefulWidget {
  const _ContactAccessDialog({required this.contact});

  final TrustedContact contact;

  @override
  State<_ContactAccessDialog> createState() => _ContactAccessDialogState();
}

class _ContactAccessDialogState extends State<_ContactAccessDialog> {
  late bool _exactLocation = widget.contact.canViewExactLocation;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          _DialogIcon(icon: Icons.location_on_outlined),
          SizedBox(width: 12),
          Expanded(child: Text('Gerenciar acesso')),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Defina o que ${widget.contact.name} poderá visualizar durante um alerta ativo.',
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 18),
            _LocationPermissionTile(
              value: _exactLocation,
              onChanged: (value) => setState(() => _exactLocation = value),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    color: AppColors.primary,
                    size: 19,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'A localização exata só é compartilhada enquanto houver um alerta ativo.',
                      style: TextStyle(fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _exactLocation),
          child: const Text('Salvar permissão'),
        ),
      ],
    );
  }
}

class _LocationPermissionTile extends StatelessWidget {
  const _LocationPermissionTile({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          const _DialogIcon(icon: Icons.location_on_outlined, size: 36),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Localização durante alertas',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 2),
                Text(
                  'Compartilhar localização exata',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _RelationshipSelector extends StatelessWidget {
  const _RelationshipSelector({
    required this.value,
    required this.onChanged,
  });

  static const _options = [
    _RelationshipOption(
      value: 'familia',
      label: 'Família',
      icon: Icons.favorite_outline_rounded,
    ),
    _RelationshipOption(
      value: 'amiga',
      label: 'Amiga(o)',
      icon: Icons.people_outline_rounded,
    ),
    _RelationshipOption(
      value: 'vizinha',
      label: 'Vizinha(o)',
      icon: Icons.home_outlined,
    ),
    _RelationshipOption(
      value: 'outro',
      label: 'Outro',
      icon: Icons.more_horiz_rounded,
    ),
  ];

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = _options.firstWhere(
      (option) => option.value == value,
      orElse: () => _options.last,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            'Relação',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: PopupMenuButton<String>(
            initialValue: value,
            tooltip: 'Selecionar relação',
            position: PopupMenuPosition.under,
            offset: const Offset(0, 6),
            constraints: const BoxConstraints(minWidth: 270, maxWidth: 300),
            color: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.border),
            ),
            onSelected: onChanged,
            itemBuilder: (context) => [
              for (final option in _options)
                PopupMenuItem<String>(
                  value: option.value,
                  height: 46,
                  child: Row(
                    children: [
                      _DialogIcon(icon: option.icon, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          option.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: option.value == value
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (option.value == value)
                        const Icon(
                          Icons.check_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                    ],
                  ),
                ),
            ],
            child: SizedBox(
              height: 50,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    _DialogIcon(icon: selected.icon, size: 32),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        selected.label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textMuted,
                      size: 21,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DialogIcon extends StatelessWidget {
  const _DialogIcon({
    required this.icon,
    this.color = AppColors.primary,
    this.size = 40,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(size < 36 ? 8 : 10),
      ),
      child: Icon(icon, color: color, size: size * 0.52),
    );
  }
}

class _RelationshipOption {
  const _RelationshipOption({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;
}
