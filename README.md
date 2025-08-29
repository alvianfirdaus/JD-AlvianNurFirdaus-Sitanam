# Sitanam – Aplikasi Smart Precision Farming System

![Logo Sitanam](assets/images/logositanam.png)

**Sitanam** adalah aplikasi mobile berbasis Smart Precision Farming yang dirancang untuk membantu petani dalam mengelola lahan pertanian secara modern, efisien, dan berkelanjutan. Aplikasi ini terintegrasi dengan perangkat IoT (Internet of Things) berbasis ESP32 dan berbagai sensor (kelembaban tanah, suhu, kelembaban udara, NPK, pH, dsb.), sehingga mampu memantau kondisi lahan secara real-time, mengontrol alat dan melihat rekomendasi pupuk yang sesuai dengan tanaman menggunakan sistem pengambilan keputusan presisi.

## Ketentuan Teknis
Pengembangan Aplikasi ini menggunakan framework **Flutter** dan berikut adalah ketentuan teknis untuk menjalankan aplikasi

| Teknologi | Versi     |
|-----------|-----------|
| Flutter   | 3.22.2      |
| Dart      | 3.4.3    | 

**Penting!** diharpakan saat menjalankan versi flutter anda sesuai dengan ketentuan teknis diatas agar tidak ada perubahan warna tampilan dan lainya.

## Alur Penggunaan Aplikasi
Alur aplikasi sitanam dapat dilihat pada flowchart dibawah ini

![alur sistem](assets/images/alur.png)<p>


## Dokumentasi Pengerjaan

### 29 Agustus 2025

**Pembuatan Splash Screen**<p>
Saat aplikasi dijalankan, pertama kali muncul Splash Screen berupa logo dan nama sistem selama 5 detik. Layar ini memberi kesan awal sekaligus waktu inisialisasi, lalu otomatis mengarahkan pengguna ke halaman login.<p>

![Logo Sitanam](dok/1.png)

**Pembuatan Halaman Login & Register**<p>
Halaman Login digunakan untuk masuk dengan email dan password melalui Firebase Authentication. Jika benar, pengguna masuk ke Halaman Daftar Perangkat IoT, jika salah muncul pesan error.
Halaman Register digunakan untuk membuat akun baru dengan email, password, dan konfirmasi password, lalu didaftarkan ke Firebase Authentication.

| Login | Register | Error Handling |
|----------|----------|----------|
| ![Gambar 1](dok/2.png) | ![Gambar 2](dok/3.png) | ![Gambar 3](dok/4.png) |




This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
