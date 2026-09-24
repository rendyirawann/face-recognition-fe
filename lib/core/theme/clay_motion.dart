import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

/// Animasi masuk untuk daftar.
///
/// MENGAPA BERTAHAP, BUKAN SEKALIGUS
///
/// Seluruh isi layar yang muncul dalam satu bingkai tidak memberi tahu mata
/// harus mulai membaca dari mana. Ketika barisnya masuk berurutan dengan
/// jeda pendek, urutan itu sendiri menjadi petunjuk arah baca — dan efeknya
/// hilang bila jedanya terlalu panjang, karena menunggu baris terakhir lebih
/// mengganggu daripada tidak ada animasi sama sekali. Karena itu 375 ms
/// untuk seluruh rangkaian, bukan per baris.
///
/// Pemakaian: bungkus daftarnya dengan [ClayAnimatedList], lalu bungkus tiap
/// itemnya dengan [ClayStaggered]. Keduanya harus berpasangan;
/// `AnimationConfiguration` tanpa `AnimationLimiter` di atasnya akan
/// mengulang animasi setiap kali daftar tergulir.
class ClayAnimatedList extends StatelessWidget {
  const ClayAnimatedList({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => AnimationLimiter(child: child);
}

/// Satu item daftar yang masuk dengan geser-naik dan pudar.
class ClayStaggered extends StatelessWidget {
  const ClayStaggered({
    super.key,
    required this.index,
    required this.child,
    this.horizontal = false,
  });

  final int index;
  final Widget child;

  /// Daftar mendatar bergeser dari kanan, bukan dari bawah.
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    return AnimationConfiguration.staggeredList(
      position: index,
      duration: const Duration(milliseconds: 375),
      child: SlideAnimation(
        verticalOffset: horizontal ? 0 : 28,
        horizontalOffset: horizontal ? 28 : 0,
        child: FadeInAnimation(child: child),
      ),
    );
  }
}
