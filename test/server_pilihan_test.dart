import 'package:flutter_test/flutter_test.dart';
import 'package:jargon_go/core/config.dart';

void main() {
  test('bawaan build release sama dengan server pertama di daftar', () {
    // Keduanya ditulis terpisah karena `const` tidak dapat membaca properti
    // dari daftar const. Uji ini yang menjaganya tetap sejalan: bila
    // daftarnya diubah tanpa mengubah bawaannya, APK rilis akan menunjuk
    // server yang tidak ada lagi di pilihan mana pun — dan gejalanya hanya
    // "tidak dapat menghubungi server", yang tidak menunjuk ke penyebabnya.
    expect(AppConfig.productionApiBaseUrl, AppConfig.serverPilihan.first.url);
  });

  test('tidak ada URL yang berakhir dengan garis miring', () {
    // Penggabungan dengan path menghasilkan `//v1/...`, yang menjadi 404
    // pada sebagian reverse proxy.
    for (final s in AppConfig.serverPilihan) {
      expect(
        s.url.endsWith('/'),
        isFalse,
        reason: '${s.nama} berakhir dengan garis miring',
      );
    }
  });

  test('setiap URL memakai https', () {
    // Aplikasi mengirim NIK, NISN, dan foto bukti absensi. Satu pilihan
    // http di daftar ini membuat semuanya melintas tanpa enkripsi tanpa
    // ada yang menyadarinya.
    for (final s in AppConfig.serverPilihan) {
      expect(s.url.startsWith('https://'), isTrue, reason: s.nama);
    }
  });

  test('tidak ada URL ganda', () {
    final url = AppConfig.serverPilihan.map((s) => s.url).toSet();
    expect(url.length, AppConfig.serverPilihan.length);
  });
}
