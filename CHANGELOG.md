# Changelog

All notable changes to this project will be documented in this file.

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