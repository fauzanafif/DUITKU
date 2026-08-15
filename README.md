# DUITKU

DUITKU adalah aplikasi pengelola keuangan pribadi yang dibangun dengan Flutter. Aplikasi ini dirancang untuk membantu pengguna mencatat pemasukan, pengeluaran, transfer antar rekening, pengelolaan anggaran, target tabungan, serta melihat laporan keuangan secara ringkas dan lokal.

## Fitur utama

- Dashboard ringkas dengan saldo, pemasukan, dan pengeluaran
- Catatan transaksi dengan tipe Income, Expense, dan Transfer
- Manajemen akun keuangan multi-rekening
- Kategori pemasukan dan pengeluaran
- Anggaran bulanan per kategori
- Target tabungan dengan progress tracking
- Laporan keuangan dan breakdown kategori
- Tema terang dan gelap
- Penyimpanan lokal berbasis Hive untuk data offline-first

## Tech stack

- Flutter
- Dart
- Riverpod
- GoRouter
- Hive
- Intl
- fl_chart
- Material 3

## Struktur proyek

```text
lib/
├── app/
│   ├── duitku_app.dart
│   └── router.dart
├── core/
│   ├── finance/
│   ├── providers/
│   └── theme/
├── data/
│   ├── database/
│   ├── models/
│   └── repositories/
├── features/
│   ├── accounts/
│   ├── budget/
│   ├── dashboard/
│   ├── profile/
│   ├── reports/
│   ├── savings/
│   ├── settings/
│   └── transactions/
├── main.dart
└── utils/

test/
├── finance_test.dart
└── app_test.dart
```

## Persyaratan

Pastikan Flutter SDK sudah terinstall dan tersedia di PATH.

Pada Windows, biasanya digunakan:

```powershell
$env:PATH = 'C:\src\flutter\bin;' + $env:PATH
flutter --version
```

## Cara menjalankan

1. Clone project
2. Install dependency

```powershell
cd C:\Users\user\Documents\DUITKU
$env:PATH = 'C:\src\flutter\bin;' + $env:PATH
flutter pub get
```

3. Jalankan aplikasi di Chrome atau emulator

```powershell
flutter run -d chrome
```

Untuk Android atau iOS, sesuaikan target device Anda:

```powershell
flutter devices
flutter run
```

## Verifikasi proyek

Proyek saat ini sudah diverifikasi dengan:

```powershell
flutter test
flutter analyze --no-fatal-infos
```

Status terbaru: semua test bisnis utama berjalan lancar dan analyzer tidak menemukan issue.

## Catatan pengembangan

Proyek ini menggunakan pendekatan local-first, sehingga data tersimpan di perangkat secara offline. Data utama dikelola lewat Hive dan dipantau melalui provider state management menggunakan Riverpod.

## Roadmap

- Penambahan backup/restore data
- Keamanan tambahan dengan PIN atau biometric
- Export laporan CSV/PDF
- Notifikasi pengingat transaksi dan anggaran
- Peningkatan UX untuk onboarding dan migration data

## Lisensi

Proyek ini dibuat untuk kebutuhan pengembangan pribadi dan dapat dimodifikasi sesuai kebutuhan penggunanya.
