import 'package:flutter/material.dart';
import '../../../../app/theme.dart';

String supportCategoryLabel(String category) => switch (category) {
      'support_center' => 'Centro de acolhimento',
      'police_station' => 'Atendimento policial',
      'health' => 'Atendimento de saúde',
      'legal' => 'Orientação jurídica',
      _ => 'Ponto de apoio',
    };

IconData supportCategoryIcon(String category) => switch (category) {
      'support_center' => Icons.favorite_outline_rounded,
      'police_station' => Icons.local_police_outlined,
      'health' => Icons.local_hospital_outlined,
      'legal' => Icons.balance_outlined,
      _ => Icons.place_outlined,
    };

Color supportCategoryColor(String category) => switch (category) {
      'support_center' => AppColors.secondary,
      'police_station' => AppColors.primary,
      'health' => AppColors.safe,
      'legal' => AppColors.warning,
      _ => AppColors.textMuted,
    };
