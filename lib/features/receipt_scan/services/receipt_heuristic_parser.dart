import '../../transactions/models/expense_category.dart';
import '../models/parsed_receipt_result.dart';

class ReceiptHeuristicParser {
  /// Phân tích toàn bộ văn bản OCR và trả về kết quả dự đoán
  static ParsedReceiptResult parse({
    required String fullText,
    required List<String> lines,
  }) {
    final merchant = extractMerchant(lines);
    final amount = extractTotalAmount(lines, fullText);
    final date = extractDate(lines, fullText);
    final category = predictCategory(merchant, fullText);

    return ParsedReceiptResult(
      merchantName: merchant,
      amount: amount,
      transactionDate: date,
      predictedCategory: category,
      rawText: fullText,
    );
  }

  /// 1. Trích xuất tên đơn vị bán lẻ (Merchant Name)
  static String extractMerchant(List<String> lines) {
    if (lines.isEmpty) return 'Chi tiêu từ biên lai';

    // Danh sách các chuỗi cửa hàng / thương hiệu phổ biến tại Việt Nam
    final knownBrands = [
      'Highlands Coffee', 'Phúc Long', 'The Coffee House', 'Trung Nguyên',
      'Circle K', 'GS25', '7-Eleven', 'FamilyMart', 'Ministop',
      'WinMart', 'WinMart+', 'Co.opmart', 'Co.op Food', 'Co.opXtra',
      'Bách Hóa Xanh', 'Lotte Mart', 'Aeon Mall', 'Mega Market', 'Big C', 'GO!',
      'KFC', 'Lotteria', 'McDonald\'s', 'Jollibee', 'Pizza Hut', 'The Pizza Company',
      'FPT Shop', 'Thế Giới Di Động', 'Điện Máy Xanh', 'CellphoneS', 'An Phát', 'GearVN',
      'Fahasa', 'Nhà sách Phương Nam', 'Tiệm Sách',
      'Petrolimex', 'PVOIL', 'CGV Cinema', 'Lotte Cinema', 'BHD Star',
    ];

    // Kiểm tra khớp thương hiệu đã biết trong 8 dòng đầu tiên
    final checkLimit = lines.length < 8 ? lines.length : 8;
    for (int i = 0; i < checkLimit; i++) {
      final line = lines[i];
      for (final brand in knownBrands) {
        if (line.toLowerCase().contains(brand.toLowerCase())) {
          return brand;
        }
      }
    }

    // Danh sách từ khoá nhận diện dòng thông tin rác ở đầu hoá đơn
    final noiseKeywords = [
      'hóa đơn', 'hoa don', 'phiếu thanh toán', 'phieu thanh toan',
      'phiếu tính tiền', 'phieu tinh tien', 'biên lai', 'receipt', 'bill',
      'tax invoice', 'vat', 'mã số thuế', 'mst', 'địa chỉ', 'dia chi',
      'tel:', 'sđt:', 'phone:', 'hotline:', 'ngày:', 'ngay:', 'giờ:', 'thu ngân:',
      'bàn:', 'khách hàng:', 'stt', 'đơn giá', 'sl', 'thành tiền',
    ];

    // Quét 4 dòng đầu tiên để lấy dòng hợp lệ đầu tiên không phải từ khoá rác
    for (int i = 0; i < checkLimit; i++) {
      final cleanLine = lines[i].trim();
      if (cleanLine.length < 3 || cleanLine.length > 45) continue;

      final lower = cleanLine.toLowerCase();
      final isNoise = noiseKeywords.any((k) => lower.contains(k));
      final isOnlyDigits = RegExp(r'^[\d\s\-_.:/]+$').hasMatch(cleanLine);

      if (!isNoise && !isOnlyDigits) {
        // Chuẩn hoá tên: loại bỏ ký tự đặc biệt ở đầu/cuối
        return cleanLine.replaceAll(RegExp(r'^[^a-zA-Z0-9À-ỹ]+|[^a-zA-Z0-9À-ỹ]+$'), '');
      }
    }

    return lines.first;
  }

  /// 2. Trích xuất tổng tiền thanh toán (Total Amount)
  static double extractTotalAmount(List<String> lines, String fullText) {
    // Từ khoá chỉ tổng tiền cần thanh toán
    final totalKeywords = [
      'tổng cộng', 'tong cong', 'tổng tiền', 'tong tien',
      'thanh toán', 'thanh toan', 'tiền thanh toán', 'khách phải trả',
      'cần thanh toán', 'total', 'grand total', 'amount due', 'net total',
      'tiền mặt', 'tien mat', 'phải thanh toán', 'số tiền',
    ];

    // Ưu tiên 1: Tìm dòng chứa từ khoá "tổng cộng", "thanh toán",...
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();

      final hasKeyword = totalKeywords.any((k) => lower.contains(k));
      if (hasKeyword) {
        // Tìm số trên cùng dòng
        final amountOnSameLine = _parseAmountFromText(line);
        if (amountOnSameLine != null && amountOnSameLine > 0) {
          return amountOnSameLine;
        }

        // Nếu cùng dòng không có số, kiểm tra dòng ngay kế tiếp
        if (i + 1 < lines.length) {
          final amountOnNextLine = _parseAmountFromText(lines[i + 1]);
          if (amountOnNextLine != null && amountOnNextLine > 0) {
            return amountOnNextLine;
          }
        }
      }
    }

    // Ưu tiên 2: Tìm các cụm số có kèm đuôi tiền tệ "đ", "vnd", "k"
    final currencyPattern = RegExp(
      r'(\d{1,3}(?:[.,]\d{3})+|\d+)\s*(?:đ|vnd|vnđ|đồng)\b',
      caseSensitive: false,
    );
    final currencyMatches = currencyPattern.allMatches(fullText);
    double maxCurrencyAmount = 0.0;
    for (final match in currencyMatches) {
      final rawNum = match.group(1);
      if (rawNum != null) {
        final val = _cleanNumberString(rawNum);
        if (val > maxCurrencyAmount && _isValidExpenseAmount(val)) {
          maxCurrencyAmount = val;
        }
      }
    }
    if (maxCurrencyAmount > 0) return maxCurrencyAmount;

    // Ưu tiên 3: Quét ngược từ cuối hoá đơn lên (thường tổng tiền nằm ở gần cuối)
    for (int i = lines.length - 1; i >= 0; i--) {
      final val = _parseAmountFromText(lines[i]);
      if (val != null && _isValidExpenseAmount(val)) {
        return val;
      }
    }

    return 0.0;
  }

  static double? _parseAmountFromText(String text) {
    // Bắt số dạng 150.000 hoặc 150,000 hoặc 150000
    final regex = RegExp(r'\b(?:\d{1,3}(?:[.,]\d{3})+|\d{4,9})\b');
    final matches = regex.allMatches(text);

    double maxInLine = 0.0;
    for (final match in matches) {
      final raw = match.group(0);
      if (raw != null) {
        final val = _cleanNumberString(raw);
        if (val > maxInLine && _isValidExpenseAmount(val)) {
          maxInLine = val;
        }
      }
    }
    return maxInLine > 0 ? maxInLine : null;
  }

  static double _cleanNumberString(String raw) {
    // Loại bỏ dấu chấm, phẩy phân cách hàng nghìn
    final sanitized = raw.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(sanitized) ?? 0.0;
  }

  static bool _isValidExpenseAmount(double val) {
    // Loại bỏ số điện thoại (10 chữ số bắt đầu bằng 0) hoặc mã số quá lớn
    // Tiền chi tiêu thực tế thông thường từ 1.000 VNĐ đến 500.000.000 VNĐ
    if (val < 1000 || val > 500000000) return false;
    // Kiểm tra không phải năm (e.g. 2024, 2025, 2026)
    if (val >= 2020 && val <= 2035) return false;
    return true;
  }

  /// 3. Trích xuất ngày giao dịch (Transaction Date)
  static DateTime extractDate(List<String> lines, String fullText) {
    // Mẫu 1: DD/MM/YYYY hoặc DD-MM-YYYY hoặc DD.MM.YYYY
    final dmyPattern = RegExp(r'\b([0-3]?\d)[/\-.]([0-1]?\d)[/\-.](\d{4})\b');
    // Mẫu 2: YYYY/MM/DD hoặc YYYY-MM-DD
    final ymdPattern = RegExp(r'\b(\d{4})[/\-.]([0-1]?\d)[/\-.]([0-3]?\d)\b');
    // Mẫu 3: DD/MM/YY
    final dmyShortPattern = RegExp(r'\b([0-3]?\d)[/\-.]([0-1]?\d)[/\-.](\d{2})\b');

    // Kiểm tra theo thứ tự ưu tiên
    final dmyMatch = dmyPattern.firstMatch(fullText);
    if (dmyMatch != null) {
      final day = int.tryParse(dmyMatch.group(1)!) ?? 1;
      final month = int.tryParse(dmyMatch.group(2)!) ?? 1;
      final year = int.tryParse(dmyMatch.group(3)!) ?? DateTime.now().year;
      if (_isValidDate(day, month, year)) {
        return DateTime(year, month, day);
      }
    }

    final ymdMatch = ymdPattern.firstMatch(fullText);
    if (ymdMatch != null) {
      final year = int.tryParse(ymdMatch.group(1)!) ?? DateTime.now().year;
      final month = int.tryParse(ymdMatch.group(2)!) ?? 1;
      final day = int.tryParse(ymdMatch.group(3)!) ?? 1;
      if (_isValidDate(day, month, year)) {
        return DateTime(year, month, day);
      }
    }

    final dmyShortMatch = dmyShortPattern.firstMatch(fullText);
    if (dmyShortMatch != null) {
      final day = int.tryParse(dmyShortMatch.group(1)!) ?? 1;
      final month = int.tryParse(dmyShortMatch.group(2)!) ?? 1;
      final shortYear = int.tryParse(dmyShortMatch.group(3)!) ?? 26;
      final year = 2000 + shortYear;
      if (_isValidDate(day, month, year)) {
        return DateTime(year, month, day);
      }
    }

    // Mặc định là ngày hiện tại nếu không tìm thấy
    return DateTime.now();
  }

  static bool _isValidDate(int day, int month, int year) {
    if (month < 1 || month > 12) return false;
    if (day < 1 || day > 31) return false;
    if (year < 2000 || year > 2035) return false;
    return true;
  }

  /// 4. Dự đoán danh mục chi tiêu tự động (Category Prediction)
  static ExpenseCategory predictCategory(String merchant, String fullText) {
    final combined = '$merchant $fullText'.toLowerCase();

    // Food & Dining
    final foodKeywords = [
      'cafe', 'coffee', 'cà phê', 'trà sữa', 'milktea', 'phở', 'bún', 'cơm',
      'quán ăn', 'nhà hàng', 'restaurant', 'bánh mì', 'pizza', 'kfc', 'lotteria',
      'jollibee', 'mcdonald', 'burger', 'lẩu', 'nướng', 'bbq', 'sushi', 'thịt',
      'highlands', 'phúc long', 'the coffee house', 'trung nguyên',
      'circle k', 'gs25', '7-eleven', 'familymart', 'winmart', 'co.op',
      'bách hóa xanh', 'lotte mart', 'siêu thị', 'mart', 'market', 'chợ',
    ];
    for (final k in foodKeywords) {
      if (combined.contains(k)) return ExpenseCategory.food;
    }

    // Study & Education
    final studyKeywords = [
      'nhà sách', 'tiệm sách', 'fahasa', 'phương nam', 'sách', 'book',
      'văn phòng phẩm', 'stationery', 'in ấn', 'photo', 'photocopy',
      'học phí', 'khóa học', 'tập vở', 'bút', 'đại học', 'trường',
    ];
    for (final k in studyKeywords) {
      if (combined.contains(k)) return ExpenseCategory.study;
    }

    // Travel & Transportation
    final travelKeywords = [
      'xăng', 'petrolimex', 'pvoil', 'dầu', 'grab', 'be', 'gojek',
      'xanh sm', 'taxi', 'mai linh', 'vina sun', 'vé xe', 'vé tàu',
      'vé máy bay', 'vietnam airlines', 'vietjet', 'vé bến', 'giữ xe', 'gửi xe',
    ];
    for (final k in travelKeywords) {
      if (combined.contains(k)) return ExpenseCategory.travel;
    }

    // Tech & Gear
    final gearKeywords = [
      'fpt shop', 'thế giới di động', 'tgdd', 'cellphones', 'an phát',
      'gearvn', 'hacom', 'hanoicomputer', 'phụ kiện', 'điện thoại',
      'laptop', 'tai nghe', 'chuột máy tính', 'bàn phím', 'cáp sạc', 'linh kiện',
    ];
    for (final k in gearKeywords) {
      if (combined.contains(k)) return ExpenseCategory.gear;
    }

    // Entertainment
    final entertainmentKeywords = [
      'cgv', 'lotte cinema', 'bhd star', 'galaxy cinema', 'rạp chiếu phim',
      'vé phim', 'billiards', 'bida', 'karaoke', 'bowling', 'game',
      'playstation', 'net quán', 'cyber',
    ];
    for (final k in entertainmentKeywords) {
      if (combined.contains(k)) return ExpenseCategory.entertainment;
    }

    return ExpenseCategory.others;
  }
}
