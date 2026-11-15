//! Jargon GO Kios — pembungkus tablet untuk halaman absensi wajah.
//!
//! MENGAPA WEBVIEW, BUKAN PENGENALAN WAJAH DI DALAM APLIKASI
//!
//! Yang menghitung angka wajah adalah face-api.js di dalam halaman
//! dashboard. Angka dari model yang berbeda tidak dapat dibandingkan —
//! mendaftarkan wajah dengan satu model lalu mencocokkannya dengan model
//! lain tidak menurunkan akurasi, melainkan menghasilkan identifikasi
//! acak. Dengan membuka halaman yang sama dengan yang dipakai operator di
//! komputer, tablet ini dijamin memakai model yang sama persis.
//!
//! Konsekuensinya aplikasi ini tidak memuat kamera, ML, maupun model apa
//! pun. Yang dibawanya hanya WebView.
//!
//! MENGAPA PROYEK TERPISAH DARI APLIKASI SISWA
//!
//! Flutter menyertakan pustaka native setiap paket di pubspec, dipakai
//! atau tidak. Bila kios ini hanya menjadi entry point kedua di proyek
//! aplikasi siswa, APK-nya tetap membawa pustaka kamera dan GPS yang
//! tidak pernah disentuhnya.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

/// Alamat dashboard, diisi saat build:
///
///     flutter build apk --release \
///       --dart-define=BASE_URL=https://absensi.sekolah.id
const String kBaseUrl = String.fromEnvironment(
  'BASE_URL',
  defaultValue: 'https://hustlesync.my.id/jargon-be',
);

/// Dua halaman yang dibuka kios, keduanya milik dashboard.
enum Halaman {
  absensi('Absensi', '/admin/biometric/scan', Icons.center_focus_strong_rounded),
  pendaftaran('Pendaftaran Wajah', '/admin/biometric', Icons.person_add_alt_1_rounded);

  const Halaman(this.judul, this.path, this.ikon);

  final String judul;
  final String path;
  final IconData ikon;

  String url() => '$kBaseUrl$path';
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Layar penuh tanpa bilah status dan tombol navigasi. Tablet yang
  // ditinggal di depan kelas tidak boleh bisa ditutup dengan satu sentuhan
  // tak sengaja.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
  ]);

  runApp(const KiosApp());
}

class KiosApp extends StatelessWidget {
  const KiosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jargon GO Kios',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F3864),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const LayarKios(),
    );
  }
}

class LayarKios extends StatefulWidget {
  const LayarKios({super.key});

  @override
  State<LayarKios> createState() => _LayarKiosState();
}

class _LayarKiosState extends State<LayarKios> {
  late final WebViewController _web;
  Halaman _halaman = Halaman.absensi;
  bool _memuat = true;
  String? _galat;

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0E1526))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() {
            _memuat = true;
            _galat = null;
          }),
          onPageFinished: (_) => setState(() => _memuat = false),
          onWebResourceError: (e) {
            // Hanya galat halaman utamanya yang ditampilkan. Gambar atau
            // skrip yang gagal tidak boleh menutupi halaman absensi yang
            // sebenarnya sudah berjalan.
            // Nullable: platform yang tidak melaporkannya dianggap
            // galat halaman utama, karena menyembunyikan galat yang
            // sesungguhnya lebih buruk daripada menampilkannya.
            if (e.isForMainFrame == false) return;
            setState(() {
              _memuat = false;
              _galat = e.description;
            });
          },
          // Kios tidak boleh berpindah ke situs lain. Tautan keluar
          // dibiarkan tidak berfungsi, bukan dibuka — tablet di depan
          // kelas tanpa bilah alamat tidak punya cara kembali.
          onNavigationRequest: (req) => req.url.startsWith(kBaseUrl)
              ? NavigationDecision.navigate
              : NavigationDecision.prevent,
        ),
      );

    // Izin kamera untuk halaman: tanpa ini getUserMedia ditolak diam-diam
    // dan layar absensi hanya menampilkan kotak hitam.
    final platform = _web.platform;
    if (platform is AndroidWebViewController) {
      platform.setOnPlatformPermissionRequest(
        (request) => request.grant(),
      );
      platform.setMediaPlaybackRequiresUserGesture(false);
    }

    _web.loadRequest(Uri.parse(_halaman.url()));
  }

  void _buka(Halaman h) {
    if (h == _halaman) {
      _web.reload();
      return;
    }
    setState(() => _halaman = h);
    _web.loadRequest(Uri.parse(h.url()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1526),
      body: SafeArea(
        child: Column(
          children: [
            _BilahAtas(
              aktif: _halaman,
              onPilih: _buka,
              onMuatUlang: () => _web.reload(),
            ),
            Expanded(
              child: Stack(
                children: [
                  WebViewWidget(controller: _web),
                  if (_galat != null) _Galat(pesan: _galat!, onCoba: () => _web.reload()),
                  if (_memuat && _galat == null)
                    const LinearProgressIndicator(minHeight: 3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bilah tipis di atas: pemilih halaman dan tombol muat ulang.
///
/// Sengaja tidak memakai bilah navigasi bawaan browser. Yang dibutuhkan
/// petugas hanya dua halaman dan satu tombol muat ulang; alamat, riwayat,
/// dan tab justru menjadi jalan keluar yang tidak diinginkan.
class _BilahAtas extends StatelessWidget {
  const _BilahAtas({
    required this.aktif,
    required this.onPilih,
    required this.onMuatUlang,
  });

  final Halaman aktif;
  final ValueChanged<Halaman> onPilih;
  final VoidCallback onMuatUlang;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1F3864),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          for (final h in Halaman.values) ...[
            TextButton.icon(
              onPressed: () => onPilih(h),
              icon: Icon(h.ikon, size: 18),
              label: Text(h.judul),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: h == aktif ? Colors.white24 : Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
            const SizedBox(width: 6),
          ],
          const Spacer(),
          IconButton(
            onPressed: onMuatUlang,
            icon: const Icon(Icons.refresh_rounded),
            color: Colors.white70,
            tooltip: 'Muat ulang',
          ),
        ],
      ),
    );
  }
}

class _Galat extends StatelessWidget {
  const _Galat({required this.pesan, required this.onCoba});

  final String pesan;
  final VoidCallback onCoba;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0E1526),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.white38),
          const SizedBox(height: 16),
          const Text(
            'Tidak dapat menghubungi server',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(
            'Periksa sambungan Wi-Fi tablet ini, lalu coba lagi.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 6),
          Text(
            pesan,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onCoba,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }
}
