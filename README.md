# UWANGKU InDev v2.3.0

Aplikasi Asisten Keuangan Pribadi Berbasis AI menggunakan Flutter dengan dukungan penuh untuk Android dan iOS.

## Fitur

- **Dashboard** - Menampilkan saldo total, pemasukan & pengeluaran bulan ini
- **Tambah Transaksi** - Input transaksi dengan kategori, nominal, tanggal, dan catatan
- **Riwayat** - Lihat semua transaksi dengan filter (Semua/Pemasukan/Pengeluaran)
- **Laporan** - Pie chart pengeluaran per kategori, bar chart 6 bulan terakhir, ringkasan harian
- **Dark Mode** - Support tema gelap/terang dengan toggle di dashboard
- **AI Chat** - Catat transaksi via chat natural language (Groq Llama 3.1)
- **Voice Input** - Catat transaksi via suara (speech-to-text)
- **OCR Scan** - Scan struk/nota via kamera (ML Kit text recognition)
  - **Offline Mode**: Tesseract OCR fallback jika tidak ada internet
  - Auto-detect koneksi → ML Kit (online) atau Tesseract (offline)
- **Cross-Platform** - Tampilan native untuk Android (Material) dan iOS (Cupertino)
- **Splash Screen** - Gradient animasi dengan logo UWANGKU + connection status
- **Google OAuth** - Login dengan Google, redirect balik ke app via custom scheme `com.example.uangku://oauth`
- **Dual Storage** - PocketBase sebagai PRIMARY, SQLite sebagai OFFLINE FALLBACK
  - Auto-switch: SmartDbHelper otomatis pilih storage berdasarkan koneksi
  - Write-through cache: data online otomatis disimpan lokal
  - Auto-sync: data offline otomatis dikirim ke server saat koneksi pulih
- **Auth Persistence** - Login sekali, token tersimpan di device (AsyncAuthStore + SharedPreferences)
- **Premium** - Unlimited AI, Export PDF/CSV (via Midtrans)

## Fitur Premium

- **AI Input Tanpa Batas** - Unlimited chat dengan AI
- **Scan Struk Tanpa Batas** - Unlimited scan nota/struk
- **Ringkasan Mingguan** - Analisis keuangan naratif via AI
- **Saran Budget Personal** - Rekomendasi keuangan berdasarkan data
- **Export PDF & CSV** - Download laporan keuangan (Save ke Folder atau Share)
- **Import Data** - Import transaksi dari CSV/Excel
- **Ringkasan Bulanan AI** - Analisis keuangan naratif bulanan via AI

### Upgrade Premium

- **Bulanan**: Rp 49.000/bulan
- **Tahunan**: Rp 249.000/tahun (hemat 58%)

Bayar via Midtrans Snap (WebView)

## Teknologi

- Flutter SDK ^3.11.4
- Clean Architecture (domain/data/presentation layers)
- Provider + BLoC (state management)
- SQLite + PocketBase (dual storage with SmartDbHelper auto-switch)
- fl_chart (charts)
- intl (formatting mata uang Indonesia)
- Groq API (Llama 3.1 8B)
- Google ML Kit Text Recognition (OCR)
- Flutter Speech to Text
- Midtrans Snap (payment)
- Flutter WebView

## Struktur Proyek (Clean Architecture)

```
lib/
├── main.dart                      # Bootstrap (runApp only)
├── app/
│   ├── app.dart                   # FinanceApp root widget
│   └── app_shell.dart             # AppShell + bottom nav
├── core/                          # Cross-cutting concerns
│   ├── config/app_config.dart
│   ├── constants/
│   ├── error/error_handler.dart
│   ├── theme/app_theme.dart
│   └── utils/platform_helper.dart
├── domain/                        # Pure business logic
│   ├── entities/                  # Transaction, Budget
│   ├── repositories/             # Abstract interfaces
│   └── usecases/                 # Auth, Transaction, Budget
├── data/                          # Implementation layer
│   ├── models/                    # Transaction, Budget, Asset, Debt, etc.
│   ├── datasources/
│   │   ├── local/sqlite_helper.dart
│   │   ├── remote/               # AI, OCR, Export, Midtrans, etc.
│   │   ├── db_interface.dart
│   │   ├── pb_helper.dart
│   │   ├── smart_db_helper.dart
│   │   └── sync_queue_helper.dart
│   └── repositories/             # Repository implementations
├── presentation/                  # Flutter UI layer
│   ├── providers/                 # Auth, Budget, Theme, Transaction, Usage
│   ├── screens/
│   │   ├── auth/                  # Login, Splash
│   │   ├── dashboard/
│   │   ├── transaction/           # Add, History
│   │   ├── budget/
│   │   ├── report/
│   │   ├── ai_chat/
│   │   ├── export_import/
│   │   ├── receipt/
│   │   └── upgrade/               # Upgrade, PaymentWebview
│   └── widgets/
│       ├── budget/
│       └── transaction/
└── services/
    └── pb_client.dart             # PocketBase client
```

## Storage Layer

App menggunakan **SmartDbHelper** — strategy pattern untuk auto-switch storage:

### Cara Kerja

1. **SmartDbHelper** mengecek koneksi PocketBase saat startup via `PbClient.isConnected()`
2. Setiap 30 detik, koneksi dicek ulang secara periodik
3. **Jika PocketBase reachable:**
   - Semua baca/tulis → PocketBase (remote primary)
   - Setiap sukses tulis → juga disimpan ke SQLite (write-through cache)
4. **Jika PocketBase unreachable:**
   - Semua baca/tulis → SQLite lokal
   - Operasi tulis di-queue ke SyncQueueHelper
5. **Saat koneksi pulih:**
   - Queue otomatis di-replay ke PocketBase
   - `connectivityStream` memberitahu UI untuk update

### Arsitektur

```
SmartDbHelper (implements DbInterface)
├── PocketBase (primary) — PbHelper
├── SQLite (fallback) — SqliteHelper
└── Sync Queue — SyncQueueHelper
```

### Diagram Alur

```
App Start → SmartDbHelper.initialize()
                ↓
        PbClient.isConnected()?
           ↙           ↘
        YES              NO
         ↓               ↓
  PocketBase           SQLite
  (primary)          (fallback)
         ↓               ↓
  Write-through      Queue ops →
  → SQLite cache     sync on reconnect
```

## Setup API Keys

API keys TIDAK lagi disimpan di file `.env` yang dibundle ke app. 
Ini untuk mencegah key terekspos di APK/IPA.

### Cara Setup (Build Time)

Gunakan `--dart-define` saat build atau run:

```bash
# Run (development)
flutter run --dart-define=GROQ_API_KEY=your_groq_key_here

# Build Android
flutter build apk --dart-define=GROQ_API_KEY=your_groq_key_here

# Build iOS
flutter build ios --dart-define=GROQ_API_KEY=your_groq_key_here
```

Untuk development lokal, bisa buat file `.env` (sudah di-gitignore):

```
GROQ_API_KEY=your_groq_key_here
```

###.env.example

Copy `.env.example` ke `.env` untuk development lokal:

```bash
cp .env.example .env
# Edit .env dengan key asli
```

## AI Chat Integration

Aplikasi menggunakan **Groq Llama 3.1 8B** untuk memproses input natural language:

1. **Dapatkan API Key:**
   - Buka: https://console.groq.com/keys
   - Login dengan Google/GitHub Account
   - Klik "Create API Key"
   - Copy key dan gunakan saat build/run (lihat section Setup API Keys)

2. **Cara Penggunaan:**
   - Tap tombol AI (icon robot) di FAB dashboard
   - Ceritakan transaksi secara natural, contoh:
     - "makan siang 35rb"
     - "gajian 5 juta"
     - "beli bensin 150rb"
   - AI akan ekstrak: nominal, kategori, tipe (income/expense)
   - Konfirmasi sebelum simpan

3. **Fitur:**
   - Natural language input (Indonesia/English)
   - OCR scan struk/nota
   - Voice input (tekan lama mic button)
   - Konfirmasi sebelum simpan

## Voice Input

1. Tekan lama (long press) tombol mic di input bar
2. Bicarafakan transaksi
3. Tekan tombol stop atau tunggu 3 detik hening
4. Teks otomatis terkirim

Mendukung bahasa Indonesia dengan auto-detect locale.

## OCR Scan

1. Tap tombol kamera di input bar
2. Pilih sumber: Kamera atau Galeri
3. Ambil foto struk/nota
4. AI akan ekstrak nominal dan kategori dari gambar

## Setup PocketBase

### 1. Download & Run PocketBase

```bash
# Download dari https://pocketbase.io/docs/
chmod +x pocketbase
./pocketbase serve
# Admin UI: http://127.0.0.1:8090/_/
```

### 2. Cara 1 — Auto Migration (Recommended)

```bash
# Copy folder pb_migrations/ ke direktori PocketBase
cp -r pb_migrations/ /path/to/pocketbase/
./pocketbase migrate up
```

### 3. Cara 2 — Import via Admin UI

1. Buka http://127.0.0.1:8090/_/
2. Settings → Import Collections
3. Upload file `pb_schema.json`
4. Klik "Confirm and import"

### 4. Update Flutter App

Edit file `.env` di root project Flutter:

```
PB_URL=http://127.0.0.1:8090
```

Ganti IP jika PocketBase di server/hosting berbeda.

### 5. Verify Setup

Buka: http://127.0.0.1:8090/_/
Pastikan collections `transactions` dan `categories` sudah muncul.

## ⚡ Quick Start

### 1. Setup VS Code Launch Config
```bash
# Copy template launch config
copy .vscode\launch.json.example .vscode\launch.json
```

Buka `.vscode/launch.json` dan sesuaikan:
- `192.168.1.100` → IP laptop kamu (`ipconfig` di Windows)
- `your-ngrok-url` → URL dari `ngrok http 8090`

### 2. Jalankan PocketBase
```bash
cd C:\laragon\pocketbase
.\pocketbase serve
```

### 3. Run App
- Tekan **F5** di VS Code, pilih konfigurasi yang sesuai
- Atau via terminal:
```bash
# Emulator (default)
flutter run --dart-define=PB_BASE_URL=http://10.0.2.2:8090

# Device fisik
flutter run --dart-define=PB_BASE_URL=http://192.168.x.x:8090

# Ngrok
flutter run --dart-define=PB_BASE_URL=https://xxxx.ngrok-free.dev
```

### 4. Cara Dapat GROQ API Key (Gratis)
1. Daftar di [console.groq.com](https://console.groq.com)
2. Klik **API Keys** → **Create API Key**
3. Copy key (format: `gsk_xxxxxxxxxxxx`)

## Development Setup

### Android Emulator (default)
```bash
flutter run
```

### Device Fisik
1. Cek IP laptop: `ipconfig` (Windows) → cari IPv4 di WiFi adapter
2. Run dengan:
```bash
flutter run --dart-define=PB_BASE_URL=http://192.168.1.xxx:8090
```

### WSL Ubuntu
1. Cek IP WSL: `ip addr show eth0 | grep "inet "`
2. Setup port forwarding di PowerShell (Admin):
```powershell
netsh interface portproxy add v4tov4 listenport=8090 listenaddress=0.0.0.0 connectport=8090 connectaddress=WSL_IP
```
3. Run Flutter normal:
```bash
flutter run
```

## Instalasi Flutter

```bash
# Clone repo
git clone https://github.com/LunaeKim99/finance-app.git

# Install dependencies
flutter pub get

# Run
flutter run
```

## Build

```bash
# Android APK (dengan API key)
flutter build apk --dart-define=GROQ_API_KEY=your_groq_key_here

# Android Release
flutter build apk --release --dart-define=GROQ_API_KEY=your_groq_key_here

# iOS (hanya di macOS)
flutter build ios --release --dart-define=GROQ_API_KEY=your_groq_key_here
```

## Requirements

- Android: API 21+ (Android 5.0)
- iOS: 13.0+
- SQLite: included (sqflite) — offline fallback
- PocketBase: v0.23+ (primary storage, auto-fallback ke SQLite)
- Midtrans: for payment (optional, configure in .env)

## Configuration

### API Keys

API keys sekarang Passed via `--dart-define` saat build time:

```bash
flutter run --dart-define=GROQ_API_KEY=gsk_xxxxxxxxxx
```

Lihat section **Setup API Keys** untuk detail lengkap.

### PocketBase (Primary Storage)

PocketBase sekarang adalah **PRIMARY storage**. Jika server reachable, app akan otomatis menggunakan PocketBase dan menyimpan cache ke SQLite. Jika server offline, app fallback ke SQLite dan queue perubahan untuk sync otomatis.

```bash
# Run PocketBase server
./pocketbase serve

# Default URL dikonfigurasi di lib/config/app_config.dart
# Android emulator: http://10.0.2.2:8090
# iOS simulator: http://127.0.0.1:8090
# Ngrok tunnel: https://equator-untainted-stank.ngrok-free.dev
```

### Midtrans Payment

Payment menggunakan PocketBase hook (server-side). 
Pastikan:

1. PocketBase server berjalan
2. Hook `pb_hooks/create_snap_token.pb.js` sudah di-register
3. Environment variable `MIDTRANS_SERVER_KEY` dan `MIDTRANS_BASE_URL` sudah diset di server

## 🖼️ Generasi Ikon Aplikasi

Untuk membuat ulang ikon aplikasi dari logo sumber:

```bash
npm install           # install dependencies sekali
npm run generate-icons
```

Script tersimpan di folder `scripts/`.

## Lisensi

MIT