import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme.dart';
import '../../../../shared/models/support_point.dart';
import 'support_category.dart';

class SupportResultsPanel extends StatelessWidget {
  const SupportResultsPanel({
    super.key,
    required this.items,
    required this.selectedId,
    required this.onSelected,
  });

  final List<SupportPoint> items;
  final String? selectedId;
  final ValueChanged<SupportPoint> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: items.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      color: AppColors.textMuted,
                      size: 38,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Nenhum local corresponde à busca.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 9),
              itemBuilder: (context, index) {
                final item = items[index];
                return _SupportPointCard(
                  item: item,
                  selected: selectedId == item.id,
                  onTap: () => onSelected(item),
                );
              },
            ),
    );
  }
}

class _SupportPointCard extends StatelessWidget {
  const _SupportPointCard({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final SupportPoint item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = supportCategoryColor(item.category);
    return Material(
      color: selected ? AppColors.surfaceSoft : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 39,
                    height: 39,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      supportCategoryIcon(item.category),
                      color: color,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          supportCategoryLabel(item.category),
                          style: TextStyle(
                            color: color,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (item.isVerified)
                    const Tooltip(
                      message: 'Informações verificadas',
                      child: Icon(
                        Icons.verified_rounded,
                        color: AppColors.safe,
                        size: 19,
                      ),
                    )
                  else
                    const Tooltip(
                      message: 'Informações não verificadas',
                      child: Icon(
                        Icons.science_outlined,
                        color: AppColors.warning,
                        size: 19,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 11),
              _InfoLine(
                icon: Icons.location_on_outlined,
                text: '${item.address} • ${item.city}/${item.state}',
              ),
              if (item.openingHours case final hours?) ...[
                const SizedBox(height: 6),
                _InfoLine(icon: Icons.schedule_rounded, text: hours),
              ],
              if (item.description case final description?) ...[
                const SizedBox(height: 9),
                Text(
                  description,
                  maxLines: selected ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11.5,
                  ),
                ),
              ],
              if (item.phone case final phone?) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => launchUrl(
                      Uri(scheme: 'tel', path: phone),
                    ),
                    icon: const Icon(Icons.phone_outlined, size: 17),
                    label: Text('Ligar para $phone'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11.5,
            ),
          ),
        ),
      ],
    );
  }
}
