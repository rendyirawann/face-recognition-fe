/// Konfigurasi build, diisi lewat `--dart-define`.
///
/// ```
/// flutter build apk --release \
///   --dart-define=API_BASE_URL=https://absensi.disdik.sumutprov.go.id \
///   --dart-define=FACE_MODEL_VERSION=faceapi-v1
/// ```
library;

class AppConfig {
  const AppConfig._();

  /// Alamat API dari `--dart-define`; kosong bila tidak diisi.
  ///
  /// Nilai bawaan ditentukan [ApiConfig.defaultBaseUrl] karena berbeda per
  /// platform. Pakai [ApiConfig.baseUrl] — pengguna dapat menimpanya lewat
  /// layar Alamat Server.
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Bawaan build release bila `API_BASE_URL` tidak diisi.
  ///
  /// Memuat awalan path `/jargon-be` karena backend dipasang di subpath.
  /// Tanpa garis miring di ujung: penggabungan menghasilkan `//v1/...` yang
  /// menjadi 404 pada sebagian reverse proxy.
  static const String productionApiBaseUrl =
      'https://hustlesync.my.id/jargon-be';

  /// Server yang dapat dipilih langsung dari layar login.
  ///
  /// MENGAPA DAFTAR, BUKAN SATU ALAMAT
  ///
  /// Sistem ini berjalan di lebih dari satu tempat sekaligus — satu untuk
  /// uji coba, satu lagi untuk demo — dan penguji berpindah di antaranya
  /// dalam satu hari. Menuntut mereka mengetik ulang URL lengkap setiap
  /// kali berpindah adalah undangan untuk salah ketik, dan salah ketik pada
  /// alamat server muncul sebagai "tidak dapat menghubungi server" yang
  /// tidak menunjuk ke penyebabnya.
  ///
  /// Yang PERTAMA menjadi bawaan build release. Mengetik alamat sendiri
  /// tetap bisa: daftar ini pintasan, bukan pembatasan.
  ///
  /// Tanpa garis miring di ujung — penggabungan dengan path menghasilkan
  /// `//v1/...` yang menjadi 404 pada sebagian reverse proxy.
  static const List<ServerPilihan> serverPilihan = [
    ServerPilihan(
      nama: 'HustleSync',
      url: 'https://hustlesync.my.id/jargon-be',
      keterangan: 'Server utama',
    ),
    ServerPilihan(
      nama: 'Beoulve Dev',
      url: 'https://beoulve-dev.biz.id/jargon-be',
      keterangan: 'Server pengembangan',
    ),
  ];

  /// Wajib sama dengan `FACE_MODEL_VERSION` di server. Embedding dari versi
  /// model berbeda tidak sebanding, dan server menolaknya.
  static const String faceModelVersion = String.fromEnvironment(
    'FACE_MODEL_VERSION',
    defaultValue: 'mobilefacenet-v1',
  );

  /// Dimensi vektor embedding.
  ///
  /// Wajib sama dengan kolom `face_embeddings.embedding` di server, yang
  /// bertipe `VECTOR(128)` sejak migrasi 0014. Nilai yang berbeda ditolak
  /// saat pairing, bukan dibiarkan menghasilkan embedding yang tidak
  /// sebanding.
  static const int embeddingDim = int.fromEnvironment(
    'FACE_EMBEDDING_DIM',
    defaultValue: 128,
  );

  /// Ukuran input model, sisi persegi dalam piksel.
  static const int modelInputSize = int.fromEnvironment(
    'FACE_MODEL_INPUT',
    defaultValue: 112,
  );

  /// Berkas model TFLite di dalam assets.
  static const String modelAsset = 'assets/models/mobilefacenet.tflite';

  /// Jeda minimum antara dua scan siswa yang sama. Penjaga sisi klien;
  /// server punya penjaganya sendiri.
  static const Duration scanCooldown = Duration(seconds: 8);

  static const Duration heartbeatInterval = Duration(minutes: 2);

  /// Seberapa sering antrean offline dicoba dikirim ulang.
  static const Duration syncInterval = Duration(seconds: 30);

  /// Batas waktu request. Pendek untuk jalur absensi: tablet lebih baik
  /// menyimpan ke antrean lokal daripada menahan siswa di depan kamera.
  static const Duration requestTimeout = Duration(seconds: 12);

  /// Skor liveness minimum sebelum embedding dikirim.
  static const double minLiveness = 0.5;

  /// Lebar minimum wajah relatif terhadap lebar frame. Wajah terlalu kecil
  /// menghasilkan embedding buruk.
  static const double minFaceWidthRatio = 0.22;

  /// Sudut kepala maksimum (derajat) yang masih diterima untuk absensi.
  static const double maxHeadAngle = 22.0;
}

/// Satu pilihan server siap pakai di layar login.
class ServerPilihan {
  const ServerPilihan({
    required this.nama,
    required this.url,
    required this.keterangan,
  });

  final String nama;
  final String url;
  final String keterangan;
}
