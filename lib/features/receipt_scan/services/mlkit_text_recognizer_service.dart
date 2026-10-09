import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class MLKitTextRecognizerService {
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  /// Nhận diện văn bản trên ảnh cục bộ hoàn toàn offline
  /// Trả về chuỗi văn bản thô và danh sách các dòng văn bản
  Future<({String fullText, List<String> lines})> recognizeText(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

    final StringBuffer fullTextBuffer = StringBuffer();
    final List<String> extractedLines = [];

    for (final TextBlock block in recognizedText.blocks) {
      for (final TextLine line in block.lines) {
        final text = line.text.trim();
        if (text.isNotEmpty) {
          extractedLines.add(text);
          fullTextBuffer.writeln(text);
        }
      }
    }

    return (
      fullText: fullTextBuffer.toString(),
      lines: extractedLines,
    );
  }

  void dispose() {
    _textRecognizer.close();
  }
}
