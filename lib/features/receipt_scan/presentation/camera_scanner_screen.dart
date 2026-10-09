import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../transactions/models/transaction_model.dart';
import '../services/image_cropper_service.dart';
import '../services/image_storage_service.dart';
import '../services/mlkit_text_recognizer_service.dart';
import '../services/receipt_heuristic_parser.dart';
import '../widgets/camera_overlay_painter.dart';
import '../widgets/focus_indicator.dart';
import 'receipt_review_screen.dart';

class CameraScannerScreen extends StatefulWidget {
  final Function(String imagePath)? onReceiptCaptured;
  final Function(TransactionModel transaction)? onTransactionSaved;

  const CameraScannerScreen({
    super.key,
    this.onReceiptCaptured,
    this.onTransactionSaved,
  });

  @override
  State<CameraScannerScreen> createState() => _CameraScannerScreenState();
}

class _CameraScannerScreenState extends State<CameraScannerScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _isTorchOn = false;

  // Focus Animation
  Offset? _focusPosition;
  late AnimationController _focusAnimController;

  @override
  void initState() {
    super.initState();
    _focusAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _initCamera();
  }

  @override
  void dispose() {
    _focusAnimController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _isCameraInitialized = false);
        return;
      }

      // Ưu tiên camera sau
      final backCamera = _cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isCameraInitialized = false);
      }
    }
  }

  Future<void> _toggleTorch() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      if (_isTorchOn) {
        await _cameraController!.setFlashMode(FlashMode.off);
      } else {
        await _cameraController!.setFlashMode(FlashMode.torch);
      }
      setState(() => _isTorchOn = !_isTorchOn);
    } catch (_) {}
  }

  Future<void> _onTapToFocus(TapDownDetails details, BoxConstraints constraints) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    final offset = details.localPosition;
    setState(() => _focusPosition = offset);

    _focusAnimController.reset();
    _focusAnimController.forward();

    // Chuyển đổi toạ độ pixel thành tỷ lệ 0.0 - 1.0 cho camera
    final double x = (offset.dx / constraints.maxWidth).clamp(0.0, 1.0);
    final double y = (offset.dy / constraints.maxHeight).clamp(0.0, 1.0);

    try {
      await _cameraController!.setFocusPoint(Offset(x, y));
      await _cameraController!.setExposurePoint(Offset(x, y));
    } catch (_) {}
  }

  Future<void> _processImageFile(File rawImageFile) async {
    setState(() => _isProcessing = true);
    try {
      // 1. Cắt nắn góc ảnh biên lai
      final croppedFile = await ImageCropperService.cropReceiptImage(rawImageFile.path);
      final finalFile = croppedFile ?? rawImageFile;

      // 2. Lưu vào thư mục documents của ứng dụng
      final savedPath = await ImageStorageService.saveReceiptImage(finalFile);
      widget.onReceiptCaptured?.call(savedPath);

      // 3. Chạy On-Device Text Recognition với Google ML Kit
      final ocrService = MLKitTextRecognizerService();
      final ocrResult = await ocrService.recognizeText(savedPath);
      ocrService.dispose();

      // 4. Bóc tách bằng Regex Heuristic Engine
      final parsedReceipt = ReceiptHeuristicParser.parse(
        fullText: ocrResult.fullText,
        lines: ocrResult.lines,
      );

      // 5. Mở màn hình Review trước khi lưu
      if (mounted) {
        final resultTransaction = await Navigator.of(context).push<TransactionModel>(
          MaterialPageRoute(
            builder: (_) => ReceiptReviewScreen(
              imagePath: savedPath,
              parsedResult: parsedReceipt,
              onSave: (tx) {
                widget.onTransactionSaved?.call(tx);
              },
            ),
          ),
        );

        // Sau khi lưu xong, tự động đóng màn hình camera
        if (mounted && resultTransaction != null) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xử lý ảnh: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isProcessing) {
      return;
    }

    try {
      final XFile photo = await _cameraController!.takePicture();
      await _processImageFile(File(photo.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể chụp ảnh: $e')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );

    if (pickedFile != null) {
      await _processImageFile(File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Tính kích thước khung ngắm biên lai (3:4 aspect ratio)
    final cutoutWidth = size.width * 0.85;
    final cutoutHeight = cutoutWidth * 1.35;
    final cutoutRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.42),
      width: cutoutWidth,
      height: cutoutHeight,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Preview hoặc Fallback
          if (_isCameraInitialized && _cameraController != null)
            LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapDown: (details) => _onTapToFocus(details, constraints),
                  child: Center(
                    child: CameraPreview(_cameraController!),
                  ),
                );
              },
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt_outlined, color: Colors.white54, size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'Camera không khả dụng hoặc đang chạy trên máy ảo',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _pickFromGallery,
                      icon: const Icon(Icons.photo_library_rounded),
                      label: const Text('Chọn ảnh từ thư viện'),
                    ),
                  ],
                ),
              ),
            ),

          // 2. Custom Painter Khung ngắm hoá đơn
          CustomPaint(
            size: size,
            painter: CameraOverlayPainter(
              cutoutRect: cutoutRect,
              cornerColor: Colors.amberAccent,
            ),
          ),

          // 3. Focus Touch Ring Animation
          if (_focusPosition != null)
            FocusIndicator(
              position: _focusPosition!,
              animation: _focusAnimController,
            ),

          // 4. Header Bar (Back button, Flash button, Title)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  tooltip: 'Quay lại',
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.crop_free, color: Colors.amberAccent, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Quét biên lai',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _toggleTorch,
                  icon: Icon(
                    _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    color: _isTorchOn ? Colors.amberAccent : Colors.white,
                  ),
                  tooltip: 'Đèn Flash',
                ),
              ],
            ),
          ),

          // 5. Instruction text guideline
          Positioned(
            top: cutoutRect.bottom + 16,
            left: 20,
            right: 20,
            child: const Center(
              child: Text(
                'Căn chỉnh hoá đơn vào trong khung & chạm để lấy nét',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  shadows: [
                    Shadow(color: Colors.black, blurRadius: 4),
                  ],
                ),
              ),
            ),
          ),

          // 6. Bottom Controls Bar
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Gallery button
                IconButton(
                  onPressed: _isProcessing ? null : _pickFromGallery,
                  iconSize: 32,
                  icon: const Icon(Icons.photo_library_outlined, color: Colors.white),
                  tooltip: 'Chọn ảnh có sẵn',
                ),

                // Shutter button
                GestureDetector(
                  onTap: _isProcessing ? null : _takePicture,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: _isProcessing
                          ? const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.black87,
                              size: 32,
                            ),
                    ),
                  ),
                ),

                // Empty placeholder for balance
                const SizedBox(width: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
