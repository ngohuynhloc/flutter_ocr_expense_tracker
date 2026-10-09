import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _dayMonthYear = DateFormat('dd/MM/yyyy');
  static final DateFormat _dayMonthYearTime = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _shortDate = DateFormat('dd/MM');
  static final DateFormat _weekdayShort = DateFormat('E', 'vi_VN');

  static String formatDMY(DateTime date) {
    return _dayMonthYear.format(date);
  }

  static String formatDMYTime(DateTime date) {
    return _dayMonthYearTime.format(date);
  }

  static String formatShort(DateTime date) {
    return _shortDate.format(date);
  }

  static String formatWeekday(DateTime date) {
    return _weekdayShort.format(date);
  }

  /// Format nhãn hiển thị thông minh: Hôm nay, Hôm qua hoặc dd/MM/yyyy
  static String formatSmart(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final aDate = DateTime(date.year, date.month, date.day);

    if (aDate == today) {
      return 'Hôm nay';
    } else if (aDate == today.subtract(const Duration(days: 1))) {
      return 'Hôm qua';
    } else {
      return _dayMonthYear.format(date);
    }
  }

  /// Format khoảng ngày trong tuần: "06/10 - 12/10/2026"
  static String formatWeekRange(DateTime monday) {
    final sunday = monday.add(const Duration(days: 6));
    if (monday.year == sunday.year) {
      return '${DateFormat('dd/MM').format(monday)} - ${DateFormat('dd/MM/yyyy').format(sunday)}';
    } else {
      return '${DateFormat('dd/MM/yyyy').format(monday)} - ${DateFormat('dd/MM/yyyy').format(sunday)}';
    }
  }

  /// Kiểm tra xem ngày thứ 2 này có phải tuần hiện tại không
  static bool isCurrentWeek(DateTime monday) {
    final now = DateTime.now();
    final currentMonday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    return monday.year == currentMonday.year &&
        monday.month == currentMonday.month &&
        monday.day == currentMonday.day;
  }
}
