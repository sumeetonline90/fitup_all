import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/vital_status.dart';

/// Presentation mapping for vital status → accent dot color.
Color vitalStatusColor(VitalStatus status) {
  return switch (status) {
    VitalStatus.normal => AppColors.primaryContainer,
    VitalStatus.borderline => AppColors.primary,
    VitalStatus.elevated => AppColors.error,
    VitalStatus.unknown => AppColors.onSurfaceVariant,
  };
}
