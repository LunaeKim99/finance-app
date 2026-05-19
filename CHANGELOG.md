# Changelog

All notable changes to this project will be documented in this file.

## [2.6.0] - 2026-05-19

### Added

- **Live Exchange Rates** — Fetch otomatis dari `open.er-api.com` (gratis, tanpa API key)
  - `ExchangeRateService` singleton: fetch → cache SharedPreferences → refresh tiap 30 menit
  - Inisialisasi di SplashScreen, fallback ke hardcoded rates jika offline
  - `CurrencyHelper.convert()` & `format()` otomatis pakai live rate

- **Hybrid Categories** — Seed 22 kategori default + user tetap bisa kustom
  - `DefaultCategories` — 16 expense + 6 income kategori umum (Makanan, Transport, Gaji, dll)
  - `CategoryBloc` auto-seed saat `CategoryLoadRequested` pertama (flag `categories_seeded_v1` di SharedPreferences)
  - Kategori lama (sebelum update) tidak terpengaruh

- **Visual Icon Picker** — Pilih ikon kategori via grid, bukan teks manual
  - `CategoryIconRegistry` — 70+ Material Icons mapping string → `IconData`
  - Bottom sheet `DraggableScrollableSheet` dengan grid 6 kolom
  - Preview ikon di dialog add/edit kategori

### Changed

- `lib/presentation/screens/categories/category_screen.dart` — `TextField` ikon diganti `InkWell` + icon picker bottom sheet
- `lib/presentation/blocs/category/category_bloc.dart` — auto-seed default categories

### Added Files

- `lib/core/services/exchange_rate_service.dart`
- `lib/core/constants/icon_registry.dart`
- `lib/core/constants/default_categories.dart`

## [2.5.0] - 2026-05-19

### Added

- **Provider → BLoC Migration (complete)** — All 6 state managers migrated to `flutter_bloc`
  - `AuthBloc` (existing), `SettingsBloc` (existing), `TransactionBloc` (enhanced), `BudgetBloc` (enhanced), `UsageBloc` (new), `CategoryBloc` (new)
  - All consumer screens updated to use `context.read<>()`/`context.watch<>()`/`BlocBuilder`
  - Computed properties on `TransactionLoaded`: `totalBalance`, `monthlyIncome`, `monthlyExpense`, `getCategoryTotals`, `getRecentTransactions`
  - Computed helpers on `BudgetLoaded`: `getBudgetForCategory`, `getBudgetsForMonth`, `getBudgetUsagePercent`, `isOverBudget`, `isWarningBudget`, `getBudgetSummary`
  - `SyncService` now injects `TransactionBloc` instead of `TransactionProvider`
  - `TransactionMarkSynced` event for sync queue processing
  - `app.dart` uses `MultiBlocProvider` with 6 BLoCs — zero `Provider`/`MultiProvider` imports
  - Removed `TransactionProvider`, `BudgetProvider`, `UsageProvider`, `ThemeProvider`, `AuthProvider` source files

- **Multi-Currency Support** — Setiap transaksi/aset/utang/budget bisa dalam mata uang berbeda
  - Domain entities: `currency` (default `'IDR'`) + `exchangeRateToIdr` (default `1.0`)
  - Field di Transaction, Budget (domain + model), Asset, Debt entity baru
  - `Asset` dan `Debt` domain entities resmi dibuat
  - SQLite schema v3: kolom `currency` + `exchange_rate_to_idr` di transactions, debts, budgets
  - Migration v1→v2→v3 via `ALTER TABLE` di `_upgradeTables`
  - `AppCurrencies`: 10 mata uang (IDR, USD, EUR, SGD, MYR, JPY, GBP, AUD, SAR, CNY) + default rates
  - `CurrencyHelper.format/convert` — format locale-aware + konversi antar mata uang
  - Currency selector di `AddTransactionScreen` (bottom sheet Android / CupertinoPicker iOS)
  - Dynamic currency symbol di field nominal (tidak hardcoded `Rp`)

- **Category Management** — CRUD kategori kustom
  - `Category` domain entity + `CategoryModel` data model
  - `CategoryRepository` + `CategoryRepositoryImpl`
  - SQLite: tabel `categories` + CRUD di SqliteHelper
  - PocketBase: CRUD via `categories` collection di PbHelper
  - SmartDbHelper: write-through cache + sync queue + routing
  - `CategoryBloc` (event/state/bloc) teregister di `MultiBlocProvider`
  - `CategoryScreen` — add/edit/delete kategori dengan ikon Material, grouped by type
  - Menu "Kelola Kategori" di SettingsScreen

- **AI Chat Custom Categories** — System prompt dinamis
  - `_buildSystemPrompt(expenseCats, incomeCats)` — kategorinya diambil dari database
  - `sendMessage()` fetch kategori user sebelum build prompt
  - AI sekarang tahu kategori kustom user, bukan cuma default

### Changed

- **AddTransactionScreen** — Load kategori dari `CategoryBloc` bukan hardcoded list
  - `initState()` dispatch `CategoryLoadRequested`
  - Toggle tipe transaksi sync kategori via `_syncCategoriesFromBloc()`
- **SqliteHelper** — db version 3 dengan migrasi kumulatif
- **SmartDbHelper** — imports diperbaiki (PbClient + ConflictAlgorithm)
- **MockDbHelper** — ditambah category CRUD methods

### New Files

- `lib/core/constants/currencies.dart` — AppCurrencies constants
- `lib/core/utils/currency_helper.dart` — CurrencyHelper format/convert
- `lib/domain/entities/asset.dart` — Asset entity
- `lib/domain/entities/debt.dart` — Debt entity
- `lib/domain/entities/category.dart` — Category entity
- `lib/domain/repositories/category_repository.dart` — abstract repo
- `lib/data/models/category_model.dart` — data model
- `lib/data/repositories/category_repository_impl.dart` — impl
- `lib/presentation/blocs/category/` — CategoryBloc (event/state/bloc)
- `lib/presentation/screens/categories/category_screen.dart` — management screen

## InDev [2.4.0] - 2026-05-19

### Added

- **Error Boundary** — Global error handler di root app
  - `ErrorBoundary` StatefulWidget bungkus `FinanceApp`
  - Tangkap `FlutterError.onError` + `PlatformDispatcher.instance.onError`
  - Custom fallback UI dengan pesan user-friendly + tombol "Coba Lagi"
  - Detail error di mode debug (tap "Detail Error")

- **Halaman Pengaturan (Settings)** — Container untuk semua konfigurasi aplikasi
  - Menu: Akun, Tampilan (Dark Mode), Mata Uang, Notifikasi, Data (Ekspor/Impor), Premium, Tentang
  - Icon gear di AppBar dashboard → navigasi ke SettingsScreen
  - `SettingsBloc` (BlocProvider) + `SettingsRepositoryImpl` (SharedPreferences)

- **Account Deletion** — Hapus akun dan seluruh data (wajib Google Play)
  - Double confirmation: dialog #1 peringatan + dialog #2 ketik "HAPUS"
  - Hapus semua data dari PocketBase (transactions, assets, debts, budgets)
  - Hapus user dari PocketBase
  - Clear SQLite lokal + Sync Queue + SharedPreferences
  - Flow: `AuthBloc` → `DeleteAccount` use case → `AuthRepositoryImpl.deleteAccount()`
  - `dropAllData()` di SqliteHelper, `clearAll()` di SyncQueueHelper

- **Profil User & Ganti Password**
  - ProfileScreen: nama (edit), email (readonly), avatar inisial
  - Form ganti password dengan validasi konfirmasi
  - Update profil via PocketBase `users.update(id, body: {'name': name})`
  - Ganti password via PocketBase `users.update(id, body: {'oldPassword', 'password', 'passwordConfirm'})`

- **Clean Architecture BLoC Refactor (Auth)**
  - `AuthBloc` sekarang inject `AuthRepository` (dependency injection)
  - `AuthState` menggunakan `UserProfile` entity (tanpa RecordModel dari PocketBase)
  - Event baru: `AuthDeleteAccountRequested`, `AuthUpdateProfileRequested`, `AuthChangePasswordRequested`
  - State baru: `AuthActionSuccess` untuk feedback non-navigasi
  - Use cases: `SignInWithEmail`, `DeleteAccount`, `ChangePassword`, `UpdateProfile`, `GetCurrentUser`

### Changed

- **app.dart** — Migrasi dari single `BlocProvider` ke `MultiBlocProvider`
  - `AuthBloc` dengan `AuthRepositoryImpl` injection
  - `SettingsBloc` dengan `SettingsRepositoryImpl` injection
- **main.dart** — Bungkus `FinanceApp` dengan `ErrorBoundary`
- **AuthRepository domain** — Tambah method: `signInWithEmail`, `getCurrentUser`, `updateProfile`, `changePassword`, `deleteAccount`, `userId`

## InDev [2.3.1] - 2026-05-19

### Changed

- **Google OAuth Redirect** — Ganti dari custom scheme ke loopback redirect
  - Tidak lagi pakai `com.example.uangku://oauth/callback` (Google tolak custom scheme)
  - App jalanin HTTP server di `127.0.0.1:8765` via dart:io `HttpServer`
  - Google redirect ke local server → app extract `code` → `authWithOAuth2Code`
  - Halaman sukses auto-redirect ke custom scheme untuk balik ke app

- **Logout Navigation** — Tambah `appNavigatorKey` global untuk navigasi dari luar MaterialApp
  - `BlocListener` di `app.dart` sekarang pake `appNavigatorKey.currentState?.pushNamedAndRemoveUntil` untuk logout

- **Data Reload After Login** — `AppShell.didChangeDependencies` reload data transaksi & budget

### Added

- **LocalOAuthServer** — Service HTTP server loopback untuk tangkap redirect OAuth
- **Pending Redirect Buffer** — `OAuthHandler._pendingRedirect` untuk cold start scenario

## InDev [2.3.0] - 2026-05-18

### Added

- **User-PocketBase Relation** — Semua data sekarang terikat ke user PocketBase
  - `user` field di model: TransactionModel, AssetModel, DebtModel, BudgetModel
  - PbHelper auto-inject `userId` saat create dan filter `user = @request.auth.id` saat fetch
  - `pb_schema.json`: relasi `user` + cascadeDelete + locked rules (`listRule`, `createRule`, `updateRule`, `deleteRule`)
  - 4 collections: transactions, assets, debts, budgets

- **Datasource Layer per Fitur** — 6 thin wrapper datasource files
  - `transaction/data/transaction_datasource.dart`
  - `budget/data/budget_datasource.dart`
  - `dashboard/data/dashboard_datasource.dart`
  - `receipt/data/receipt_datasource.dart`
  - `report/data/report_datasource.dart`
  - `export_import/data/export_datasource.dart`

- **3 BLoC Baru** — export_import, receipt, report
  - Masing-masing dengan event, state, dan bloc file
  - ExportImportBloc: load, export PDF/Excel
  - ReceiptBloc: save receipt scan sebagai transaksi
  - ReportBloc: load laporan dengan aggregasi income/expense/category

### Changed

- **AI Chat Refactor** — Full migration dari Provider ke BLoC
  - `ChatMessage` class pindah dari `ai_chat_screen.dart` ke `ai_chat_state.dart`
  - `ai_chat_screen.dart` sekarang hanya render UI + dispatch events
  - Semua service logic (AiService, VoiceService, OcrService) di BLoC
  - `AiChatBloc` diprovide via `BlocProvider` di `app_shell.dart`
  - `TransactionBloc` & `BudgetBloc` — Kini menggunakan local datasource (TransactionDatasource, BudgetDatasource) bukan SmartDbHelper langsung

### Fixed

- **AuthLoginRequested Handler** — Tambah handler `_onLoginRequested` di AuthBloc untuk login email/password via `authWithPassword`, termasuk error categorization (invalid credentials, network, timeout)
- **Login Screen Email/Password** — login_screen.dart sekarang punya form email + password di samping Google login, dispatch `AuthLoginRequested` event
- **BLoC Constructor Pattern** — ExportImportBloc, ReceiptBloc, ReportBloc, TransactionBloc, BudgetBloc pakai optional datasource injection `{DatasourceType? datasource}` untuk fleksibilitas testing

### Version Scheme

- **Naming Scheme** — Semua versi sekarang pakai prefix `InDev`

## InDev [2.2.0] - 2026-05-18

### Added

- **Fitur Logout** — Tombol keluar di Dashboard dengan konfirmasi dialog
  - `AuthBloc`, `AuthEvent`, `AuthState` — BLoC untuk autentikasi (login Google + logout)
  - `AuthLogoutRequested` → clear auth store + SharedPreferences
  - `BlocListener` di `app.dart` navigasi ke `/login` saat logout
  - Login & Splash screen migrasi dari `AuthProvider` ke `AuthBloc`

- **BLoC Pattern per Fitur** — Setiap fitur sekarang punya BLoC sendiri
  - `auth/bloc/` — autentikasi (login, logout, check status)
  - `transaction/bloc/` — CRUD transaksi via `SmartDbHelper`
  - `budget/bloc/` — CRUD budget via `SmartDbHelper`
  - `ai_chat/bloc/` — AI chat dengan finance-only filter
  - `dashboard/bloc/` — state dashboard
  - `upgrade/bloc/` — proses pembayaran Premium
  - Subfolder `widgets/` dan `bloc/` di setiap folder fitur (9 fitur)

- **Collection `midtrans_logs`** — Log transaksi Midtrans di PocketBase
  - Schema: order_id, transaction_id, status, payment_type, gross_amount, currency, user_id, raw_payload
  - Tersimpan otomatis saat pembayaran sukses/pending/failed

- **Premium Transaction otomatis** — Pembayaran Premium tercatat di `transactions`
  - Record baru dibuat dengan title "Pembayaran Premium - [paket]", type expense, kategori "Premium / Subscription"

### Changed

- **Dependencies** — Tambah `flutter_bloc` ^8.1.6 dan `equatable` ^2.0.7
- **PaymentWebviewScreen** — Refactor untuk simpan midtrans_logs + transaction record
- **UpgradeScreen** — Kirim `planName` ke PaymentWebviewScreen

## InDev [2.1.0] - 2026-05-18

### Added

- **AI Topic Boundary** — Filter percakapan AI hanya seputar keuangan
  - System prompt diperketat dengan daftar topik yang diizinkan dan dilarang
  - `_isFinanceRelated()` pre-filter dengan keyword detection
  - Off-topic langsung direspon dengan pesan standar tanpa diproses AI
  - Prompt ringkasan mingguan, bulanan, dan saran budget juga diperketat

### Changed

- **Midtrans Error Handling** — Pesan error lebih informatif dalam Bahasa Indonesia
  - Specific `ClientException` handling untuk kode 401, 403, 500, 502
  - Deteksi `SocketException` dan `HandshakeException` untuk error jaringan
  - Throw ulang exception yang tidak tertangani (`rethrow`)

- **PocketBase di .gitignore** — Seluruh folder `pocketbase/` tidak dilacak git

### Removed

- **pb_hooks/create_snap_token.pb.js** — File hook yang tidak terpakai dihapus

## InDev [2.0.1] - 2026-05-11

### Fixed

- **Auth Token Persistence** — Token login tidak hilang setelah app ditutup
  - Migrasi dari `AuthStore` (in-memory) ke `AsyncAuthStore` + `SharedPreferences`
  - `PbClient` sekarang punya `init()` yang dipanggil di `main.dart` sebelum `PbHelper`
  - User cukup login sekali, token bertahan sampai app data dihapus

- **Payment Environment Mismatch** — Gagal bayar karena Snap URL sandbox vs production tidak konsisten
  - `getSnapUrl()` sekarang pake `AppConfig.isProduction` (dari server), bukan cek URL PocketBase
  - Midtrans hook: tambah `finish_redirect_url` agar WebView bisa deteksi status pembayaran
  - Customer name/email sekarang pake data real dari `AuthProvider` (tidak hardcoded)

- **OAuth Redirect Back to App** — Browser tidak balik ke app setelah login Google
  - Setelah realtime OAuth selesai, `launchUrl` custom scheme `com.example.uangku://oauth/callback` dipanggil
  - Browser otomatis redirect balik ke aplikasi lewat intent-filter

### Changed

- **Harga Premium Tahunan** — Rp 399.000 → Rp 249.000

## InDev [2.0.0] - 2026-05-11

### Changed

- **Clean Architecture Refactor** — Restrukturasi total dari struktur flat ke Clean Architecture
  - `main.dart` dipisah menjadi 3 file: `main.dart` (bootstrap), `app/app.dart` (FinanceApp), `app/app_shell.dart` (AppShell)
  - Layer baru: `domain/` — entities, abstract repository interfaces, use cases
  - Layer baru: `core/` — config, constants, error handler, theme, utils
  - `data/` layer — models, datasources (local + remote), repository implementations
  - `presentation/` — providers, screens (organized per fitur), widgets (organized per fitur)
  - Layer dependency rule: `presentation → domain ← data`, `core` berdiri sendiri
  - Barrel exports (`index.dart`) di setiap folder untuk import yang lebih rapi
  - ThemeData dipisah dari `main.dart` ke `core/theme/app_theme.dart`
  - Semua import paths diupdate, 0 error flutter analyze
  - Tidak ada perubahan fungsionalitas — murni refactor struktur

## InDev [1.8.1] - 2026-05-11

### Fixed

- **Google OAuth Login Flow** — Full rewrite of login pipeline
  - Masalah 1: Google blokir `inAppWebView` → ganti ke `LaunchMode.externalApplication` (Chrome Custom Tabs, tidak diblokir Google)
  - Masalah 2: `AuthProvider.initialize()` tidak di-await di main.dart → pindah ke splash_screen dengan `Future.wait`
  - Masalah 3: splash_screen baca state sebelum siap → `Future.wait` jalankan delay + initialize paralel
  - Masalah 4: login_screen tidak navigasi setelah sukses → `Navigator.pushReplacement` ke AppShell
  - AndroidManifest: tambah `android:autoVerify="true"` di deep link intent-filter
  - Redirect URI: `com.example.uangku://oauth` dengan deep link scheme

## InDev [1.8.0] - 2026-05-11

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

## InDev [1.7.0] - 2026-04-27

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

## InDev [1.6.0] - 2026-04-26

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

## InDev [1.5.0] - 2026-04-25

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

## InDev [1.4.0] - 2026-04-25

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

## InDev [1.3.0] - 2026-04-25

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

## InDev [1.2.0] - 2026-04-25

### Changed

- **AI Chat Migration** - Switch dari Gemini ke Groq API
  - Ganti provider: Google Gemini → Groq API
  - Ganti model: llama-3.1-8b-instruct untuk rate limit lebih tinggi
  - Lebih stabil untuk usage tinggi
  - hapus .env dari git tracking

## InDev [1.1.0] - 2026-04-24

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

## InDev [1.0.0] - 2026-04-23

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

## InDev [0.2.0] - 2026-04-XX

### Added

- **SQLite Local Storage** dengan DbInterface abstraction layer
- **PocketBase Integration** (optional for online mode)

### Fixed

- PocketBase URL per platform
- Date formatting Indonesian localization

## InDev [0.1.0] - 2026-04-XX

### Added

- Initial release
- Dashboard dengan saldo & ringkasan bulan ini
- Tambah transaksi (pemasukan/pengeluaran)
- Riwayat transaksi dengan filter (Semua/Pemasukan/Pengeluaran)
- Laporan: pie chart pengeluaran per kategori, bar chart 6 bulan
- Cross-platform UI (Android Material & iOS Cupertino)
- SQLite local storage