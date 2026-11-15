/// Model untuk fitur Super App Jargon GO: beranda, Panic Button, dan
/// Pemberkasan.
///
/// Model absensi & kios tetap di `models.dart`.
library;

// =====================================================================
// Beranda
// =====================================================================

class HomeSummary {
  const HomeSummary({
    required this.greeting,
    required this.roleLabel,
    required this.students,
    this.school,
    required this.availableMenus,
  });

  final String greeting;
  final String roleLabel;
  final List<StudentTodayCard> students;
  final SchoolTodayCard? school;



  /// Menu yang boleh ditampilkan, ditentukan server dari izin akun.
  ///
  /// Aplikasi TIDAK menyimpulkan sendiri dari peran: menambah peran baru di
  /// dashboard tidak boleh menuntut rilis aplikasi baru.
  final List<String> availableMenus;



  bool hasMenu(String key) => availableMenus.contains(key);

  factory HomeSummary.fromJson(Map<String, dynamic> j) => HomeSummary(
    greeting: j['greeting'] as String? ?? 'Selamat datang',
    roleLabel: j['role_label'] as String? ?? 'Pengguna',
    // Bawaan false: versi server lama tidak mengirim penanda ini, dan
    // menampilkan tombol penanganan yang pasti ditolak lebih buruk daripada
    // tidak menampilkannya.
    students: (j['students'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(StudentTodayCard.fromJson)
        .toList(),
    school: j['school'] is Map<String, dynamic>
        ? SchoolTodayCard.fromJson(j['school'] as Map<String, dynamic>)
        : null,
    availableMenus: (j['available_menus'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList(),
  );
}

class StudentTodayCard {
  const StudentTodayCard({
    required this.studentId,
    required this.fullName,
    this.classroomName,
    required this.schoolName,
    required this.relation,
    required this.todayStatus,
    this.checkInTime,
    this.checkOutTime,
    required this.lateMinutes,
    required this.monthPresent,
    required this.monthLate,
    required this.monthAbsent,
  });

  final String studentId;
  final String fullName;
  final String? classroomName;
  final String schoolName;

  /// `diri_sendiri` untuk akun siswa; `ayah`/`ibu`/`wali` untuk orang tua.
  final String relation;

  /// `hadir`, `terlambat`, ..., atau `belum_absen` bila belum discan sama
  /// sekali — berbeda dari `alfa` yang sudah ditetapkan sistem.
  final String todayStatus;
  final String? checkInTime;
  final String? checkOutTime;
  final int lateMinutes;

  final int monthPresent;
  final int monthLate;
  final int monthAbsent;

  bool get isSelf => relation == 'diri_sendiri';

  factory StudentTodayCard.fromJson(Map<String, dynamic> j) => StudentTodayCard(
    studentId: j['student_id'] as String,
    fullName: j['full_name'] as String? ?? '-',
    classroomName: j['classroom_name'] as String?,
    schoolName: j['school_name'] as String? ?? '-',
    relation: j['relation'] as String? ?? 'diri_sendiri',
    todayStatus: j['today_status'] as String? ?? 'belum_absen',
    checkInTime: j['check_in_time'] as String?,
    checkOutTime: j['check_out_time'] as String?,
    lateMinutes: (j['late_minutes'] as num?)?.toInt() ?? 0,
    monthPresent: (j['month_present'] as num?)?.toInt() ?? 0,
    monthLate: (j['month_late'] as num?)?.toInt() ?? 0,
    monthAbsent: (j['month_absent'] as num?)?.toInt() ?? 0,
  );
}

class SchoolTodayCard {
  const SchoolTodayCard({
    required this.schoolId,
    required this.schoolName,
    required this.totalStudents,
    required this.hadir,
    required this.terlambat,
    required this.belumAbsen,
    required this.rate,
  });

  final String schoolId;
  final String schoolName;
  final int totalStudents;
  final int hadir;
  final int terlambat;
  final int belumAbsen;
  final double rate;

  factory SchoolTodayCard.fromJson(Map<String, dynamic> j) => SchoolTodayCard(
    schoolId: j['school_id'] as String,
    schoolName: j['school_name'] as String? ?? '-',
    totalStudents: (j['total_students'] as num?)?.toInt() ?? 0,
    hadir: (j['hadir'] as num?)?.toInt() ?? 0,
    terlambat: (j['terlambat'] as num?)?.toInt() ?? 0,
    belumAbsen: (j['belum_absen'] as num?)?.toInt() ?? 0,
    rate: (j['rate'] as num?)?.toDouble() ?? 0,
  );
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String kind;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  static AppNotification fromJson(Map<String, dynamic> j) => AppNotification(
    id: j['id'] as String? ?? '',
    kind: j['kind'] as String? ?? '',
    title: j['title'] as String? ?? '',
    body: j['body'] as String? ?? '',
    isRead: j['is_read'] as bool? ?? false,
    createdAt:
        DateTime.tryParse(j['created_at'] as String? ?? '')?.toLocal() ??
        DateTime.now(),
  );
}

class NotificationList {
  const NotificationList({required this.unread, required this.items});

  final int unread;
  final List<AppNotification> items;

  static NotificationList fromJson(Map<String, dynamic> j) => NotificationList(
    unread: (j['unread'] as num?)?.toInt() ?? 0,
    items: ((j['items'] as List<dynamic>?) ?? const [])
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

// =====================================================================
// PKL
// =====================================================================

/// Penempatan PKL yang berlaku hari ini.
class PklPlacement {
  const PklPlacement({
    required this.placementId,
    required this.placeName,
    required this.placeAddress,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.startsOn,
    required this.endsOn,
    required this.daysLeft,
    required this.checkedIn,
    required this.checkedOut,
    this.checkInAfter,
    this.checkOutBefore,
  });

  final String placementId;
  final String placeName;
  final String placeAddress;

  /// Datang sebagai STRING dari server, bukan angka.
  ///
  /// Kolomnya NUMERIC(10,7) dan tidak punya padanan persis di JSON; double
  /// membulatkan digit terakhir, dan titik yang bergeser beberapa
  /// sentimeter pada peta terlihat seperti data yang salah. Diurai ke
  /// double hanya saat benar-benar dipakai menghitung.
  final String latitude;
  final String longitude;

  final int radiusMeters;
  final DateTime startsOn;
  final DateTime endsOn;

  /// Sisa hari termasuk hari ini. Nol berarti hari terakhir.
  final int daysLeft;

  final bool checkedIn;
  final bool checkedOut;

  final String? checkInAfter;
  final String? checkOutBefore;

  double get lat => double.tryParse(latitude) ?? 0;
  double get lon => double.tryParse(longitude) ?? 0;

  /// Keduanya sudah dilakukan hari ini.
  bool get selesaiHariIni => checkedIn && checkedOut;

  factory PklPlacement.fromJson(Map<String, dynamic> j) => PklPlacement(
    placementId: j['placement_id'] as String,
    placeName: j['place_name'] as String? ?? '-',
    placeAddress: j['place_address'] as String? ?? '-',
    latitude: '${j['latitude'] ?? 0}',
    longitude: '${j['longitude'] ?? 0}',
    radiusMeters: (j['radius_meters'] as num?)?.toInt() ?? 100,
    startsOn: DateTime.tryParse('${j['starts_on']}') ?? DateTime.now(),
    endsOn: DateTime.tryParse('${j['ends_on']}') ?? DateTime.now(),
    daysLeft: (j['days_left'] as num?)?.toInt() ?? 0,
    checkedIn: j['checked_in'] as bool? ?? false,
    checkedOut: j['checked_out'] as bool? ?? false,
    checkInAfter: j['check_in_after'] as String?,
    checkOutBefore: j['check_out_before'] as String?,
  );
}

/// Hasil satu kali absen PKL.
class PklCheckResult {
  const PklCheckResult({
    required this.kind,
    required this.recordedAt,
    required this.distanceMeters,
    required this.status,
  });

  final String kind;
  final DateTime recordedAt;
  final double distanceMeters;
  final String status;

  factory PklCheckResult.fromJson(Map<String, dynamic> j) => PklCheckResult(
    kind: j['kind'] as String? ?? '-',
    recordedAt: DateTime.tryParse('${j['recorded_at']}') ?? DateTime.now(),
    distanceMeters: (j['distance_meters'] as num?)?.toDouble() ?? 0,
    status: j['status'] as String? ?? 'hadir',
  );
}
