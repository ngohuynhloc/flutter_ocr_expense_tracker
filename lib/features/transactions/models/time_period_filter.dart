enum TimePeriodFilter {
  allTime,
  thisWeek,
  thisMonth,
  lastMonth,
}

extension TimePeriodFilterExtension on TimePeriodFilter {
  String get displayName {
    switch (this) {
      case TimePeriodFilter.allTime:
        return 'Tất cả';
      case TimePeriodFilter.thisWeek:
        return 'Tuần này';
      case TimePeriodFilter.thisMonth:
        return 'Tháng này';
      case TimePeriodFilter.lastMonth:
        return 'Tháng trước';
    }
  }

  /// Trả về khoảng [startDate, endDate] tương ứng với bộ lọc
  ({DateTime? start, DateTime? end}) getDateRange() {
    final now = DateTime.now();
    switch (this) {
      case TimePeriodFilter.allTime:
        return (start: null, end: null);

      case TimePeriodFilter.thisWeek:
        final monday = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        final sunday = monday.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        return (start: monday, end: sunday);

      case TimePeriodFilter.thisMonth:
        final firstDay = DateTime(now.year, now.month, 1);
        final lastDay = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return (start: firstDay, end: lastDay);

      case TimePeriodFilter.lastMonth:
        final firstDayLastMonth = DateTime(now.year, now.month - 1, 1);
        final lastDayLastMonth = DateTime(now.year, now.month, 0, 23, 59, 59);
        return (start: firstDayLastMonth, end: lastDayLastMonth);
    }
  }
}
