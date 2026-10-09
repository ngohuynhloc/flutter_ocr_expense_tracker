# MINI-PROJECT SHORT TECHNICAL REPORT
**Course:** Cross-Platform Mobile App Development (VKU)  
**Mini-Project Title:** Mini-Project 3: OCR Expense Tracker & Receipt Parser (Flutter & Dart)  
**Team / Student Name:** [Team Name or Student Name]  
**Submission Date:** [DD/MM/YYYY]  

---

## 1. GENERAL INFORMATION & DELIVERABLE LINKS
* **Team Members:**
  1. [Student Full Name] — Student ID: [22ITxxx] — Role: [Team Lead / Frontend & Vision AI] — Contribution: [50%]
  2. [Student Full Name] — Student ID: [22ITyyy] — Role: [Member / Database & CustomPainter Charts] — Contribution: [50%]
* **🔗 Live Demo / APK Download:** [Insert APK Link or Google Drive Link]
* **💻 GitHub Repository:** https://github.com/ngohuynhloc/flutter_ocr_expense_tracker.git
* **🎥 Video Demo (Optional):** [Insert YouTube / Drive Link]

---

## 2. FEATURE IMPLEMENTATION CHECKLIST

| # | Required Feature | Status | Implementation Details & Acceptance Level |
|:---:|---|:---:|---|
| **1** | **Camera Viewfinder & Image Cropper** | ✅ Complete | • 3:4 aspect ratio receipt viewfinder with custom corner guides (`CameraOverlayPainter`).<br>• Flash toggle (`torch`/`off`), tap-to-focus animation (`setFocusPoint`).<br>• Integrated `image_cropper` for edge refinement and local persistent storage in app Documents. |
| **2** | **On-Device OCR & Regex Heuristics** | ✅ Complete | • 100% offline OCR powered by `google_mlkit_text_recognition` (<100ms latency).<br>• Smart heuristic parser (`ReceiptHeuristicParser`): brand detection (WinMart, Highlands, Circle K, etc.), header noise filtering, Vietnamese currency regex (`150.000 đ`, `150k`), transaction date parsing, and category auto-prediction.<br>• Full pre-save review screen (`ReceiptReviewScreen`). |
| **3** | **Local SQLite Database & Full CRUD** | ✅ Complete | • SQLite management via `sqflite` with B-Tree indexes on `transaction_date` and `category`.<br>• Full CRUD: Add manually, Edit dialog, Swipe-to-delete with Undo SnackBar, and category filter chips. |
| **4** | **Zero-Dependency Canvas Charts (`CustomPainter`)** | ✅ Complete | • **Animated Donut Chart**: Smooth sweep animation, touch-to-expand segment with center percentage inspection.<br>• **Weekly Spending Bar Chart**: 7-day visualization (Mon-Sun), dashed reference gridlines, coordinate labels, and interactive tooltips. |
| **5** | **Multi-Period & Week Navigation Filtering** | ✅ Complete | • Multi-period filter (`TimePeriodFilter`: All-time, This Week, This Month, Last Month) across list & analytics.<br>• Week-by-week navigation buttons (`<` `>`) with automatic range calculation (`dd/MM - dd/MM/yyyy`). |
| **6** | **Unit Testing & Heuristic Verification** | ✅ Complete | • Comprehensive unit test suite (`test/receipt_heuristic_parser_test.dart`) covering real Vietnamese invoices (WinMart, Highlands, Petrolimex, Fahasa, FPT Shop) with 100% pass rate. |

---

## 3. TECHNICAL ARCHITECTURE & PROJECT STRUCTURE

### 📂 Directory Structure (Feature-First Clean Architecture)
```
lib/
├── core/
│   ├── database/
│   │   └── database_helper.dart             # SQLite singleton, schema definition & index creation
│   ├── theme/
│   │   └── app_theme.dart                   # Material 3 design tokens & curated color palette
│   └── utils/
│       ├── currency_formatter.dart          # Vietnamese Dong (VNĐ) formatting
│       └── date_formatter.dart              # Smart date & week-range formatting
├── features/
│   ├── analytics/                           # Custom Canvas Visualizations
│   │   ├── presentation/
│   │   │   └── analytics_dashboard_screen.dart
│   │   └── widgets/
│   │       ├── animated_donut_chart.dart    # Interactive touch donut chart
│   │       ├── donut_chart_painter.dart     # Canvas math painter for slices
│   │       ├── weekly_bar_chart_painter.dart# Canvas bar & gridline painter
│   │       └── weekly_spending_bar_chart.dart # Interactive weekly bar chart with week navigation
│   ├── receipt_scan/                        # Camera, OCR & Heuristic Engine
│   │   ├── models/
│   │   │   └── parsed_receipt_result.dart   # Data transfer object for parsed receipts
│   │   ├── presentation/
│   │   │   ├── camera_scanner_screen.dart   # Viewfinder, flash, autofocus & gallery fallback
│   │   │   └── receipt_review_screen.dart   # Interactive edit & confirm screen
│   │   ├── services/
│   │   │   ├── image_cropper_service.dart   # Aspect ratio cropping service
│   │   │   ├── image_storage_service.dart   # Persistent image file management
│   │   │   ├── mlkit_text_recognizer_service.dart # Google ML Kit On-Device OCR wrapper
│   │   │   └── receipt_heuristic_parser.dart # Rule-based regex heuristic engine
│   │   └── widgets/
│   │       ├── camera_overlay_painter.dart  # 3:4 viewfinder mask & guide corners
│   │       └── focus_indicator.dart         # Animated pulse focus indicator
│   └── transactions/                        # Core Expense Management & CRUD
│       ├── controllers/
│       │   └── transaction_controller.dart  # ChangeNotifier state controller
│       ├── models/
│       │   ├── expense_category.dart        # Enum categories with custom icons & colors
│       │   ├── time_period_filter.dart      # Enum for time-range filtering
│       │   └── transaction_model.dart       # Immutable transaction domain model
│       ├── presentation/
│       │   ├── transaction_list_screen.dart # Main dashboard & swipe-to-delete list
│       │   └── widgets/
│       │       ├── add_edit_transaction_dialog.dart # Modal dialog for manual CRUD
│       │       └── transaction_card.dart    # Dismissible transaction card
│       └── repository/
│           └── transaction_repository.dart  # SQLite data access object (DAO)
└── main.dart                                # Application root & dependency wiring
```

### 🔄 State Management & Data Flow Architecture
* **State Management:** Utilizes Flutter's built-in `ChangeNotifier` (`TransactionController`) combined with `ListenableBuilder` / reactive listeners to ensure high performance, separation of concerns, and zero third-party boilerplate.
* **Repository Pattern:** `ITransactionRepository` encapsulates SQLite operations (`DatabaseHelper`), decoupling UI logic from data persistence.
* **Offline-First & Graceful Fallback:** ML Kit runs fully on-device without cloud API dependencies. Camera view provides automatic gallery selection fallback on emulators or permission denial.

---

## 4. EMPIRICAL EVIDENCE & SCREENSHOTS

| **1. Camera Scanner & Viewfinder** | **2. Receipt Review & OCR Parser** |
|:---:|:---:|
| ![Camera Scanner](screenshots/camera_scanner.png)<br>*(Khung ngắm tỉ lệ 3:4, bật/tắt flash & chạm lấy nét)* | ![Receipt Review](screenshots/receipt_review.png)<br>*(Bóc tách tự động: Tên quán, Tổng tiền, Ngày & Danh mục)* |

| **3. Transaction List & CRUD** | **4. Canvas Analytics Dashboard** |
|:---:|:---:|
| ![Transaction List](screenshots/transaction_list.png)<br>*(Danh sách chi tiêu, lọc đa mốc thời gian & vuốt xoá)* | ![Analytics Dashboard](screenshots/analytics_dashboard.png)<br>*(Biểu đồ Donut & Biểu đồ cột chuyển tuần tự vẽ Canvas)* |

---

## 5. TECHNICAL CHALLENGES & RESOLUTIONS

### 🔴 Challenge 1: Noise Filtering & Multi-Format Amount Extraction in Vietnamese Receipts
* **Problem:** Vietnamese receipts contain high visual noise (MST, VAT, phone numbers, cashiers) and various currency representations (`150.000 đ`, `150,000 VND`, `150k`, or multiple sub-totals/discounts).
* **Resolution:** Implemented a multi-tier heuristic engine in `ReceiptHeuristicParser`:
  1. *Merchant Matching:* Scans the top 8 lines against a curated dictionary of Vietnamese retail brands while ignoring noise keywords (`hóa đơn`, `mst`, `tel:`).
  2. *Amount Identification:* Prioritizes lines matching payment keywords (`tổng cộng`, `thanh toán`, `tiền mặt`), falls back to regex matching currency suffixes (`đ`, `vnd`), and filters out invalid numbers (years `2020-2035`, phone numbers).
  3. *Unit Testing:* Verified against 5 standard test suites with 100% assertions passing.

### 🔴 Challenge 2: Cross-Drive Incremental Build Conflicts & Android v2 Embedding Migration
* **Problem:** Developing on a multi-drive Windows setup (`E:\Da_Nen_Tang` vs `C:\Users\...`) caused Kotlin's incremental compiler to throw `IllegalArgumentException: this and base files have different roots`. Additionally, older plugin versions (`image_cropper: 5.0.1`) failed on modern Flutter 3.x due to deprecated `PluginRegistry.Registrar` v1 embedding classes.
* **Resolution:** 
  1. Upgraded `image_cropper` to `^8.0.0` and `camera` to `^0.11.0` to ensure strict compliance with Flutter v2 embedding.
  2. Added `kotlin.incremental=false` and `kotlin.incremental.useClasspathSnapshot=false` in `android/gradle.properties`.
  3. Configured `packaging { jniLibs { keepDebugSymbols.add("**/*.so") } }` in `android/app/build.gradle.kts` to resolve NDK `llvm-strip` missing symbol errors, achieving 100% clean APK compilation.

### 🔴 Challenge 3: Interactive Touch Math on Zero-Dependency CustomPainter Charts
* **Problem:** Developing interactive charts (zooming into donut segments, rendering column-specific tooltips) without third-party chart packages required manual coordinate mapping and canvas hit-testing.
* **Resolution:** 
  1. *Donut Chart:* Calculated touch angle and distance from center using `math.atan2(dy, dx)` and Euclidean distance $\sqrt{dx^2 + dy^2}$ to determine exactly which angular slice was tapped, animating the radius expansion smoothly via `CurvedAnimation`.
  2. *Weekly Bar Chart:* Divided chart canvas dynamically based on horizontal slot width $(W - \text{padding}) / 7$ and rendered custom dashed gridlines and formatted VNĐ value labels with zero frame drops.
