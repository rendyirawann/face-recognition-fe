import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../failure.dart';
import 'clay_theme.dart';
import 'clay_widgets.dart';

/// Tampilan galat yang memberi tahu APA YANG HARUS DILAKUKAN.
///
/// Sebelumnya setiap layar menampilkan `e.message` apa adanya lewat
/// `ClayEmpty`. Pesan dari server memang sudah berbahasa Indonesia, tetapi
/// ia menjelaskan APA YANG TERJADI, bukan apa yang bisa dikerjakan
/// penggunanya. "Gagal menghubungi server" benar, dan tidak berguna bagi
/// siswa yang memegang ponsel di tempat PKL.
///
/// Kelas ini memetakan jenis kegagalan ke satu kalimat tindakan. Pemetaan
/// ada DI SATU TEMPAT supaya tiga belas layar tidak masing-masing menebak
/// kalimatnya sendiri dan menghasilkan tiga belas gaya berbeda.
class ClayError extends StatelessWidget {
  const ClayError({super.key, required this.failure, this.onRetry});

  final ApiFailure failure;
  final VoidCallback? onRetry;

  /// (ikon, judul, saran tindakan)
  (IconData, String, String) get _tampilan {
    if (failure.isNetwork) {
      return (
        Icons.wifi_off_rounded,
        'Tidak ada koneksi',
        'Periksa sambungan internet Anda, lalu tarik layar ke bawah untuk '
            'memuat ulang. Absensi yang sudah tercatat tidak hilang.',
      );
    }

    return switch (failure.statusCode) {
      401 => (
        Icons.lock_clock_rounded,
        'Sesi Anda berakhir',
        'Masuk kembali untuk melanjutkan. Ini terjadi bila aplikasi lama '
            'tidak dibuka, atau kata sandi Anda baru diganti.',
      ),
      403 => (Icons.no_accounts_rounded, 'Tidak dapat dibuka', failure.message),
      404 => (
        Icons.search_off_rounded,
        'Data tidak ditemukan',
        'Data yang Anda cari tidak ada lagi, atau berada di luar cakupan '
            'akun Anda.',
      ),
      409 => (
        Icons.done_all_rounded,
        'Sudah pernah dilakukan',
        failure.message,
      ),
      422 => (Icons.edit_note_rounded, 'Isian belum lengkap', failure.message),
      429 => (
        Icons.hourglass_top_rounded,
        'Terlalu sering',
        'Tunggu sekitar satu menit, lalu coba lagi.',
      ),
      // 5xx: kegagalan di sisi server. Pengguna tidak dapat berbuat apa pun
      // selain mencoba lagi, dan mengatakannya apa adanya lebih jujur
      // daripada menyuruhnya memeriksa isian yang sudah benar.
      int c when c >= 500 => (
        Icons.cloud_off_rounded,
        'Server sedang bermasalah',
        'Ini bukan kesalahan Anda. Coba lagi beberapa saat; bila terus '
            'berulang, laporkan ke operator sekolah.',
      ),
      _ => (Icons.error_outline_rounded, 'Terjadi kesalahan', failure.message),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (ikon, judul, saran) = _tampilan;

    return ClayEmpty(
      icon: ikon,
      title: judul,
      message: saran,
      action: onRetry == null
          ? null
          : ClayButton(
              label: 'Coba lagi',
              icon: Icons.refresh_rounded,
              expanded: false,
              onPressed: onRetry,
            ),
    );
  }
}

/// Layar pengganti saat SATU widget gagal digambar.
///
/// MENGAPA PERLU
///
/// Pada build rilis, widget yang melempar galat menghasilkan area ABU-ABU
/// KOSONG — tanpa pesan, tanpa petunjuk. Pengguna melihat sebagian layar
/// hilang dan menyimpulkan aplikasinya rusak total, padahal bagian lain
/// masih bekerja.
///
/// Rincian teknisnya hanya ditampilkan pada build debug. Di tangan siswa,
/// jejak tumpukan Dart tidak membantu siapa pun dan justru dapat
/// membocorkan nama berkas dan struktur internal.
///
/// Dipasang sekali di `main()`:
///
///     ErrorWidget.builder = (d) => ClayErrorWidget(detail: d);
class ClayErrorWidget extends StatelessWidget {
  const ClayErrorWidget({super.key, required this.detail});

  final FlutterErrorDetails detail;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ClayTheme.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(ClayTheme.sXxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.broken_image_rounded,
                size: ClayTheme.iconIllustration,
                color: ClayTheme.warning,
              ),
              const SizedBox(height: ClayTheme.sLg),
              Text(
                'Bagian ini gagal ditampilkan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: ClayTheme.textStrong,
                ),
              ),
              const SizedBox(height: ClayTheme.sSm),
              Text(
                'Bagian lain aplikasi masih dapat dipakai. Tutup lalu buka '
                'kembali halaman ini.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: ClayTheme.textMuted,
                  height: 1.5,
                ),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: ClayTheme.sLg),
                Text(
                  detail.exceptionAsString(),
                  textAlign: TextAlign.center,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: ClayTheme.danger,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
