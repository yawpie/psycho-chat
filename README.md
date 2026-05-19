# Psycho Chat

## Ringkasan Struktur Proyek

Berikut penjelasan singkat fungsi setiap folder dan file penting di proyek ini:

- `backend/` : Berisi layanan backend (Node.js). Termasuk `package.json` dan kode sumber di `src/` — mis. `src/server.js` menjalankan API/server yang melayani klien.
- `mobile/` : Aplikasi mobile berbasis Flutter. Termasuk `pubspec.yaml`, konfigurasi Android (`android/`), iOS (`ios/`) dan kode aplikasi di `lib/`.
- `lib/` : Kode sumber utama aplikasi Flutter (mis. `main.dart`). Di sinilah logika UI dan fitur aplikasi mobile berada.
- `android/`, `ios/`, `macos/`, `linux/`, `windows/` : Direktori native yang dibuat oleh Flutter untuk masing-masing platform (build / konfigurasi native). Jangan mengedit bagian yang dihasilkan kecuali Anda paham konsekuensinya.
- `build/` : Artefak build dan berkas hasil kompilasi (generated files). Bersifat ter-generate dan biasanya diabaikan dalam kontrol versi.
- `native_assets/` : Aset native yang disertakan untuk target platform (contoh: file untuk `android/`, `windows/`, dll.).
- `native_hooks/` : Hook native khusus yang digunakan saat proses build/deploy.
- `test/` : Tes unit/widget untuk aplikasi Flutter.
- `web/` : Berkas dan aset untuk target Web (index.html, manifest, icons) ketika aplikasi Flutter dibangun untuk web.
- `mobile/app/` dan subfolder `build.gradle.kts` dll.: Konfigurasi dan modul Gradle untuk modul Android dari aplikasi mobile.
- `build/937c3db8349c8c8e17d693c1f7d27f18/` : Direktori internal build cache/metadata (contoh hasil build sebelumnya).

File dan konfigurasi penting lainnya

- Root `README.md` : Dokumen ini, tempat menjelaskan struktur dan panduan singkat.
- `backend/package.json` : Definisi dependensi dan script untuk menjalankan backend.
- `mobile/pubspec.yaml` : Definisi dependensi Flutter, aset, dan konfigurasi package untuk aplikasi mobile.

## Catatan dan rekomendasi

- Banyak folder di proyek ini adalah hasil build/generate (mis. `build/`, platform-specific folders). Jangan commit file hasil build ke Git kecuali sengaja diperlukan.
- Untuk mengembangkan backend: masuk ke `backend/`, jalankan `npm install` lalu `npm run start` (sesuaikan dengan `package.json`).
- Untuk mengembangkan mobile: buka `mobile/` dengan Android Studio atau VS Code, jalankan `flutter pub get`, lalu gunakan `flutter run` untuk target yang diinginkan.

Butuh penjelasan lebih rinci untuk folder tertentu? Beritahu saya folder mana yang ingin Anda perinci (mis. `backend/src` atau `mobile/lib/widgets`), saya akan tambahkan deskripsi dan contoh perintah develop.
