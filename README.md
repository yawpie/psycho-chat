# Psycho Chat

## Link Presentasi (Matkul Crypto)


## Ringkasan Struktur Proyek

Berikut penjelasan singkat fungsi setiap folder dan file penting di proyek ini:

- `backend/` berisi layanan Node.js. Entry point server ada di `backend/src/server.ts`.
- `mobile/` berisi aplikasi Flutter. Kode UI utama ada di `mobile/lib/`.
- `backend/prisma/schema.prisma` berisi skema database Prisma.
- `build/` dan folder platform native Flutter seperti `android/`, `ios/`, `macos/`, `linux/`, `windows/` adalah hasil generate atau konfigurasi platform.

File konfigurasi penting:

- `backend/package.json` berisi script untuk menjalankan backend, build, dan seed data.
- `backend/.env.example` menyimpan `DATABASE_URL`, dan di repo ini nilainya mengarah ke SQLite lokal.
- `mobile/pubspec.yaml` berisi dependensi dan konfigurasi aplikasi Flutter.

## Cara Menjalankan Program

### 1. Prasyarat

- Node.js versi 20 atau lebih baru.
- Flutter SDK yang sudah terpasang.
- Emulator Android, simulator iOS, atau device fisik untuk menjalankan aplikasi mobile.

### 2. Jalankan backend

1. Buka terminal dan masuk ke folder `backend`.
2. Jalankan `npm install` untuk memasang dependensi.
3. Pastikan file `backend/.env` tersedia dan berisi `DATABASE_URL="file:./path/to_db.sqlite"`.
4. Jalankan backend dengan `npm run dev`.
5. Backend akan berjalan di `http://localhost:3000` secara default.

Jika ingin menjalankan mode production secara lokal, gunakan `npm run build` lalu `npm start`.

### 3. Jalankan aplikasi mobile

1. Buka terminal baru dan masuk ke folder `mobile`.
2. Jalankan `flutter pub get` untuk mengambil dependensi Flutter.
3. Pastikan emulator atau device sudah aktif.
4. Jalankan `flutter run`.
5. Jika muncul pilihan device, pilih target yang ingin digunakan.

### 4. Data contoh opsional

Jika ingin mengisi database dengan data contoh, jalankan perintah berikut dari folder `backend`:

- `npm run seed:all` untuk menambahkan data user, conversation, dan message.
- `npm run delete-convos` jika ingin membersihkan data conversation.

## Urutan yang Disarankan

1. Jalankan backend terlebih dahulu.
2. Setelah backend aktif, jalankan aplikasi Flutter.
3. Jika aplikasi mobile tidak bisa terhubung, cek kembali IP backend yang disimpan di pengaturan aplikasi dan pastikan backend masih berjalan.

## Catatan

- Banyak folder di proyek ini adalah hasil build/generate. Jangan commit file hasil build ke Git kecuali memang sengaja diperlukan.
- Jika Anda ingin, saya bisa lanjut menambahkan bagian troubleshooting, misalnya untuk error koneksi backend, Flutter device tidak terdeteksi, atau database Prisma belum terbentuk.
