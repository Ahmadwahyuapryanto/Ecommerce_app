# Nama : Ahmad Wahyu Apryanto
# NPM : 2022804098

# Ecommerce
Aplikasi e-commerce ini adalah platform jual beli online berbasis Flutter yang dirancang untuk memberikan pengalaman berbelanja yang modern dan interaktif. Dengan dukungan Firebase sebagai backend, aplikasi ini menawarkan fitur lengkap mulai dari pendaftaran dan login pengguna, penjelajahan produk dengan filter dan pencarian, hingga proses checkout yang mudah. Pengguna dapat menambahkan produk ke keranjang, memilih layanan pengiriman, dan melihat riwayat pesanan mereka. Untuk meningkatkan interaksi, aplikasi ini juga dilengkapi dengan sistem ulasan dan peringkat produk. Pengalaman pengguna diperkaya dengan berbagai animasi halus, seperti transisi antar halaman, efek saat menambahkan produk ke keranjang, dan notifikasi visual setelah pembayaran berhasil, menjadikan aplikasi ini tidak hanya fungsional tetapi juga menarik secara visual.

# Fitur Aplikasi
Berdasarkan analisis dari file yang Anda berikan, berikut adalah fitur-fitur yang ada di aplikasi Anda:

- Autentikasi Pengguna:

Pengguna dapat mendaftar dan masuk ke aplikasi menggunakan email dan kata sandi melalui Firebase Auth.

Terdapat fitur untuk keluar dari akun (logout).

Aplikasi dapat memvalidasi apakah pengguna sudah masuk atau belum untuk mengakses fitur tertentu.

- Manajemen Produk:

Admin dapat menambah, mengedit, dan menghapus produk.

Produk memiliki informasi seperti nama, harga, kategori, deskripsi, gambar, dan peringkat.

- Tampilan Produk dan Beranda:

Halaman utama (beranda) menampilkan daftar produk, spanduk promosi yang dapat bergeser otomatis, dan filter berdasarkan kategori.

Terdapat fitur pencarian untuk menemukan produk berdasarkan nama.

- Keranjang Belanja:

Pengguna dapat menambahkan produk ke keranjang belanja.

Pengguna dapat melihat, memperbarui jumlah, dan menghapus produk dari keranjang.

Aplikasi akan menampilkan notifikasi saat produk berhasil ditambahkan ke keranjang.

- Proses Pembelian (Checkout):

Pengguna dapat melakukan proses pembelian langsung dari halaman detail produk atau dari keranjang belanja.

Pengguna dapat memilih layanan pengiriman yang tersedia.

Setelah pembayaran berhasil, pesanan akan dibuat dan keranjang akan dikosongkan.

- Riwayat Pesanan:

Pengguna dapat melihat riwayat pesanan yang telah mereka buat.

Setiap pesanan menampilkan detail produk, tanggal, status, dan total pembayaran.

- Ulasan dan Peringkat Produk:

Pengguna dapat memberikan ulasan dan peringkat untuk produk yang telah mereka beli.

Aplikasi menampilkan rata-rata peringkat dan jumlah ulasan pada setiap produk.

- Notifikasi:

Terdapat halaman notifikasi yang mengelompokkan pemberitahuan berdasarkan waktu (Hari Ini, Minggu Ini, Lebih Lama).

Notifikasi dapat difilter berdasarkan status "semua", "belum dibaca", dan "sudah dibaca".

- Profil Pengguna:

Menampilkan nama dan email pengguna yang sedang masuk.

Menyediakan menu untuk mengedit profil, alamat, dan pengaturan lainnya (meskipun fungsionalitasnya belum diimplementasikan sepenuhnya).

# Animasi yang Digunakan
Aplikasi Anda menggunakan beberapa animasi untuk meningkatkan pengalaman pengguna:

- Animasi Transisi Halaman: Aplikasi menggunakan transisi fade (memudar) saat berpindah antar halaman.

- Animasi Daftar dan Grid: Saat menampilkan daftar produk di beranda, aplikasi menggunakan animasi staggered grid dengan efek slide dan fade in untuk memunculkan setiap kartu produk secara bertahap.

- Animasi Lottie:

- pay_success.json: Animasi ini ditampilkan dalam sebuah dialog setelah pengguna berhasil melakukan pembayaran, memberikan konfirmasi visual yang menarik.

- Animasi 'Terbang ke Keranjang': Saat pengguna menambahkan produk ke keranjang dari halaman beranda, sebuah partikel akan "terbang" dari tombol "tambah" menuju ikon keranjang belanja, memberikan umpan balik visual yang interaktif.

- Animasi Pergantian AppBar: Terdapat transisi fade dan slide saat AppBar berubah dari tampilan normal ke tampilan pencarian.

- assets/fitur.png