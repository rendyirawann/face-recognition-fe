import 'offline_queue_memory.dart'
    if (dart.library.io) 'offline_queue_sqflite.dart';

/// Antrean absensi lokal untuk saat jaringan sekolah terputus.
///
/// Tanpa ini, siswa yang sudah datang tercatat alfa dan orang tuanya menerima
/// notifikasi yang salah ketika jaringan mati.
///
/// Yang disimpan hanya embedding, waktu tangkap, dan skor liveness — tidak
/// ada gambar, dan barisnya dihapus segera setelah server menerimanya.
///
/// Dua implementasi: SQLite di perangkat, dalam memori di web. Versi web
/// hilang saat halaman dimuat ulang, dan itu tidak masalah — mode kios butuh
/// kamera dan TFLite yang tidak ada di browser.
abstract class OfflineQueue {
  /// Batas umur antrean. Lebih lama dari ini, jam kedatangannya tidak lagi
  /// bisa dipertanggungjawabkan — lebih baik dikoreksi manual oleh guru.
  static const Duration maxAge = Duration(hours: 18);

  /// Batas jumlah baris agar penyimpanan tablet tidak habis bila jaringan
  /// mati berhari-hari.
  static const int maxRows = 5000;

  static Future<OfflineQueue> open() => openOfflineQueue();

  Future<void> close();

  /// Simpan satu pemindaian yang gagal terkirim.
  Future<void> enqueue(Map<String, dynamic> payload);

  /// Ambil batch tertua untuk dicoba kirim.
  ///
  /// Urutan tertua-dulu penting: jam masuk siswa harus tercatat sesuai
  /// urutan kedatangan sebenarnya.
  Future<List<PendingScan>> take({int limit});

  Future<void> remove(int id);

  Future<void> markFailed(int id, String error);

  Future<int> count();

  /// Buang baris kedaluwarsa dan yang melebihi kapasitas.
  ///
  /// Mengembalikan jumlah baris yang dibuang, supaya bisa dilaporkan ke
  /// operator alih-alih hilang tanpa jejak.
  Future<int> purgeStale();
}

class PendingScan {
  const PendingScan({
    required this.id,
    required this.payload,
    required this.capturedAt,
    required this.attempts,
  });

  final int id;
  final Map<String, dynamic> payload;
  final DateTime capturedAt;
  final int attempts;

  /// Sudah terlalu sering gagal — kemungkinan payload-nya sendiri bermasalah
  /// (mis. versi model tidak cocok), bukan jaringannya.
  bool get isExhausted => attempts >= 8;
}
