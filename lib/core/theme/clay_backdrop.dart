import 'package:flutter/material.dart';

import 'clay_theme.dart';

/// Lapisan hias di belakang isi layar.
///
/// MENGAPA ADA
///
/// Pada mode terang, latar dan permukaan kartu hanya berselisih tipis
/// (#EFF1FA melawan #F6F8FE) — selisih itu memang disengaja, karena
/// claymorphism butuh latar sedikit lebih gelap agar bayangan terangnya
/// terbaca. Akibatnya layar yang penuh kartu terbaca sebagai bidang putih
/// datar, dan warna tema hanya muncul pada tombol.
///
/// Yang digambar di sini bukan pola, melainkan dua sapuan warna lebar yang
/// sangat samar: biru di kanan atas, teal di kiri bawah. Keduanya di bawah
/// 10% opasitas — cukup untuk memberi arah pada bidang kosong, tetapi tidak
/// cukup untuk mengganggu keterbacaan teks di atasnya.
///
/// Dilukis, bukan berupa gambar: berkas gambar harus disediakan dalam
/// beberapa kepadatan, ikut menambah besar APK, dan tidak dapat mengikuti
/// pergantian tema.
class ClayBackdrop extends StatelessWidget {
  const ClayBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(color: ClayTheme.background),
            child: CustomPaint(painter: _SapuanPainter(gelap: ClayTheme.gelap)),
          ),
        ),
        child,
      ],
    );
  }
}

class _SapuanPainter extends CustomPainter {
  const _SapuanPainter({required this.gelap});

  final bool gelap;

  @override
  void paint(Canvas canvas, Size size) {
    // Pada mode gelap sapuannya dibuat lebih redup lagi: latar gelap sudah
    // punya kedalaman sendiri, dan warna tambahan di atasnya cepat terlihat
    // seperti noda alih-alih cahaya.
    final kuat = gelap ? 0.055 : 0.085;

    void sapu(Offset pusat, double jari, Color warna, double opasitas) {
      final rect = Rect.fromCircle(center: pusat, radius: jari);
      canvas.drawCircle(
        pusat,
        jari,
        Paint()
          ..shader = RadialGradient(
            colors: [
              warna.withValues(alpha: opasitas),
              warna.withValues(alpha: 0),
            ],
            stops: const [0, 1],
          ).createShader(rect),
      );
    }

    // Kanan atas — di belakang bilah judul, tempat mata mendarat lebih dulu.
    sapu(
      Offset(size.width * 0.92, size.height * 0.02),
      size.width * 0.78,
      ClayTheme.primary,
      kuat,
    );

    // Kiri bawah — mengimbangi, dan jatuh di belakang navigasi mengambang.
    sapu(
      Offset(size.width * 0.04, size.height * 0.94),
      size.width * 0.82,
      ClayTheme.secondary,
      kuat * 0.85,
    );

    // Sapuan ketiga yang jauh lebih kecil di tengah kiri, supaya bidang
    // panjang yang digulir tidak kehilangan warna di bagian tengahnya.
    sapu(
      Offset(size.width * 0.06, size.height * 0.42),
      size.width * 0.5,
      ClayTheme.primary,
      kuat * 0.5,
    );
  }

  @override
  bool shouldRepaint(_SapuanPainter old) => old.gelap != gelap;
}
