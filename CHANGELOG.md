# Changelog

All notable changes to this project will be documented in this file.

## [1.8.1] - 2026-05-11

### Fixed

- **Google OAuth Login Flow** — Full rewrite of login pipeline
  - Masalah 1: Google blokir `inAppWebView` → ganti ke `LaunchMode.externalApplication` (Chrome Custom Tabs, tidak diblokir Google)
  - Masalah 2: `AuthProvider.initialize()` tidak di-await di main.dart → pindah ke splash_screen dengan `Future.wait`
  - Masalah 3: splash_screen baca state sebelum siap → `Future.wait` jalankan delay + initialize paralel
  - Masalah 4: login_screen tidak navigasi setelah sukses → `Navigator.pushReplacement` ke AppShell
  - AndroidManifest: tambah `android:autoVerify="true"` di deep link intent-filter
  - Redirect URI: `com.example.uangku://oauth` dengan deep link scheme

## [1.8.0] - 2026-05-11

### Added

- **SmartDbHelper** — Strategy pattern untuk auto-switch storage
  - PocketBase sebagai PRIMARY storage (jika reachable)
  - SQLite sebagai OFFLINE FALLBACK (jika tidak ada koneksi)
  - Write-through cache: data dari remote langsung disimpan ke SQLite
  - Periodic connectivity check setiap 30 detik
  - Auto-sync: queued operations dikirim ke PocketBase saat koneksi pulih
  - Stream<bool> connectivityStream untuk notify listeners

- **NgrokHttpClient** — Custom http.Client untuk PocketBase SDK v0.23.x
  - Inject header `ngrok-skip-browser-warning: true` di setiap request
  - PocketBase SDK menerima via `httpClientFactory` parameter
  - Tidak perlu `beforeSend` hook (tidak didukung di v0.23.x)

- **Connection Status Indicators**
  - SplashScreen: green/grey dot + "Tersambung ke server" / "Mode offline"
  - DashboardScreen: "☁ Online" indicator atau "📴 Offline" banner

### Changed

- **TransactionProvider** — Refactor total
  - Hapus `switchStorage()`, `setUseRemoteStorage()`, `_requiresOnline()`
  - Hapus manual queue logic (`_loadFromQueue`, `_parsePayload`, `_queueTransaction`)
  - Semua offline/online logic otomatis oleh SmartDbHelper
  - Listener ke `connectivityStream` dan `connectivity_plus`

- **BudgetProvider** — Migrasi ke DbInterface
  - Dari `SqliteHelper` → `SmartDbHelper` via `DbInterface`
  - Panggil `_dbHelper.initialize()` di method `initialize()`

- **SyncQueueHelper** — Fix serialization
  - `payload.toString()` → `jsonEncode(payload)` (proper JSON)
  - SmartDbHelper menggunakan `jsonDecode` saat replay

- **app_config.dart.example** — Default URL ke Ngrok tunnel

### Fixed

- PbClient tidak pernah mengirim `ngrok-skip-browser-warning` header
- TransactionProvider selalu default ke SqliteHelper (PocketBase tidak pernah dipakai)
- Payload serialization di SyncQueueHelper (Dart Map toString tidak bisa di-parse)
- BudgetProvider tidak ada DbInterface initialize

## [1.7.0] - 2026-04-27

### Added

- **BudgetProgressCard on Dashboard** - Menampilkan progress budget bulan ini
  - Top 3 kategori dengan spending tertinggi
  - Empty state dengan button "Atur Budget Bulanan"
  - Navigasi ke BudgetScreen via "Lihat Semua"
  - Progress bar: green (normal), orange (warning), red (over budget)
  - Menggunakan Consumer<BudgetProvider> untuk performa

- **PocketBase Connection Configuration**
  - PbClient singleton dengan env-based URL
  - Support Android Emulator (10.0.2.2:8090)
  - Support device fisik via --dart-define
  - Connection check sebelum sync
  - App tetap jalan offline jika PocketBase unreachable

- **Unit Tests** - 12 test cases untuk TransactionProvider
  - Balance calculations (totalBalance, monthlyIncome, monthlyExpense)
  - Category totals grouping
  - Monthly filtering
  - Income/expense filtering

- **Development Setup Section** di README.md
  - Cara run di Android Emulator
  - Cara run di device fisik
  -Cara run di WSL Ubuntu

### Changed

- **pb_import.json** - Update ke PocketBase v0.20+ format
  - Menggunakan `fields` (bukan `schema`)
  - Menambahkan field options (min, max, presentable, unique, dll)
  - 5 collections: transactions(8), categories(5), assets(7), debts(9), budgets(8)

- **Midtrans Security Fix**
  - Remove MIDTRANS_SERVER_KEY dari .env
  - Server key sekarang hanya di server (PocketBase hook)
  - Error messages dalam Bahasa Indonesia

- **Icon Generation Scripts** - Pindahkan ke folder scripts/
  - generate_icon.js → scripts/generate_icon.js
  - generate_icons.js → scripts/generate_icons.js
  - Update paths di package.json

- **Git Author Fix** - Semua commit sekarang ter-attribusi ke LunaeKim99

### Fixed

- Unused import di pb_helper.dart
- Analyzer issues (unused variables, prefer_final_fields)
- Budget provider initialization di main.dart

## [1.6.0] - 2026-04-26

### Changed

- **ReportScreen UI Revamp** - Modern minimalist design
  - AppBar: transparent, centerTitle, green share button
  - Month selector: pill container with dark mode
  - Summary cards: gradient + shadow, circular icon container
  - Section title: dark mode safe text color
  - Daily summary: removed (simplify)
  - Weekly & Monthly premium gate: green gradient container
  - Pie & Bar charts: wrapped in container with shadow

- **DashboardScreen Dark Mode Fix** - Card styling
  - Card Pemasukan: gradient green in light / AppTheme.darkCard in dark
  - Card Pengeluaran: gradient red in light / AppTheme.darkCard in dark
  - Saldo card: red gradient when balance < 0, green when >= 0
  - AI Recommendation: Container with dark mode support

- **Premium Pricing Update**
  - Bulanan: Rp 49.000/bulan
  - Tahunan: Rp 399.000/tahun

- **AI Chat Bubble Fix** - Text color for dark mode
  - Changed: `Colors.grey` → `Colors.grey[100]` for message bubble

### Fixed

- Month selector background in dark mode
- Pie chart container color in dark mode
- Bar chart bottomTitles showTitles parameter

## [1.5.0] - 2026-04-25

### Changed

- **AddTransactionScreen UI Revamp** - Modern Minimal design
  - Layout baru: top section (nominal besar) + scrollable detail
  - Nominal besar di tengah seperti kalkulator (42px bold)
  - Type selector: pill toggle dengan shadow halus
  - Form rows: underline style (Material 3) - tidak ada outline box
  - Accent color: merah untuk pengeluaran, hijau untuk pemasukan
  - AnimatedContainer animate saat toggle tipe
  - AppBar transparan dengan delete button (edit mode)
  - Dark mode support

## [1.4.0] - 2026-04-25

### Added

- **Offline OCR Fallback** - Tesseract OCR untuk mode offline
  - Cek koneksi otomatis: online → ML Kit, offline → Tesseract
  - tessdata bahasa Indonesia & English
  - Auto retry ML Kit jika error ke Tesseract
  - Banner "Mode Offline" di receipt review

- **Bottom Navigation Redesign** - Navigation bar baru
  - 5 item: Beranda | Riwayat | [+] | Laporan | AI Chat
  - Tombol [+] hijau di tengah dengan gradient
  - Hapus semua FloatingActionButton
  - Dark mode support

- **App Icon Update** - Launcher icons baru
  - Background abu gelap (#263238)
  - Generate launcher icons dengan flutter_launcher_icons
  - iOS icons otomatis

- **Splash Screen Update** - Animasi splash screen
  - Gradient white (#FFFFFF) → light green (#E8F5E9)
  - Fade + scale animation untuk logo
  - LinearProgressIndicator loading
  - Fade transition ke AppShell

### Changed

- Standardisasi asset: hanya `assets/images/logo.png`
- Hapus duplicate logo files
- Update semua Image.asset references

- **Demo Build Config** - All premium features unlocked for testing
  - AppConfig.isDemoBuild flag
  - DEMO badge in AppBar
  - Premium gate bypass for testing

- **Import Data** - Import transaksi dari CSV/Excel
  - Parse CSV dan Excel (.xlsx)
  - Premium-only feature
  - Download template CSV
  - Preview hasil import (sukses/gagal)
  - Error handling per baris

- **AI Chat Fix** - Remove close button from AppBar

- **Export Save to Folder** - Pilihan simpan atau share file export
  - Bottom sheet dialog: Simpan ke Folder / Bagikan
  - Save to Folder via FilePicker
  - File命名为 UWANGKU_[filename]
  - iOS: langsung share tanpa dialog

- **Report Daily Summary** - Ringkasan transaksi hari ini (FREE)
  - Total pemasukan & pengeluaran hari ini
  - List transaksi hari ini (max 5 item)
  - Empty state message

- **Report Monthly AI Summary** - Analisis naratif bulanan (Premium)
  - AI-generated monthly analysis via Groq
  - Rebuild saat bulan berubah
  - Premium gate dengan upgrade button

## [1.3.0] - 2026-04-25

### Added

- **Usage Limit System** - Batas penggunaan fitur AI
  - FREE: 10x AI text & 2x scan struk/hari
  - PREMIUM: unlimited semua fitur
  - Reset harian otomatis

- **Receipt Scan Pro** - Scan struk/nota via OCR + AI
  - Google ML Kit text recognition
  - Groq Llama parsing untuk ekstrak item
  - Preview & edit sebelum simpan
  - Simpan sebagai 1 transaksi atau per item

- **AI Summary & Recommendation** - Fitur AI Premium
  - Ringkasan Mingguan naratif (7 hari)
  - Saran Budget Personal berdasarkan data
  - Groq Llama untuk analisis keuangan

- **Export Data** - Export Premium
  - PDF laporan keuangan per bulan
  - CSV data transaksi

- **Midtrans Payment** - Upgrade Premium
  - WebView payment via Midtrans Snap
  - Paket Bulanan (Rp 29.000) atau Tahunan (Rp 99.000/tahun)
  - Integration dengan UsageProvider

### Changed

- Badge status FREE/PREMIUM di dashboard AppBar
- Semua Premium gate navigasi ke UpgradeScreen

## [1.2.0] - 2026-04-25

### Changed

- **AI Chat Migration** - Switch dari Gemini ke Groq API
  - Ganti provider: Google Gemini → Groq API
  - Ganti model: llama-3.1-8b-instruct untuk rate limit lebih tinggi
  - Lebih stabil untuk usage tinggi
  - hapus .env dari git tracking

## [1.1.0] - 2026-04-24

### Added

- **Dark Mode** - Support tema gelap/terang
  - Toggle di AppBar dashboard
  - Simpan preferensi di SharedPreferences
  - Semua screen sudah dark mode aware

- **AI Chat Integration** - Catat transaksi via natural language
  - Gemini 2.5 Flash integration
  - Input teks natural: "makan siang 35rb", "gajian 5 juta"
  - Ekstrak otomatis: nominal, kategori, tipe (income/expense)
  - Konfirmasi sebelum simpan

- **Voice Input** - Catat transaksi via suara
  - Speech-to-text dengan speech_to_text package
  - Auto-detect locale Indonesia dengan fallback
  - Tekan lama tombol mic untuk merekam

- **OCR Scan** - Scan struk/nota via kamera
  - Google ML Kit text recognition
  - Ambil dari kamera atau galeri
  - Tampilkan preview gambar di chat
  - AI ekstrak transaksi dari teks hasil OCR

### Changed

- All screens updated with dark mode support
- TransactionCard now uses Theme.of(context).brightness

## [1.0.0] - 2026-04-23

### Added

- **Edit Transaksi** - User bisa edit transaksi yang sudah tersimpan
  - Navigasi dari Dashboard atau History screen
  - Android: tap item atau icon edit
  - iOS: tap item atau long press (CupertinoContextMenu)

- **UI Polish** - Tampilan lebih premium
  - TransactionCard: left accent border, edit icon di bawah nominal (tidak overlap)
  - HistoryScreen: group by date, swipe delete style, stats header
  - DashboardScreen: FAB solid green, saldo card bulan ini, empty state upgrade
  - AddTransactionScreen: pill toggle dengan checkmark, format angka otomatis
  - ReportScreen: section title dengan accent bar hijau

### Changed

- **Storage** - Default SQLite (offline mode)
  - Belum ada backend server, jadi SQLite dulu

## [0.2.0] - 2026-04-XX

### Added

- **SQLite Local Storage** dengan DbInterface abstraction layer
- **PocketBase Integration** (optional for online mode)

### Fixed

- PocketBase URL per platform
- Date formatting Indonesian localization

## [0.1.0] - 2026-04-XX

### Added

- Initial release
- Dashboard dengan saldo & ringkasan bulan ini
- Tambah transaksi (pemasukan/pengeluaran)
- Riwayat transaksi dengan filter (Semua/Pemasukan/Pengeluaran)
- Laporan: pie chart pengeluaran per kategori, bar chart 6 bulan
- Cross-platform UI (Android Material & iOS Cupertino)
- SQLite local storage