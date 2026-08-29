# DUITKU

DUITKU adalah aplikasi pengelola keuangan pribadi berbasis Flutter. Aplikasi ini membantu pengguna memantau kondisi keuangan, mencatat transaksi, mengatur anggaran, dan merencanakan target tabungan dengan penyimpanan lokal.

## Fitur

- Dashboard saldo, skor kesehatan keuangan, grafik pemasukan/pengeluaran, dan ringkasan budget
- Transaksi `Income`, `Expense`, dan `Transfer` antar akun, lengkap dengan CRUD dan konfirmasi hapus
- Banyak akun keuangan, seperti rekening bank, kas, e-wallet, dan uang jajan
- Kategori bawaan (default/system) pemasukan & pengeluaran otomatis tersedia sejak pertama kali aplikasi dibuka — tidak bisa diedit/dihapus, dipisahkan dari kategori buatan pengguna di layar Kategori
- Kategori kustom dengan CRUD penuh, termasuk alur "Lainnya → buat kategori kustom" saat mencatat transaksi
- Anggaran bulanan berdasarkan kategori
- Target tabungan dengan pelacakan progres dan streak
- Cicilan & utang (kartu kredit, paylater, cicilan barang) dengan pengingat jatuh tempo
- Transaksi berulang untuk langganan dan tagihan rutin
- Limit uang jajan per akun
- Laporan dan breakdown transaksi berdasarkan kategori, plus fitur gajian/alokasi
- Activity Log / audit history: setiap perubahan data (tambah/ubah/hapus di transaksi, kategori, budget, rekening) tercatat otomatis dan permanen — tidak ikut terhapus saat data lain dihapus atau di-restore
- Backup & restore data (JSON), export transaksi (CSV), dan export laporan bulanan (PDF)
- Onboarding, profil dengan foto, pengaturan tema, serta pengaturan mata uang
- Proteksi aplikasi dengan PIN dan autentikasi biometrik jika tersedia di perangkat
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
- `pdf` untuk export laporan bulanan
- `image_picker` untuk foto profil
- `path_provider` untuk lokasi penyimpanan file backup/export
- `crypto` untuk hashing PIN aplikasi
- `uuid` untuk id entitas, `timezone` untuk penjadwalan notifikasi lokal

Application id (Android): `com.duitku.duitku`.

## Struktur proyek

```text
lib/
├── app/             # Konfigurasi aplikasi dan routing
├── core/            # Logika finansial, provider, tema, dan utilitas
├── data/            # Database, model, dan repository
├── features/        # Modul fitur aplikasi
│   ├── accounts/     ├── activity_log/  ├── budget/
│   ├── dashboard/    ├── debts/         ├── onboarding/
│   ├── profile/      ├── recurring/     ├── reports/
│   ├── savings/      ├── security/      ├── settings/
│   ├── shell/        └── transactions/
├── widgets/         # Widget yang digunakan bersama
└── main.dart        # Entry point aplikasi

test/                # Unit test untuk logika finansial, kalkulator,
                     # controller, Activity Log, dan export laporan
tool/                # Skrip pengembangan (mis. generate_adaptive_icon.dart
                     # untuk membangun ikon adaptif Android)
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

## Build rilis

```powershell
flutter build apk --release        # Android (APK)
flutter build appbundle --release  # Android (Play Store)
flutter build web --release        # Web
```

Untuk rilis Android yang ditandatangani, buat `android/key.properties` dan file
keystore Anda sendiri. Kedua file tersebut sengaja diabaikan Git (lihat
`.gitignore`) dan tidak boleh dibagikan.

## Pengujian dan analisis

```powershell
flutter test
flutter analyze
```

Test mencakup pemuatan aplikasi, formatter mata uang, perhitungan saldo, transaksi, transfer, status anggaran, cicilan, transaksi berulang, skor kesehatan, Activity Log, dan export laporan.

## Penyimpanan data

Data aplikasi disimpan secara lokal di perangkat menggunakan Hive. Saat ini belum ada sinkronisasi cloud, sehingga penghapusan data aplikasi atau perangkat dapat menghilangkan data yang tersimpan. Gunakan fitur Backup & Restore (JSON) untuk memindahkan data antar perangkat.

Activity Log disimpan di box Hive terpisah (`duitku_activity_logs`) yang sengaja tidak ikut dibersihkan saat restore "Ganti" data dan tidak dimasukkan ke file backup, sehingga audit trail selalu utuh.

## Roadmap

- Sinkronisasi cloud dan multi-perangkat
- Pengingat transaksi dan anggaran yang lebih fleksibel
- Penyempurnaan onboarding dan migrasi data

## Lisensi

Proyek ini dibuat untuk kebutuhan pengembangan pribadi dan dapat dimodifikasi sesuai kebutuhan penggunanya.
