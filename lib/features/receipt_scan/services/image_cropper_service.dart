import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../core/theme/app_theme.dart';

class ImageCropperService {
  /// Cắt và nắn góc ảnh biên lai
  static Future<File?> cropReceiptImage(String sourcePath) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      compressQuality: 90,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Cắt góc hoá đơn',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          activeControlsWidgetColor: AppColors.primary,
          dimmedLayerColor: Colors.black.withOpacity(0.8),
          cropFrameColor: Colors.white,
          cropGridColor: Colors.white.withOpacity(0.5),
        ),
        IOSUiSettings(
          title: 'Cắt góc hoá đơn',
          aspectRatioLockEnabled: false,
          resetAspectRatioEnabled: true,
        ),
      ],
    );

    if (croppedFile != null) {
      return File(croppedFile.path);
    }
    return null;
  }
}
