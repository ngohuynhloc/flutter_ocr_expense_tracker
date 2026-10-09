import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _vndFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  static final NumberFormat _compactVndFormat = NumberFormat.compact(
    locale: 'vi_VN',
  );

  /// Format số tiền sang chuẩn hiển thị Việt Nam (VD: 150.000 ₫)
  static String formatVND(double amount) {
    return _vndFormat.format(amount).trim();
  }

  /// Format số tiền dạng rút gọn cho trục biểu đồ (VD: 1.5M, 200K)
  static String formatCompact(double amount) {
    return _compactVndFormat.format(amount);
  }
}
