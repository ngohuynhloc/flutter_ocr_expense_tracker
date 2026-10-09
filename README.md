# Mini-Project 3: OCR Expense Tracker & Receipt Parser (Flutter & Dart)

Ứng dụng quản lý tài chính và chi tiêu cá nhân hoàn toàn offline trên thiết bị với On-Device AI Vision (Google ML Kit), bộ quy tắc Regex Heuristic bóc tách hóa đơn tiếng Việt & quốc tế, cơ sở dữ liệu SQLite cục bộ, và hệ thống biểu đồ trực quan hóa được vẽ trực tiếp bằng Flutter `CustomPainter` (zero 3rd-party chart library).

---

## 🚀 Tính năng Cốt lõi (Core Features)

1. **Camera Viewfinder & Cắt góc biên lai**:
   - Khung ngắm định vị biên lai tỉ lệ 3:4 với 4 góc căn chỉnh nổi bật (`CameraOverlayPainter`).
   - Bật/tắt đèn Flash (`torch` / `off`).
   - Chạm lấy nét đa điểm (`setFocusPoint`) kèm hiệu ứng animation vòng lấy nét màu hổ phách.
   - Hỗ trợ cắt nắn góc ảnh (`image_cropper`) trước khi đưa vào OCR.
   - Lưu trữ và quản lý cache ảnh biên lai cục bộ trong thư mục Documents.

2. **On-Device Vision AI & Regex Heuristics Engine**:
   - Tích hợp `google_mlkit_text_recognition` chạy 100% offline (độ trễ < 100ms, không tốn chi phí Cloud).
   - Bộ bóc tách thông minh `ReceiptHeuristicParser`:
     - Nhận diện thương hiệu & điểm bán (WinMart, Highlands, Circle K, Petrolimex, Fahasa, FPT Shop,...).
     - Lọc bỏ rác đầu hóa đơn (MST, SĐT, Hotline, Thu ngân, Hóa đơn,...).
     - Trích xuất tổng tiền thanh toán chuẩn Việt Nam (`150.000 đ`, `150,000 VND`, `150k`).
     - Bóc tách ngày giao dịch (`DD/MM/YYYY`, `DD-MM-YYYY`, `YYYY-MM-DD`).
     - Tự động dự đoán danh mục (*Food, Study, Travel, Gear, Entertainment, Others*).
   - Màn hình Review biên lai tương tác (`ReceiptReviewScreen`) cho phép người dùng sửa đổi 100% dữ liệu trước khi lưu vào máy.

3. **Cơ sở dữ liệu Cục bộ SQLite**:
   - Quản lý giao dịch bằng `sqflite` với Index tối ưu truy vấn theo ngày và danh mục.
   - Đầy đủ tính năng CRUD: Thêm mới, Chỉnh sửa, Xoá bằng cử chỉ vuốt (*Swipe-to-delete*) có nút Hoàn tác (*Undo*).

4. **Biểu đồ Canvas Tự vẽ với `CustomPainter` (Không dùng thư viện thứ 3)**:
   - **Animated Donut Chart**: Biểu đồ tròn/vành khăn phân bổ danh mục có animation quét góc mượt mà, hỗ trợ chạm tương tác vào từng lát cắt để phóng to và xem chi tiết tỉ lệ % ở tâm biểu đồ.
   - **Weekly Spending Bar Chart**: Biểu đồ cột 7 ngày trong tuần (T2 - CN) với các đường lưới ngang chấm mờ, nhãn trục tọa độ và tooltip hiển thị số tiền khi chạm vào cột.

---

## 📂 Cấu trúc Thư mục Dự án

```
lib/
├── core/
│   ├── database/
│   │   └── database_helper.dart             # Quản lý SQLite singleton, schema và index
│   ├── theme/
│   │   └── app_theme.dart                   # Bảng màu AppColors và Theme Material 3
│   └── utils/
│       ├── currency_formatter.dart          # Định dạng tiền tệ VNĐ và dạng rút gọn
│       └── date_formatter.dart              # Định dạng ngày thông minh
├── features/
│   ├── analytics/                           # Phân tích & Trực quan hoá dữ liệu Canvas
│   │   ├── presentation/
│   │   │   └── analytics_dashboard_screen.dart
│   │   └── widgets/
│   │       ├── animated_donut_chart.dart
│   │       ├── donut_chart_painter.dart
│   │       ├── weekly_bar_chart_painter.dart
│   │       └── weekly_spending_bar_chart.dart
│   ├── receipt_scan/                        # Camera, ML Kit OCR & Parser
│   │   ├── models/
│   │   │   └── parsed_receipt_result.dart
│   │   ├── presentation/
│   │   │   ├── camera_scanner_screen.dart
│   │   │   └── receipt_review_screen.dart
│   │   ├── services/
│   │   │   ├── image_cropper_service.dart
│   │   │   ├── image_storage_service.dart
│   │   │   ├── mlkit_text_recognizer_service.dart
│   │   │   └── receipt_heuristic_parser.dart
│   │   └── widgets/
│   │       ├── camera_overlay_painter.dart
│   │       └── focus_indicator.dart
│   └── transactions/                        # Quản lý giao dịch chi tiêu
│       ├── controllers/
│       │   └── transaction_controller.dart
│       ├── models/
│       │   ├── expense_category.dart
│       │   └── transaction_model.dart
│       ├── presentation/
│       │   ├── transaction_list_screen.dart
│       │   └── widgets/
│       │       ├── add_edit_transaction_dialog.dart
│       │       └── transaction_card.dart
│       └── repository/
│           └── transaction_repository.dart
└── main.dart
```

---

## 🛠️ Hướng dẫn Chạy Ứng dụng

1. Đảm bảo bạn đã cài đặt Flutter SDK và thêm thư mục `bin` vào biến môi trường `PATH`.
2. Mở terminal tại thư mục dự án và tải các thư viện:
   ```bash
   flutter pub get
   ```
3. Chạy bộ kiểm thử Heuristic Parser:
   ```bash
   flutter test test/receipt_heuristic_parser_test.dart
   ```
4. Kết nối thiết bị Android hoặc khởi động máy ảo và chạy:
   ```bash
   flutter run
   ```
