/// Daftar terpusat alamat API.
///
/// Path dikumpulkan di sini supaya kenaikan versi atau perubahan endpoint
/// cukup disunting di satu tempat; yang terlewat hanya ketahuan sebagai 404
/// di tangan pengguna.
///
/// Alamat servernya sendiri ada di [ApiConfig.baseUrl] dan dapat diubah saat
/// aplikasi berjalan.
library;

class ApiRoutes {
  const ApiRoutes._();

  /// Awalan versi API. Ubah di sini bila server naik versi.
  static const String prefix = '/v1';

  // =================================================================
  // Kesehatan server (tanpa autentikasi)
  // =================================================================

  /// Dipakai layar Alamat Server untuk menguji koneksi sebelum disimpan.
  static const String health = '/health';

  // =================================================================
  // Autentikasi
  // =================================================================

  static const String login = '$prefix/auth/login';
  static const String logout = '$prefix/auth/logout';
  static const String refresh = '$prefix/auth/refresh';

  // =================================================================
  // Jargon GO — data milik pengguna
  // =================================================================

  static const String home = '$prefix/me/home';
  static const String myAttendance = '$prefix/me/attendance';

  static String myRecap(String studentId) =>
      '$prefix/me/attendance/$studentId/recap';

  static const String myNotifications = '$prefix/me/notifications';
  static const String myNotificationsRead = '$prefix/me/notifications/read';

  // =================================================================
  // Absensi (pemantauan guru & kepala sekolah)
  // =================================================================

  static const String attendances = '$prefix/attendances';
  static const String attendanceSummary = '$prefix/attendances/summary';
  static const String attendanceByClassroom =
      '$prefix/attendances/by-classroom';
  static const String attendanceManual = '$prefix/attendances/manual';

  // =================================================================
  // Panic Button
  // =================================================================

  static const String panicCategories = '$prefix/panic/categories';
  static const String panicReports = '$prefix/panic/reports';

  static String panicReport(String id) => '$panicReports/$id';

  static String panicSupport(String id) => '$panicReports/$id/support';

  static String panicComments(String id) => '$panicReports/$id/comments';

  // =================================================================
  // Pemberkasan
  // =================================================================

  static const String documentTypes = '$prefix/documents/types';
  static const String submissions = '$prefix/documents/submissions';

  static String submission(String id) => '$submissions/$id';

  static String submissionFiles(String id) => '$submissions/$id/files';

  static String submitSubmission(String id) => '$submissions/$id/submit';

  static String documentFile(String fileId) =>
      '$prefix/documents/files/$fileId';

  // =================================================================
  // Perangkat kios (tablet sekolah)
  // =================================================================

  static const String devicePair = '$prefix/devices/pair';
  static const String kioskRecognize = '$prefix/kiosk/recognize';
  static const String kioskHeartbeat = '$prefix/kiosk/heartbeat';
  static const String kioskRoster = '$prefix/kiosk/roster';

  static String kioskEnrollFace(String studentId) =>
      '$prefix/kiosk/students/$studentId/face';

  // Aturan kredensial per endpoint.
  //
  // Ditaruh bersama daftar path supaya menambah endpoint baru berarti
  // menetapkan kredensialnya pada saat yang sama.

  /// Endpoint yang memakai `Authorization: Device <token>` (tablet kios).
  static bool needsDeviceToken(String path) => path.startsWith('$prefix/kiosk');

  /// Endpoint yang tidak boleh membawa kredensial.
  ///
  /// `devices/pair` dan `auth/login` sedang meminta kredensial, `/health`
  /// dipanggil sebelum ada sesi, dan `auth/refresh` memeriksa kredensialnya
  /// dari body — access token yang dibawa justru yang baru kedaluwarsa.
  static bool needsNoCredential(String path) =>
      path.startsWith(devicePair) ||
      path.startsWith(login) ||
      path.startsWith(refresh) ||
      path.startsWith(health);
}
