import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

enum ExpenseCategory {
  food,
  study,
  travel,
  gear,
  entertainment,
  others;

  String get displayName {
    switch (this) {
      case ExpenseCategory.food:
        return 'Ăn uống';
      case ExpenseCategory.study:
        return 'Học tập';
      case ExpenseCategory.travel:
        return 'Di chuyển';
      case ExpenseCategory.gear:
        return 'Thiết bị';
      case ExpenseCategory.entertainment:
        return 'Giải trí';
      case ExpenseCategory.others:
        return 'Khác';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.food:
        return Icons.restaurant_rounded;
      case ExpenseCategory.study:
        return Icons.school_rounded;
      case ExpenseCategory.travel:
        return Icons.two_wheeler_rounded;
      case ExpenseCategory.gear:
        return Icons.devices_rounded;
      case ExpenseCategory.entertainment:
        return Icons.sports_esports_rounded;
      case ExpenseCategory.others:
        return Icons.receipt_long_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.food:
        return AppColors.categoryFood;
      case ExpenseCategory.study:
        return AppColors.categoryStudy;
      case ExpenseCategory.travel:
        return AppColors.categoryTravel;
      case ExpenseCategory.gear:
        return AppColors.categoryGear;
      case ExpenseCategory.entertainment:
        return AppColors.categoryEntertainment;
      case ExpenseCategory.others:
        return AppColors.categoryOthers;
    }
  }

  String toDbString() => name;

  static ExpenseCategory fromDbString(String? value) {
    if (value == null) return ExpenseCategory.others;
    return ExpenseCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ExpenseCategory.others,
    );
  }
}
