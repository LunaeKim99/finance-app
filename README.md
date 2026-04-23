# Personal Finance App

Aplikasi Pencatatan Pengeluaran & Pemasukan Harian (Finance App) menggunakan Flutter dengan dukungan penuh untuk Android dan iOS.

## Fitur

- **Dashboard** - Menampilkan saldo total, pemasukan & pengeluaran bulan ini
- **Tambah Transaksi** - Input transaksi dengan kategori, nominal, tanggal, dan catatan
- **Riwayat** - Lihat semua transaksi dengan filter (Semua/Pemasukan/Pengeluaran)
- **Laporan** - Pie chart pengeluaran per kategori, bar chart 6 bulan terakhir
- **Cross-Platform** - Tampilan native untuk Android (Material) dan iOS (Cupertino)

## Teknologi

- Flutter SDK ^3.11.4
- Provider (state management)
- sqflite (local database)
- fl_chart (charts)
- intl (formatting mata uang Indonesia)

## Struktur Proyek

```
lib/
├── main.dart                  # Entry point & routing
├── database/
│   └── db_helper.dart        # SQLite helper
├── models/
│   └── transaction_model.dart
├── providers/
│   └── transaction_provider.dart
├── screens/
│   ├── dashboard_screen.dart
│   ├── add_transaction_screen.dart
│   ├── history_screen.dart
│   └── report_screen.dart
├── widgets/
│   └── transaction_card.dart
└── utils/
    └── platform_helper.dart
```

## Instalasi

```bash
# Clone repo
git clone https://github.com/KimYo2/finance-app.git

# Install dependencies
flutter pub get

# Run
flutter run
```

## Build

```bash
# Android APK
flutter build apk --debug

# Android Release
flutter build apk --release

# iOS (hanya di macOS)
flutter build ios --release
```

## Requirements

- Android: API 21+ (Android 5.0)
- iOS: 13.0+

## Lisensi

MIT