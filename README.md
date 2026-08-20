# DUITKU

DUITKU adalah aplikasi pengelola keuangan pribadi berbasis Flutter. Aplikasi ini membantu pengguna memantau kondisi keuangan, mencatat transaksi, mengatur anggaran, dan merencanakan target tabungan dengan penyimpanan lokal.

## Fitur

- Dashboard saldo, pemasukan, pengeluaran, dan ringkasan periode
- Transaksi `Income`, `Expense`, dan `Transfer` antar akun
- Banyak akun keuangan, seperti rekening bank dan kas
- Kategori pemasukan dan pengeluaran
- Anggaran bulanan berdasarkan kategori
- Target tabungan dengan pelacakan progres
- Laporan dan breakdown transaksi berdasarkan kategori
- Onboarding, profil, pengaturan tema, serta pengaturan mata uang
- Proteksi aplikasi dengan autentikasi lokal jika tersedia di perangkat
- Notifikasi lokal
- Penyimpanan offline-first menggunakan Hive

## Teknologi

- Flutter dan Dart
- Material 3
- Riverpod untuk state management
- GoRouter untuk navigasi
- Hive CE untuk database lokal
- `fl_chart` untuk visualisasi laporan
- `intl` untuk format angka, mata uang, dan tanggal
- `local_auth` untuk autentikasi biometrik atau perangkat
- `share_plus` untuk berbagi data atau laporan
- `flutter_local_notifications` untuk notifikasi lokal

## Struktur proyek

```text
lib/
├── app/             # Konfigurasi aplikasi dan routing
├── core/            # Logika finansial, provider, tema, dan utilitas
├── data/            # Database, model, dan repository
├── features/        # Modul fitur aplikasi
│   ├── accounts/    ├── budget/       ├── dashboard/
│   ├── onboarding/  ├── profile/      ├── reports/
│   ├── savings/     ├── security/     ├── settings/
│   ├── shell/       └── transactions/
├── widgets/         # Widget yang digunakan bersama
└── main.dart        # Entry point aplikasi

test/
├── app_test.dart
└── finance_test.dart
```

## Persyaratan

- Flutter SDK yang mendukung Dart `^3.13.0`
- Android Studio dan Android SDK untuk target Android
- Xcode untuk target iOS atau macOS
- Chrome untuk menjalankan target web

Pastikan Flutter tersedia di `PATH`, lalu cek instalasinya:

```powershell
flutter doctor
flutter --version
```

## Menjalankan proyek

```powershell
git clone <url-repositori>
cd DUITKU
flutter pub get
flutter devices
flutter run -d chrome
```

Gunakan device lain dengan mengganti target pada perintah terakhir, misalnya `flutter run -d windows` atau `flutter run -d android`.

## Pengujian dan analisis

```powershell
flutter test
flutter analyze
```

Test mencakup pemuatan aplikasi, formatter mata uang, perhitungan saldo, transaksi, transfer, serta status anggaran.

## Penyimpanan data

Data aplikasi disimpan secara lokal di perangkat menggunakan Hive. Saat ini belum ada sinkronisasi cloud, sehingga penghapusan data aplikasi atau perangkat dapat menghilangkan data yang tersimpan. Fitur backup/restore dan export laporan dapat ditambahkan pada pengembangan berikutnya.

## Roadmap

- Backup dan restore data
- Export laporan ke CSV atau PDF
- Pengingat transaksi dan anggaran yang lebih fleksibel
- Penyempurnaan onboarding dan migrasi data

## Lisensi

Proyek ini dibuat untuk kebutuhan pengembangan pribadi dan dapat dimodifikasi sesuai kebutuhan penggunanya.
