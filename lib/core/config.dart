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
      'https://beoulve-dev.biz.id/jargon-be';

  /// Wajib sama dengan `FACE_MODEL_VERSION` di server. Embedding dari versi
  /// model berbeda tidak sebanding, dan server menolaknya.
  static const String faceModelVersion = String.fromEnvironment(
    'FACE_MODEL_VERSION',
    defaultValue: 'mobilefacenet-v1',
  );

  /// Dimensi vektor embedding (MobileFaceNet = 512).
  static const int embeddingDim = int.fromEnvironment(
    'FACE_EMBEDDING_DIM',
    defaultValue: 512,
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
