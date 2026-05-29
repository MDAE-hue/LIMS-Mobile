# LIMS Mobile

<p align="center">
  <strong>Laboratory Information Management System untuk pengelolaan report, lab task, review, dan monitoring status pekerjaan laboratorium.</strong>
</p>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-Mobile-02569B?style=for-the-badge&logo=flutter&logoColor=white">
  <img alt="Laravel" src="https://img.shields.io/badge/Laravel-Backend-FF2D20?style=for-the-badge&logo=laravel&logoColor=white">
  <img alt="Dart" src="https://img.shields.io/badge/Dart-App-0175C2?style=for-the-badge&logo=dart&logoColor=white">
  <img alt="PHP" src="https://img.shields.io/badge/PHP-API-777BB4?style=for-the-badge&logo=php&logoColor=white">
</p>

## Apa Itu Proyek Ini?

LIMS Mobile adalah aplikasi mobile untuk membantu alur kerja laboratorium agar proses pembuatan laporan, penugasan lab, review, acknowledgement, sampai penutupan report bisa dipantau dalam satu sistem.

Proyek ini terdiri dari dua bagian utama:

- `frontend`: aplikasi mobile Flutter untuk pengguna.
- `backend`: REST API Laravel sebagai pusat data, autentikasi, role, report, dan aktivitas sistem.

Tujuan utamanya adalah membuat proses request dan monitoring report lebih rapi, cepat dicek, dan mudah dilacak oleh beberapa role pengguna.

## Fitur Utama

- Login berbasis akun dan role pengguna.
- Dashboard ringkasan status report.
- Grafik distribusi status, perkembangan mingguan, dan perkembangan bulanan.
- Manajemen report dari request sampai closed.
- Filter report berdasarkan status proses.
- Review report untuk role yang berwenang.
- Lab task untuk pekerjaan analyst/sampler.
- Manajemen user untuk admin.
- Settings dan logout session.
- Activity log di backend untuk jejak aktivitas sistem.

## Role Pengguna

Sistem mendukung beberapa role agar menu dan akses pengguna bisa disesuaikan:

- Admin
- Manager
- Superintendent
- Sampler
- Analyst
- User

Setiap role dapat memiliki akses tab dan aksi yang berbeda, misalnya review report, melihat lab task, atau mengelola user.

## Tech Stack

| Bagian | Teknologi |
| --- | --- |
| Mobile App | Flutter, Dart |
| Backend API | Laravel, PHP |
| HTTP Client | http, dio |
| Chart | fl_chart |
| Local Session | shared_preferences |
| Database | Mengikuti konfigurasi Laravel pada `.env` |

## Struktur Proyek

```text
LIMS_mobile/
├── backend/      # Laravel API
├── frontend/     # Flutter mobile app
└── README.md     # Dokumentasi utama proyek
```

## Cara Menjalankan Backend

Masuk ke folder backend:

```powershell
cd D:\Projek\LIMS_mobile\backend
```

Install dependency PHP:

```powershell
composer install
```

Salin file environment:

```powershell
copy .env.example .env
```

Generate app key:

```powershell
php artisan key:generate
```

Jalankan migrasi database:

```powershell
php artisan migrate
```

Jalankan server Laravel:

```powershell
php artisan serve
```

Secara default API akan berjalan di:

```text
http://127.0.0.1:8000
```

## Cara Menjalankan Frontend

Masuk ke folder frontend:

```powershell
cd D:\Projek\LIMS_mobile\frontend
```

Install dependency Flutter:

```powershell
flutter pub get
```

Cek device atau emulator:

```powershell
flutter devices
```

Jalankan aplikasi:

```powershell
flutter run
```

Jika menggunakan Android emulator, pastikan konfigurasi API di Flutter mengarah ke alamat backend yang benar. Untuk emulator Android, biasanya localhost komputer host diakses dengan:

```text
http://10.0.2.2:8000
```

## Konfigurasi API Frontend

Konfigurasi alamat API dapat dicek di:

```text
frontend/lib/core/config/api_config.dart
```

Pastikan base URL sesuai dengan environment yang sedang digunakan, misalnya emulator, device fisik, atau server lokal.

## Status Pengembangan

Proyek ini masih dapat dikembangkan lebih lanjut, terutama pada:

- Validasi form yang lebih lengkap.
- Polishing UI di semua halaman detail dan form.
- Unit test dan widget test tambahan.
- Dokumentasi endpoint API.
- Deployment backend ke server.
- Build release Android.

## Catatan

File sensitif dan hasil build tidak disimpan ke repository, seperti:

- `.env`
- `vendor/`
- `build/`
- `.dart_tool/`
- `storage/logs/`
- file cache lokal

Gunakan `.env.example` sebagai template konfigurasi backend.

## Lisensi

Proyek ini dibuat untuk kebutuhan pengembangan aplikasi LIMS Mobile.
