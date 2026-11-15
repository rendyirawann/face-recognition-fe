import 'package:flutter_test/flutter_test.dart';
import 'package:jargon_kiosk/main.dart';

void main() {
  group('Alamat halaman kios', () {
    test('kedua halaman dibangun dari satu alamat dasar', () {
      // Alamat dasar hanya ditulis di satu tempat. Menyalinnya ke tiap
      // halaman berarti suatu saat salah satunya tertinggal menunjuk
      // server lama, dan gejalanya hanya "tidak dapat menghubungi server".
      for (final h in Halaman.values) {
        expect(h.url(), startsWith(kBaseUrl));
      }
    });

    test('path absensi dan pendaftaran berbeda', () {
      expect(Halaman.absensi.path, isNot(Halaman.pendaftaran.path));
    });

    test('alamat dasar tidak berakhiran garis miring', () {
      // Penggabungan dengan path akan menghasilkan `//admin/...`, yang
      // pada sebagian reverse proxy menjadi 404.
      expect(kBaseUrl.endsWith('/'), isFalse);
    });

    test('alamat dasar memakai https', () {
      // getUserMedia hanya berjalan pada konteks aman. Di atas http,
      // kamera ditolak browser tanpa pesan yang jelas.
      expect(kBaseUrl.startsWith('https://'), isTrue);
    });

    test('path diawali garis miring agar tidak menelan segmen alamat', () {
      for (final h in Halaman.values) {
        expect(h.path.startsWith('/'), isTrue, reason: h.judul);
      }
    });
  });
}
