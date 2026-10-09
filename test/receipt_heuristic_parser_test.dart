import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_expense_tracker/features/receipt_scan/services/receipt_heuristic_parser.dart';
import 'package:ocr_expense_tracker/features/transactions/models/expense_category.dart';

void main() {
  group('ReceiptHeuristicParser Tests', () {
    test('Phân tích hoá đơn siêu thị WinMart', () {
      final lines = [
        'SIÊU THỊ WINMART+',
        'HÓA ĐƠN BÁN LẺ',
        'MST: 0104918404',
        'Ngày: 28/09/2026 14:30',
        'Bánh mì sandwich: 25.000',
        'Sữa tươi Vinamilk: 38.000',
        'Nước ngọt Coca: 15.000',
        'Tổng cộng: 78.000 đ',
        'Tiền mặt: 100.000 đ',
        'Tiền thối: 22.000 đ',
        'Xin cảm ơn quý khách!',
      ];
      final fullText = lines.join('\n');

      final result = ReceiptHeuristicParser.parse(fullText: fullText, lines: lines);

      expect(result.merchantName, contains('WinMart'));
      expect(result.amount, equals(78000.0));
      expect(result.transactionDate.day, equals(28));
      expect(result.transactionDate.month, equals(9));
      expect(result.transactionDate.year, equals(2026));
      expect(result.predictedCategory, equals(ExpenseCategory.food));
    });

    test('Phân tích hoá đơn quán cafe Highlands', () {
      final lines = [
        'HIGHLANDS COFFEE',
        'PHIẾU TÍNH TIỀN',
        'Số bàn: T2-05',
        'Ngày GD: 25/09/2026 09:15',
        '1 Phin Sữa Đá (L): 45.000',
        '1 Bánh Mousse Cacao: 35.000',
        'Thành tiền: 80,000 VND',
        'Khách phải trả: 80,000 VND',
      ];
      final fullText = lines.join('\n');

      final result = ReceiptHeuristicParser.parse(fullText: fullText, lines: lines);

      expect(result.merchantName, equals('Highlands Coffee'));
      expect(result.amount, equals(80000.0));
      expect(result.transactionDate.day, equals(25));
      expect(result.transactionDate.month, equals(9));
      expect(result.predictedCategory, equals(ExpenseCategory.food));
    });

    test('Phân tích hoá đơn cây xăng Petrolimex', () {
      final lines = [
        'CÔNG TY XĂNG DẦU PETROLIMEX',
        'CỬA HÀNG SỐ 12',
        'Ngày: 20/09/2026',
        'Xăng RON 95-III: 2.2 lít',
        'Tổng thanh toán: 50.000 VNĐ',
      ];
      final fullText = lines.join('\n');

      final result = ReceiptHeuristicParser.parse(fullText: fullText, lines: lines);

      expect(result.merchantName, equals('Petrolimex'));
      expect(result.amount, equals(50000.0));
      expect(result.predictedCategory, equals(ExpenseCategory.travel));
    });

    test('Phân tích hoá đơn nhà sách Fahasa', () {
      final lines = [
        'NHÀ SÁCH FAHASA NGUYỄN HUỆ',
        'BIÊN LAI BÁN HÀNG',
        '22/09/2026',
        'Sách Lập trình Flutter & Dart',
        'Tổng cộng',
        '168.000 đ',
      ];
      final fullText = lines.join('\n');

      final result = ReceiptHeuristicParser.parse(fullText: fullText, lines: lines);

      expect(result.merchantName, equals('Fahasa'));
      expect(result.amount, equals(168000.0));
      expect(result.predictedCategory, equals(ExpenseCategory.study));
    });

    test('Phân tích hoá đơn cửa hàng công nghệ FPT Shop', () {
      final lines = [
        'HỆ THỐNG FPT SHOP',
        'HÓA ĐƠN GTGT',
        'Chuột không dây Logitech: 350.000 đ',
        'Total: 350,000',
        'Ngày xuất: 15/09/2026',
      ];
      final fullText = lines.join('\n');

      final result = ReceiptHeuristicParser.parse(fullText: fullText, lines: lines);

      expect(result.merchantName, equals('FPT Shop'));
      expect(result.amount, equals(350000.0));
      expect(result.predictedCategory, equals(ExpenseCategory.gear));
    });
  });
}
