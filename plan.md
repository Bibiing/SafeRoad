SafeRoad Admin Enhancement Plan

Tujuan Utama
Transformasi Dashboard Admin dari sekadar ringkasan menjadi pusat kendali laporan yang
fungsional, mencakup manajemen status, alasan penolakan, sistem notifikasi, dan pelaporan data (ekspor).

---

Fase 1: Re-Branding & UI Differentiation
Agar Admin tidak merasa berada di tampilan User, kita akan memberikan perbedaan visual yang kontras.

- Fitur: Menambahkan Admin Sidebar/Drawer khusus untuk navigasi cepat antar menu (Dashboard, Manajemen Laporan, Ekspor).

Fase 2: Alur Kerja Penolakan (Rejection Reason)
Admin tidak boleh menolak laporan tanpa penjelasan.

- Aksi: Memperbarui model data Report di Firestore untuk mendukung field rejectionReason.
- Fitur: Implementasi Rejection Dialog. Jika Admin memilih status "Ditolak", akan muncul popup form untuk mengisi alasan. Alasan ini akan disimpan dan dapat dilihat oleh User pembuat laporan.

Fase 3: Notifikasi Otomatis (FCM Integration)
Memberikan feedback instan kepada User saat ada kemajuan pada laporan mereka.

- Aksi: Membuat Notification Service yang terpicu saat Admin melakukan updateStatus.
- Fitur: Mengirimkan Push Notification ke perangkat User menggunakan Firebase Cloud
  Messaging (FCM).
  - Contoh: "Laporan Anda mengenai 'Lubang Jalan' telah selesai diproses!"

Fase 4: Manajemen Data & Ekspor (Excel/CSV)
Memudahkan Admin untuk melakukan rekapitulasi data bulanan.

- Aksi: Menambahkan library csv atau excel ke dalam proyek.
- Fitur: Tombol "Unduh Laporan (CSV)" di layar Admin. Fitur ini akan mengambil seluruh data dari Firestore dan mengubahnya menjadi file yang bisa dibuka di Excel.

Fase 5: Validasi & Security Rules
Memastikan keamanan data agar User biasa tidak bisa menembus fungsi Admin.

- Aksi: Memperbarui Firestore Security Rules untuk memverifikasi bahwa operasi updateStatus hanya bisa dilakukan jika request.auth.token.role == 'admin' atau mengecek dokumen di collection users.

---

Estimasi Urutan Kerja (Teknis):

1.  Update Model: Menambah field rejectionReason di ReportDto dan Report.
2.  UI Manajemen Laporan: Membuat tampilan list yang lebih informatif (menampilkan foto
    ImageKit versi thumbnail).
3.  Logika Status: Membuat fungsi changeStatusWithReason() di ViewModel.
4.  Sistem Notifikasi: Integrasi fungsi kirim pesan FCM di sisi klien/admin.
5.  Fitur Ekspor: Implementasi fungsi exportToExcel() di AllReportsViewModel.

Apakah rencana ini sudah sesuai dengan ekspektasi Anda? Jika ya, saya akan mulai dari Fase 1
dan 2 (UI kontras & Alasan Penolakan).

