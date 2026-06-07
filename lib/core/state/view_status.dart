/// Status operasi async yang dipakai seluruh ViewModel SafeRoad.
///
/// Token bersama lintas modul (User, Auth, Admin, Additional) agar pola
/// state konsisten. Sebelumnya enum ini tinggal di `ui/auth/login` dan
/// diimpor lintas modul — kini dipindah ke `core/state` (audit §9.1).
enum ViewStatus { initial, loading, success, failure }
