import 'package:jargon_go/core/api_config.dart';
import 'package:jargon_go/core/config.dart';
import 'package:jargon_go/core/api_routes.dart';
import 'package:jargon_go/data/jargon_models.dart';
import 'package:jargon_go/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pengujian unit untuk logika yang paling berkonsekuensi di sisi klien:
/// normalisasi vektor (menentukan apakah pencocokan wajah bisa dipercaya) dan
/// pembacaan respons API (menentukan apa yang dilihat siswa di layar).
void main() {
  group('RecognizeResult', () {
    test('membaca absensi masuk beserta jam lokal', () {
      final r = RecognizeResult.fromJson({
        'matched': true,
        'action': 'checked_in',
        'message': 'Selamat pagi, Budi. Absen berhasil!',
        'student': {
          'id': 'a1',
          'full_name': 'Budi Santoso',
          'nis': '12345',
          'classroom_name': 'X IPA 1',
        },
        'attendance': {
          'status': 'hadir',
          'check_in_at': '2026-08-14T00:20:00Z',
          'late_minutes': 0,
        },
      });

      expect(r.action, RecognizeAction.checkedIn);
      expect(r.action.isSuccess, isTrue);
      expect(r.student?.fullName, 'Budi Santoso');
      expect(r.status, 'hadir');
      // 00:20 UTC = 07:20 WIB.
      expect(r.checkInTime, isNotNull);
    });

    test('aksi tak dikenal diperlakukan sebagai ditolak, bukan crash', () {
      final r = RecognizeResult.fromJson({
        'matched': false,
        'action': 'sesuatu_yang_baru',
        'message': 'x',
      });
      expect(r.action, RecognizeAction.rejected);
    });

    test('hasil antrean offline ditandai netral, bukan gagal', () {
      final r = RecognizeResult.queued();
      expect(r.action, RecognizeAction.queuedOffline);
      expect(r.action.isNeutral, isTrue);
      expect(r.action.isSuccess, isFalse);
    });

    test('respons tanpa data absensi tidak menghasilkan galat', () {
      final r = RecognizeResult.fromJson({
        'matched': false,
        'action': 'no_match',
        'message': 'Wajah tidak dikenali.',
      });
      expect(r.checkInTime, isNull);
      expect(r.lateMinutes, 0);
      expect(r.student, isNull);
    });
  });

  group('UserProfile', () {
    test('superadmin memiliki semua izin', () {
      final u = UserProfile.fromJson({
        'id': 'u1',
        'name': 'Super',
        'username': 'superadmin',
        'role_label': 'Superadmin',
        'roles': ['superadmin'],
        'permissions': <String>[],
      });
      expect(u.can('override_attendance'), isTrue);
      expect(u.roleLabel, 'Superadmin');
    });

    test('guru hanya memiliki izin yang diberikan', () {
      final u = UserProfile.fromJson({
        'id': 'u2',
        'name': 'Budi',
        'username': 'budi',
        'school_id': 's1',
        'role_label': 'Guru',
        'roles': ['guru'],
        'permissions': ['view_attendance'],
      });
      expect(u.can('view_attendance'), isTrue);
      expect(u.can('delete_student'), isFalse);
      expect(u.roleLabel, 'Guru');
    });

    test('label peran berasal dari server, bukan dipetakan di aplikasi', () {
      // Menambah peran baru di dashboard tidak boleh menuntut rilis aplikasi
      // baru, jadi labelnya dikirim server apa adanya.
      final u = UserProfile.fromJson({
        'id': 'u3',
        'name': 'Sari',
        'username': 'sari',
        'role_label': 'Petugas Pengaduan',
        'roles': ['petugas_pengaduan'],
        'permissions': ['view_panic_feed'],
      });
      expect(u.roleLabel, 'Petugas Pengaduan');
    });

    test('akun tanpa role_label tidak menebak-nebak', () {
      final u = UserProfile.fromJson({
        'id': 'u4',
        'name': 'X',
        'username': 'x',
        'roles': ['peran_baru'],
        'permissions': <String>[],
      });
      expect(u.roleLabel, 'Pengguna');
    });
  });

  group('Cakupan akun siswa & orang tua', () {
    UserProfile parse(Map<String, dynamic> extra) => UserProfile.fromJson({
          'id': 'u1',
          'name': 'Uji',
          'username': 'uji',
          'role_label': 'Uji',
          'permissions': <String>[],
          ...extra,
        });

    test('akun siswa tertaut ke dirinya sendiri', () {
      final u = parse({
        'roles': ['siswa'],
        'identity_type': 'nisn',
        'identity_number': '0061234567',
        'students': [
          {
            'id': 's1',
            'full_name': 'Budi Santoso',
            'school_id': 'sc1',
            'school_name': 'SMA N 1 Medan',
            'relation': 'diri_sendiri',
          }
        ],
      });

      expect(u.isStudent, isTrue);
      expect(u.isStudentScoped, isTrue);
      expect(u.students.single.relation, 'diri_sendiri');
      expect(u.identityLabel, 'NISN');
    });

    test('orang tua dapat memiliki anak di sekolah berbeda', () {
      // Inilah alasan cakupan orang tua tidak diturunkan dari school_id.
      final u = parse({
        'roles': ['orang_tua'],
        'identity_type': 'nik',
        'identity_number': '1275010101900001',
        'students': [
          {
            'id': 's1',
            'full_name': 'Anak Satu',
            'school_id': 'sc1',
            'school_name': 'SMA N 1 Medan',
            'relation': 'ayah',
          },
          {
            'id': 's2',
            'full_name': 'Anak Dua',
            'school_id': 'sc2',
            'school_name': 'SMP N 3 Binjai',
            'relation': 'ayah',
          },
        ],
      });

      expect(u.isParent, isTrue);
      expect(u.students.length, 2);
      expect(
        u.students.map((s) => s.schoolId).toSet().length,
        2,
        reason: 'anak berada di dua sekolah berbeda',
      );
      expect(u.identityLabel, 'NIK');
    });

    test('guru tidak dibatasi pada siswa tertentu', () {
      final u = parse({
        'roles': ['guru'],
        'school_id': 'sc1',
        'permissions': ['view_attendance'],
      });
      expect(u.isStudentScoped, isFalse);
      expect(u.students, isEmpty);
    });
  });

  group('Beranda Jargon GO', () {
    test('menu ditentukan server, bukan disimpulkan dari peran', () {
      final s = HomeSummary.fromJson({
        'greeting': 'Selamat pagi, Budi',
        'role_label': 'Siswa',
        'students': <dynamic>[],
        'available_menus': ['absensi', 'face_recognition'],
      });

      expect(s.hasMenu('absensi'), isTrue);
      expect(s.hasMenu('face_recognition'), isTrue);
      // Menu yang tidak dikirim server tidak boleh muncul: inilah yang
      // menjaga aplikasi tidak menampilkan tab untuk modul yang sudah tidak ada.
      expect(s.hasMenu('pemberkasan'), isFalse);
    });

    test('siswa yang belum discan berbeda dari alfa', () {
      // "belum_absen" berarti belum ada pemindaian sama sekali; "alfa" berarti
      // sistem sudah menetapkan siswa tidak hadir. Menyamakan keduanya akan
      // membuat orang tua menerima kabar salah pada pagi hari.
      final card = StudentTodayCard.fromJson({
        'student_id': 's1',
        'full_name': 'Budi',
        'school_name': 'SMA N 1',
        'relation': 'diri_sendiri',
      });
      expect(card.todayStatus, 'belum_absen');
      expect(card.checkInTime, isNull);
      expect(card.isSelf, isTrue);
    });
  });

  group('AttendanceRow', () {
    test('membedakan id absensi dari id siswa', () {
      // Endpoint koreksi memakai student_id; menukarnya dengan id baris
      // absensi akan membuat koreksi diterapkan ke siswa yang salah.
      final row = AttendanceRow.fromJson({
        'id': 'attendance-1',
        'student_id': 'student-9',
        'student_name': 'Sri Wahyuni',
        'status': 'terlambat',
        'late_minutes': 7,
      });
      expect(row.id, 'attendance-1');
      expect(row.studentId, 'student-9');
      expect(row.statusLabel, 'Terlambat');
    });
  });

  group('Alamat server', () {
    test('skema http ditambahkan bila pengguna hanya mengetik IP:port', () {
      // Yang dibaca orang dari `ipconfig` adalah angka tanpa skema; menolaknya
      // hanya akan membuat setelan terasa rewel.
      expect(ApiConfig.normalize('192.168.1.10:8080'),
          'http://192.168.1.10:8080');
      expect(ApiConfig.normalize('https://api.contoh.id'),
          'https://api.contoh.id');
    });

    test('garis miring di ujung dibuang', () {
      // Tanpa ini, penggabungan dengan path endpoint menghasilkan `//v1/...`
      // yang pada sebagian reverse proxy menjadi 404.
      expect(ApiConfig.normalize('http://localhost:8080/'),
          'http://localhost:8080');
      expect(ApiConfig.normalize('http://localhost:8080///'),
          'http://localhost:8080');
    });

    test('alamat yang sudah memuat /v1 ditolak', () {
      // Kalau diterima, setiap request menjadi /v1/v1/... — galat 404 yang
      // sangat sulit dilacak dari sisi pengguna.
      expect(ApiConfig.validationError('http://localhost:8080/v1'), isNotNull);
      expect(ApiConfig.validationError('http://localhost:8080'), isNull);
    });

    test('awalan path diterima, karena backend bisa dipasang di subpath', () {
      // https://contoh.id/jargon-be adalah pemasangan yang wajar, dan
      // alamatnya memang harus memuat awalan itu. Dio menyambung baseUrl
      // dengan path endpoint sebagai teks, jadi hasilnya benar.
      expect(ApiConfig.validationError('https://beoulve-dev.biz.id/jargon-be'),
          isNull);
      expect(ApiConfig.normalize('https://beoulve-dev.biz.id/jargon-be/'),
          'https://beoulve-dev.biz.id/jargon-be');
    });

    test('alamat produksi tidak berakhiran garis miring', () {
      // Garis miring di ujung membuat penggabungan menghasilkan `//v1/...`,
      // yang pada sebagian reverse proxy menjadi 404.
      expect(AppConfig.productionApiBaseUrl, isNot(endsWith('/')));
      expect(AppConfig.productionApiBaseUrl, startsWith('https://'));
      // Awalan pathnya harus ikut, kalau tidak request menembak akar domain.
      expect(Uri.parse(AppConfig.productionApiBaseUrl).path, '/jargon-be');
    });

    test('masukan kosong kembali ke bawaan, bukan alamat kosong', () {
      expect(ApiConfig.normalize('   '), ApiConfig.defaultBaseUrl);
    });

    test('same-origin mati kecuali diaktifkan build container', () {
      // Build container memakai --dart-define=API_SAME_ORIGIN=true agar
      // aplikasi mengambil alamat API dari origin halamannya sendiri.
      // Di build lain bendera ini HARUS mati: kalau tidak, `flutter run`
      // di :5000 akan menembak dirinya sendiri, bukan API di :8080.
      expect(ApiConfig.sameOrigin, isFalse);
    });

    test('bawaan tanpa --dart-define memakai alamat loopback, bukan emulator',
        () {
      // Pengujian berjalan di VM (bukan web), jadi bawaannya alamat emulator
      // Android. Yang dijaga di sini: nilainya benar-benar DIPUTUSKAN di
      // ApiConfig. Sebelumnya AppConfig.apiBaseUrl punya nilai bawaan sendiri,
      // yang membuat cabang per-platform di ApiConfig tidak pernah tercapai —
      // dan debug web diam-diam menembak 10.0.2.2 yang tidak ada di browser.
      expect(AppConfig.apiBaseUrl, isEmpty,
          reason: 'nilai bawaan harus diputuskan ApiConfig, bukan AppConfig');
      expect(ApiConfig.defaultBaseUrl, 'http://10.0.2.2:8080');
    });
  });

  group('ApiRoutes', () {
    test('endpoint kios memakai kredensial perangkat, bukan JWT', () {
      // Salah jenis kredensial menghasilkan 401 yang membingungkan: token
      // ADA, hanya jenisnya yang keliru.
      expect(ApiRoutes.needsDeviceToken(ApiRoutes.kioskRecognize), isTrue);
      expect(ApiRoutes.needsDeviceToken(ApiRoutes.home), isFalse);
    });

    test('login, pairing, dan health tidak membawa kredensial', () {
      // Ketiganya justru sedang meminta kredensial atau dipanggil sebelum
      // ada sesi.
      expect(ApiRoutes.needsNoCredential(ApiRoutes.login), isTrue);
      expect(ApiRoutes.needsNoCredential(ApiRoutes.devicePair), isTrue);
      expect(ApiRoutes.needsNoCredential(ApiRoutes.health), isTrue);
      expect(ApiRoutes.needsNoCredential(ApiRoutes.myPkl), isFalse);
    });

    test('path bersarang dibangun dari path induknya', () {
      // Sehingga mengubah path induknya sekali ikut memindahkan seluruh
      // turunannya, bukan menyisakan satu yang tertinggal.
      expect(ApiRoutes.myPklAttendance, startsWith(ApiRoutes.myPkl));
    });
  });
}
