# Sitanam – Aplikasi Smart Precision Farming System

![Logo Sitanam](dok/00.png)

**Sitanam** adalah aplikasi mobile berbasis Smart Precision Farming yang dirancang untuk membantu petani dalam mengelola lahan pertanian secara modern, efisien, dan berkelanjutan. Aplikasi ini terintegrasi dengan perangkat IoT (Internet of Things) berbasis ESP32 dan berbagai sensor (kelembaban tanah, suhu, kelembaban udara, NPK, pH, dsb.), sehingga mampu memantau kondisi lahan secara real-time, mengontrol alat dan melihat rekomendasi pupuk yang sesuai dengan tanaman menggunakan sistem pengambilan keputusan presisi.<p>



## Ketentuan Teknis
Pengembangan Aplikasi ini menggunakan framework **Flutter** dan berikut adalah ketentuan teknis untuk menjalankan aplikasi

| Teknologi | Versi     |
|-----------|-----------|
| Flutter   | 3.22.2      |
| Dart      | 3.4.3    | 

**Penting!** diharpakan saat menjalankan versi flutter anda sesuai dengan ketentuan teknis diatas agar tidak ada perubahan warna tampilan dan lainya.

## Alur Penggunaan Aplikasi
Alur aplikasi sitanam dapat dilihat pada flowchart dibawah ini

![alur sistem](dok/0.png)<p>


## Dokumentasi Pengerjaan

### Seluruh Dokumentasi Pengerjaan Per fitur dan halaman aplikasi akan dijelaskan dibawah ini !

**Pembuatan Splash Screen**<p>
Saat aplikasi dijalankan, pertama kali muncul Splash Screen berupa logo dan nama sistem selama 5 detik. Layar ini memberi kesan awal sekaligus waktu inisialisasi, lalu otomatis mengarahkan pengguna ke halaman login.<p>

![Logo Sitanam](dok/1.png)

**Pembuatan Halaman Login & Register**<p>
Halaman Login digunakan untuk masuk dengan email dan password melalui Firebase Authentication. Jika benar, pengguna masuk ke Halaman Daftar Perangkat IoT, jika salah muncul pesan error.
Halaman Register digunakan untuk membuat akun baru dengan email, password, dan konfirmasi password, lalu didaftarkan ke Firebase Authentication.

| Halaman Login | Halaman Register | Error Handling (berhasil login)| Error Handling (gagal login)|
|----------|----------|----------|--------|
| ![Gambar 1](dok/2.png) | ![Gambar 2](dok/3.png) | ![Gambar 3](dok/4.png) |![Gambar 4](dok/13.png) |

**Pembuatan Halaman Daftar Perangkat IoT**<p>
Halaman Daftar Perangkat IoT menampilkan perangkat yang terhubung secara real-time dari Firebase Realtime Database. Setelah login, pengguna diarahkan ke halaman ini: jika belum ada perangkat, ditampilkan panduan menambah perangkat; jika ada, ditampilkan daftar perangkat dalam bentuk card untuk dikontrol.
Pengguna dapat menambah perangkat lewat ikon +, menghapus perangkat dengan tekan lama pada card, serta mengatur akun lewat ikon profil di pojok kanan atas..

| Daftar Perangkat IoT (jika masih belum memiliki perangkat) | Daftar Perangkat IoT (telah menambahkan perangkat ke aplikasi)  | Error Handling (jika menghapus perangkat)|
|----------|----------|----------|
| ![Gambar 1](dok/5.png) | ![Gambar 2](dok/6.png) | ![Gambar 3](dok/7.png) |


**Pembuatan Halaman Tambah Perangkat IoT**<p>
Halaman ini memudahkan pengguna menghubungkan perangkat IoT ke akun dengan memindai kode QR. Sistem akan memverifikasi ID di Firebase, lalu menambahkan UID pengguna ke data perangkat. Jika berhasil, muncul popup konfirmasi.

| View Scan QR menambahkan perangkat IoT | Error Handling (jika berhasil menambahkan perangkat) |
|----------|----------|
| ![Gambar 1](dok/8.jpg) | ![Gambar 2](dok/9.jpg) |


**Pembuatan Halaman Kelola Akun**<p>
Halaman ini menampilkan email akun aktif, menyediakan fitur ganti password (dengan memasukkan password lama, baru, dan konfirmasi), serta tombol logout untuk keluar dari akun.

| Halaman Kelola Akun | Halaman Kelola Akun (kolom isi) | Error Handling |
|----------|----------|-------------|
| ![Gambar 1](dok/10.png) | ![Gambar 2](dok/11.png) |  ![Gambar 3](dok/12.png) |

**Pembuatan Halaman Dashboard Kontrol Perangkat IoT**<p>
Setelah memilih perangkat yng ingin dikontrol, pengguna diarahkan ke Dashboard sebagai pusat navigasi IoT. Dashboard ini sederhana dan menampilkan menu menuju fitur utama seperti Kendali IoT, Status Lingkungan, Catatan, dan Rekomendasi Pupuk, sehingga memudahkan pemantauan dan pengendalian sesuai kebutuhan.

| Halaman Dashboard Kontrol Perangkat IoT | 
|----------|
| ![Gambar 1](dok/14.png) |

**Pembuatan Halaman Kendali IoT**<p>
Halaman Kendali IoT memungkinkan pengguna mengatur pompa dari jarak jauh. Tersedia dua mode: Manual, dengan tombol hidupkan/matikan pompa, dan Otomatis, di mana sistem mengendalikan pompa sesuai logika yang telah ditentukan. Tampilan dibuat sederhana agar pengguna mudah berpindah antar mode sesuai kebutuhan di lapangan.

| Mode Manual Pompa On| Mode Manual Pompa Off | Mode Otomatis sesuai kelembaban tanah |
|----------|----------|-------------|
| ![Gambar 1](dok/15.png) | ![Gambar 2](dok/16.png) |  ![Gambar 3](dok/17.png) |


-------------------



This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
