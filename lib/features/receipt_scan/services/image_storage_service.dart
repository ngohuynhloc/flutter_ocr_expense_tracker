import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageStorageService {
  /// Lưu file ảnh biên lai vào thư mục Documents của ứng dụng
  /// Trả về đường dẫn tuyệt đối của file đã lưu
  static Future<String> saveReceiptImage(File sourceFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final receiptsDir = Directory(p.join(appDir.path, 'receipts'));

    if (!await receiptsDir.exists()) {
      await receiptsDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = p.extension(sourceFile.path).isNotEmpty
        ? p.extension(sourceFile.path)
        : '.jpg';
    final fileName = 'receipt_$timestamp$extension';
    final destinationPath = p.join(receiptsDir.path, fileName);

    final savedFile = await sourceFile.copy(destinationPath);
    return savedFile.path;
  }

  /// Xoá file ảnh biên lai khi xoá giao dịch
  static Future<bool> deleteReceiptImage(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (_) {}
    return false;
  }
}
