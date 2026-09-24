import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show TextInputFormatter;
import 'package:google_nav_bar/google_nav_bar.dart';

import 'clay_theme.dart';

/// Permukaan tanah liat dasar. Seluruh komponen lain dibangun dari sini.
///
/// Dua bayangan berlawanan arah itulah yang membuat bentuknya terbaca sebagai
/// permukaan lunak. Menghapus salah satunya akan mengembalikannya menjadi
/// kartu Material biasa.
class ClaySurface extends StatelessWidget {
  const ClaySurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.radius = ClayTheme.radius,
    this.color,
    this.depth = 1,
    this.sunken = false,
    this.onTap,
    this.width,
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? color;

  /// Ketebalan bayangan. >1 untuk elemen utama, <1 untuk elemen sekunder.
  final double depth;

  /// `true` menggambar permukaan yang tenggelam — dipakai untuk kotak isian
  /// dan elemen yang sedang aktif. Pada claymorphism, "tenggelam" adalah
  /// satu-satunya cara menunjukkan sesuatu tidak dapat ditekan lagi.
  final bool sunken;

  final VoidCallback? onTap;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final surface = color ?? ClayTheme.surface;

    final decoration = BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: sunken ? null : ClayTheme.raised(depth: depth),
      // Permukaan tenggelam ditiru dengan gradien gelap-ke-terang: Flutter
      // tidak punya inner shadow, dan gradien halus ini memberi kesan cekung
      // yang cukup meyakinkan tanpa menggambar manual di canvas.
      gradient: sunken
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                  ClayTheme.shadowDark.withValues(alpha: 0.10),
                  surface,
                ),
                surface,
              ],
            )
          : null,
      border: sunken
          ? Border.all(
              color: ClayTheme.shadowDark.withValues(alpha: 0.28),
              width: 1,
            )
          : null,
    );

    final body = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: decoration,
      child: child,
    );

    if (onTap == null) {
      return margin == null ? body : Padding(padding: margin!, child: body);
    }

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: _PressableClay(radius: radius, onTap: onTap!, child: body),
    );
  }
}

/// Membuat permukaan "tertekan" saat disentuh.
///
/// Umpan balik ini penting justru karena claymorphism tidak punya garis tepi:
/// tanpa perubahan kedalaman saat ditekan, pengguna tidak yakin sentuhannya
/// terbaca — dan akan menekan dua kali.
class _PressableClay extends StatefulWidget {
  const _PressableClay({
    required this.child,
    required this.onTap,
    required this.radius,
  });

  final Widget child;
  final VoidCallback onTap;
  final double radius;

  @override
  State<_PressableClay> createState() => _PressableClayState();
}

class _PressableClayState extends State<_PressableClay> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.975 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Kartu isi dengan judul opsional.
class ClayCard extends StatelessWidget {
  const ClayCard({
    super.key,
    required this.child,
    this.title,
    this.trailing,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.onTap,
  });

  final Widget child;
  final String? title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ClaySurface(
      padding: padding,
      margin: margin,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    title!,
                    style: TextStyle(
                      color: ClayTheme.textStrong,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    );
  }
}

/// Tombol utama bergaya clay.
class ClayButton extends StatelessWidget {
  const ClayButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
    this.textColor,
    this.expanded = true,
    this.busy = false,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final Color? textColor;
  final bool expanded;
  final bool busy;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    final bg = color ?? ClayTheme.primary;
    final fg = textColor ?? Colors.white;

    final content = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (busy)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: fg),
          )
        else if (icon != null) ...[
          Icon(icon, size: compact ? 17 : 19, color: fg),
          const SizedBox(width: 8),
        ],
        if (!busy)
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: compact ? 13.5 : 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
      ],
    );

    return Opacity(
      // Tombol nonaktif diredupkan, bukan diubah warnanya: mengganti warna
      // membuat pengguna mengira itu tombol yang berbeda.
      opacity: enabled ? 1 : 0.5,
      child: ClaySurface(
        onTap: enabled ? onPressed : null,
        color: bg,
        radius: ClayTheme.radiusPill,
        depth: 0.85,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? ClayTheme.sLg : ClayTheme.sXxl,
          vertical: compact ? ClayTheme.sMd : ClayTheme.sLg,
        ),
        // Tinggi minimum dipasang di sini, bukan diserahkan pada isi
        // tombolnya. Tombol berisi ikon saja dan tombol berisi teks panjang
        // menghasilkan tinggi berbeda, dan dua tombol bersebelahan yang
        // tingginya tidak sama langsung terlihat.
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: compact
                ? ClayTheme.tinggiTombolKecil - ClayTheme.sMd * 2
                : ClayTheme.tinggiTombol - ClayTheme.sLg * 2,
          ),
          child: Center(
            heightFactor: 1,
            widthFactor: expanded ? null : 1,
            child: content,
          ),
        ),
      ),
    );
  }
}

/// Tombol sekunder (permukaan terang, teks berwarna).
class ClayGhostButton extends StatelessWidget {
  const ClayGhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
    this.compact = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ClayButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      color: ClayTheme.surface,
      textColor: color ?? ClayTheme.primary,
      expanded: false,
      compact: compact,
    );
  }
}

/// Lencana status kecil.
class ClayBadge extends StatelessWidget {
  const ClayBadge({
    super.key,
    required this.label,
    required this.color,
    this.background,
    this.icon,
  });

  final String label;
  final Color color;
  final Color? background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(ClayTheme.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ikon dalam wadah clay bulat.
class ClayIcon extends StatelessWidget {
  const ClayIcon({
    super.key,
    required this.icon,
    this.color,
    this.background,
    this.size = 22,
    this.padding = 13,
  });

  final IconData icon;
  final Color? color;
  final Color? background;
  final double size;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: background ?? ClayTheme.primarySoft,
        borderRadius: BorderRadius.circular(ClayTheme.radiusSmall),
      ),
      child: Icon(icon, size: size, color: color ?? ClayTheme.primary),
    );
  }
}

/// Kotak isian dengan permukaan tenggelam.
class ClayField extends StatelessWidget {
  const ClayField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.icon,
    this.obscure = false,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.suffix,
    this.onSubmitted,
    this.onChanged,
    this.inputFormatters,
    this.textAlign = TextAlign.start,
    this.style,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? maxLength;
  final bool enabled;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign textAlign;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              label!,
              style: TextStyle(
                color: ClayTheme.textBody,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        ClaySurface(
          // TIDAK `sunken` lagi. Permukaan tenggelam adalah cara claymorphism
          // menandai isian, tetapi pada latar gelap efeknya hilang: kotaknya
          // sewarna kartu di sekelilingnya. Kotak TERANG yang dipakai
          // sebagai gantinya, karena itu isyarat "di sini bisa diketik" yang
          // sudah dikenal semua orang tanpa perlu dipelajari.
          color: ClayTheme.fieldFill,
          depth: 0.5,
          radius: ClayTheme.radiusSmall,
          padding: EdgeInsets.zero,
          child: Row(
            children: [
              if (icon != null)
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Icon(icon, size: 19, color: ClayTheme.fieldHint),
                ),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  maxLength: maxLength,
                  enabled: enabled,
                  textAlign: textAlign,
                  inputFormatters: inputFormatters,
                  onSubmitted: onSubmitted,
                  onChanged: onChanged,
                  // `fieldText`, BUKAN `textStrong`. Kotaknya sekarang
                  // terang, dan warna teks tema gelap di atasnya berarti
                  // teks terang di atas latar terang — isian yang tampak
                  // kosong padahal sudah diisi.
                  style:
                      style ??
                      const TextStyle(
                        color: ClayTheme.fieldText,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                  cursorColor: ClayTheme.primary,
                  decoration: InputDecoration(
                    hintText: hint,
                    // hintStyle diberikan di sini, tidak diwarisi dari tema:
                    // tema global menyetel hint untuk latar GELAP, dan nilai
                    // itu tenggelam di atas kotak terang.
                    hintStyle: const TextStyle(
                      color: ClayTheme.fieldHint,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    counterText: '',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: icon == null ? 20 : 12,
                      vertical: maxLines > 1 ? 16 : 16,
                    ),
                  ),
                ),
              ),
              if (suffix != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: suffix!,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Keadaan kosong yang ramah — dipakai di semua daftar.
class ClayEmpty extends StatelessWidget {
  const ClayEmpty({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClaySurface(
              radius: ClayTheme.radiusPill,
              padding: const EdgeInsets.all(28),
              child: Icon(icon, size: 40, color: ClayTheme.textMuted),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ClayTheme.textStrong,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ClayTheme.textMuted,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}

/// Bilah navigasi bawah bergaya clay.
/// Navigasi bawah bergaya pil.
///
/// Dibangun di atas `GNav` (paket google_nav_bar), sama dengan aplikasi
/// rujukan. Yang membedakan rasanya dari navigasi biasa adalah label yang
/// disembunyikan pada tab tidak terpilih lalu MELEBAR saat dipilih, dengan
/// kurva easeOutCubic 420 ms dan getar halus. Versi buatan sendiri
/// sebelumnya menampilkan seluruh label sekaligus dan beranimasi 180 ms,
/// sehingga terasa jauh lebih kaku.
///
/// Wadahnya tetap `ClaySurface` supaya batangnya mengambang sebagai
/// permukaan tanah liat; hanya isi batangnya yang berasal dari paket.
class ClayNavBar extends StatelessWidget {
  const ClayNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelected,
  });

  final List<ClayNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ClaySurface(
          radius: ClayTheme.radiusPill,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: GNav(
            selectedIndex: currentIndex,
            onTabChange: onSelected,
            gap: 7,
            haptic: true,
            curve: Curves.easeOutCubic,
            duration: const Duration(milliseconds: 420),
            tabBorderRadius: ClayTheme.radiusPill,
            backgroundColor: Colors.transparent,
            color: ClayTheme.textMuted,
            activeColor: ClayTheme.primary,
            tabBackgroundColor: ClayTheme.primarySoft,
            iconSize: 21,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            textStyle: TextStyle(
              color: ClayTheme.primary,
              fontFamily: ClayTheme.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            tabs: [
              for (var i = 0; i < items.length; i++)
                _tombol(items[i], selected: i == currentIndex),
            ],
          ),
        ),
      ),
    );
  }

  /// GNav tidak mengenal lencana maupun ikon versi terpilih, jadi keduanya
  /// digambar lewat `leading` — satu-satunya celah yang disediakan paket
  /// untuk mengganti ikon bawaannya.
  GButton _tombol(ClayNavItem item, {required bool selected}) {
    return GButton(
      icon: item.icon,
      text: item.label,
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            selected ? item.activeIcon : item.icon,
            size: 21,
            color: selected ? ClayTheme.primary : ClayTheme.textMuted,
          ),
          // Lencana jumlah: satu-satunya cara pengguna tahu ada tindak
          // lanjut baru tanpa membuka tabnya.
          if (item.badge > 0)
            Positioned(
              right: -7,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: ClayTheme.danger,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  item.badge > 9 ? '9+' : '${item.badge}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ClayNavItem {
  const ClayNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badge = 0,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badge;
}

/// Menampilkan pesan galat dengan gaya yang sama di seluruh aplikasi.
void showClaySnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        // Latar netral diambil dari tema, BUKAN dari `ClayTheme.textStrong`.
        // Pada palet gelap warna itu hampir putih, sehingga teksnya menjadi
        // putih di atas putih — pesan galat yang tidak terbaca adalah
        // kegagalan yang lebih buruk daripada tidak ada pesan sama sekali.
        backgroundColor: error ? ClayTheme.danger : ClayTheme.snackBg,
        duration: Duration(seconds: error ? 5 : 3),
      ),
    );
}

/// Membatasi lebar isi pada layar lebar.
///
/// Aplikasi ini dirancang untuk ponsel. Dibentangkan penuh di tablet 10 inci,
/// satu baris teks menjadi 900 piksel — jauh melewati panjang baris yang
/// nyaman dibaca, dan kartu absensi berubah menjadi pita tipis melintang.
///
/// TIDAK dipasang di akar aplikasi, melainkan per layar. Layar kios absensi
/// justru membutuhkan lebar penuh untuk pratinjau kamera; membatasi semuanya
/// dari satu tempat akan mengecilkan kameranya juga.
class ClayConstrained extends StatelessWidget {
  const ClayConstrained({super.key, required this.child, this.maxWidth = 560});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
