import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/failure.dart';
import '../../core/theme/clay_backdrop.dart';
import '../../core/theme/clay_loading.dart';
import '../../core/theme/clay_error.dart';
import '../../core/theme/clay_theme.dart';
import '../../core/theme/clay_widgets.dart';
import '../../data/jargon_models.dart';
import '../../providers.dart';

/// Absen dari tempat PKL.
///
/// URUTANNYA DISENGAJA: LOKASI DULU, BARU FOTO
///
/// Meminta foto lebih dulu berarti siswa memotret, menunggu unggahan, lalu
/// baru diberi tahu bahwa ia berada di luar radius — pekerjaan yang
/// terbuang dan pesan yang datang terlambat. Di sini jaraknya dihitung
/// dan ditampilkan SEBELUM tombol foto aktif, sehingga yang di luar radius
/// tahu sejak awal dan tidak sempat memotret sia-sia.
///
/// Perhitungan jarak di layar ini hanya untuk MEMBERI TAHU. Yang
/// memutuskan tetap server: ponsel dapat berbohong tentang lokasinya, dan
/// pemeriksaan di sisi klien tidak pernah menjadi penjaga.
class PklScreen extends ConsumerStatefulWidget {
  const PklScreen({super.key});

  @override
  ConsumerState<PklScreen> createState() => _PklScreenState();
}

class _PklScreenState extends ConsumerState<PklScreen> {
  final _picker = ImagePicker();

  PklPlacement? _pkl;
  bool _loading = true;
  ApiFailure? _error;

  Position? _posisi;
  String? _galatLokasi;
  bool _mencariLokasi = false;

  bool _mengirim = false;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pkl = await ref.read(repositoryProvider).pklPlacement();
      if (!mounted) return;
      setState(() {
        _pkl = pkl;
        _loading = false;
      });
      if (pkl != null) await _cariLokasi();
    } on ApiFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _cariLokasi() async {
    setState(() {
      _mencariLokasi = true;
      _galatLokasi = null;
    });

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw 'Layanan lokasi mati. Nyalakan GPS lalu coba lagi.';
      }

      var izin = await Geolocator.checkPermission();
      if (izin == LocationPermission.denied) {
        izin = await Geolocator.requestPermission();
      }
      if (izin == LocationPermission.deniedForever) {
        throw 'Izin lokasi ditolak permanen. Aktifkan dari Pengaturan aplikasi.';
      }
      if (izin == LocationPermission.denied) {
        throw 'Izin lokasi diperlukan untuk absen PKL.';
      }

      // `high`, bukan `medium` seperti kartu beranda. Di sini koordinatnya
      // dipakai memutuskan diterima atau ditolaknya absensi, jadi selisih
      // puluhan meter berarti sesuatu.
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      if (!mounted) return;
      setState(() {
        _posisi = p;
        _mencariLokasi = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _galatLokasi = e is String ? e : 'Gagal membaca lokasi. Coba lagi.';
        _mencariLokasi = false;
      });
    }
  }

  /// Jarak ke titik PKL, meter. Null bila lokasi belum terbaca.
  double? get _jarak {
    final p = _posisi;
    final k = _pkl;
    if (p == null || k == null) return null;
    return Geolocator.distanceBetween(p.latitude, p.longitude, k.lat, k.lon);
  }

  bool get _diDalamRadius {
    final j = _jarak;
    final k = _pkl;
    return j != null && k != null && j <= k.radiusMeters;
  }

  Future<void> _absen(String jenis) async {
    final k = _pkl;
    final p = _posisi;
    if (k == null || p == null) return;

    // Kamera, bukan galeri. Foto bukti yang boleh diambil dari galeri
    // bukan lagi bukti bahwa siswanya berada di sana hari ini.
    final XFile? foto = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      // Dikecilkan di perangkat lebih dulu. Server mengompresi lagi, tetapi
      // yang dihemat di sini adalah unggahannya: jaringan di tempat PKL
      // sering lebih buruk daripada di sekolah.
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 88,
    );
    if (foto == null || !mounted) return;

    setState(() => _mengirim = true);
    try {
      final bytes = await File(foto.path).readAsBytes();
      final hasil = await ref
          .read(repositoryProvider)
          .pklCheck(
            kind: jenis,
            latitude: p.latitude,
            longitude: p.longitude,
            accuracyMeters: p.accuracy,
            photoBytes: bytes,
          );

      if (!mounted) return;
      showClaySnack(
        context,
        'Absen $jenis tercatat ${hasil.status} '
        '(${hasil.distanceMeters.round()} m dari titik).',
      );
      await _muat();
    } on ApiFailure catch (e) {
      if (mounted) showClaySnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _mengirim = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClayBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Absensi PKL')),
        body: _loading
            ? const ClayBerandaSkeleton()
            : _error != null
            ? ClayError(failure: _error!, onRetry: _muat)
            : _pkl == null
            ? const ClayEmpty(
                icon: Icons.business_center_outlined,
                title: 'Anda tidak sedang PKL',
                message:
                    'Absensi Anda dilakukan di sekolah. Halaman ini hanya '
                    'untuk siswa yang sedang menjalani Praktik Kerja '
                    'Lapangan.',
              )
            : ClayRefresh(onRefresh: _muat, child: _isi(_pkl!)),
      ),
    );
  }

  Widget _isi(PklPlacement k) {
    final jarak = _jarak;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        ClayTheme.sXl,
        ClayTheme.sMd,
        ClayTheme.sXl,
        ClayTheme.sXxxl,
      ),
      children: [
        // --- Tempat PKL ---
        ClaySurface(
          padding: const EdgeInsets.all(ClayTheme.sXl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                k.placeName,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: ClayTheme.textStrong,
                ),
              ),
              const SizedBox(height: ClayTheme.sXs),
              Text(
                k.placeAddress,
                style: TextStyle(fontSize: 12.5, color: ClayTheme.textMuted),
              ),
              const SizedBox(height: ClayTheme.sLg),
              Row(
                children: [
                  ClayBadge(
                    label: 'radius ${k.radiusMeters} m',
                    color: ClayTheme.primary,
                  ),
                  const SizedBox(width: ClayTheme.sSm),
                  ClayBadge(
                    label: k.daysLeft == 0
                        ? 'hari terakhir'
                        : 'sisa ${k.daysLeft} hari',
                    color: k.daysLeft <= 3
                        ? ClayTheme.warning
                        : ClayTheme.success,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: ClayTheme.sLg),

        // --- Lokasi saat ini ---
        _KartuLokasi(
          mencari: _mencariLokasi,
          galat: _galatLokasi,
          jarak: jarak,
          radius: k.radiusMeters,
          akurasi: _posisi?.accuracy,
          onUlangi: _cariLokasi,
        ),

        const SizedBox(height: ClayTheme.sLg),

        // --- Tombol absen ---
        if (k.selesaiHariIni)
          ClaySurface(
            padding: const EdgeInsets.all(ClayTheme.sXl),
            color: ClayTheme.successSoft,
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: ClayTheme.success,
                  size: ClayTheme.iconIllustration,
                ),
                const SizedBox(width: ClayTheme.sMd),
                Expanded(
                  child: Text(
                    'Absen masuk dan pulang hari ini sudah lengkap.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ClayTheme.textStrong,
                    ),
                  ),
                ),
              ],
            ),
          )
        else ...[
          ClayButton(
            label: k.checkedIn ? 'Sudah absen masuk' : 'Absen Masuk',
            icon: Icons.login_rounded,
            busy: _mengirim,
            // Tombol mati bila di luar radius, dan alasannya sudah tertulis
            // di kartu lokasi di atasnya. Tombol yang bisa ditekan lalu
            // ditolak server membuat siswa memotret sia-sia.
            onPressed: (k.checkedIn || !_diDalamRadius || _mengirim)
                ? null
                : () => _absen('masuk'),
          ),
          const SizedBox(height: ClayTheme.sMd),
          ClayButton(
            label: k.checkedOut ? 'Sudah absen pulang' : 'Absen Pulang',
            icon: Icons.logout_rounded,
            color: ClayTheme.surface,
            textColor: ClayTheme.primary,
            busy: _mengirim,
            // Pulang hanya setelah masuk. Urutan terbalik menghasilkan
            // baris absensi tanpa jam datang, dan rekapnya tidak terbaca.
            onPressed:
                (!k.checkedIn || k.checkedOut || !_diDalamRadius || _mengirim)
                ? null
                : () => _absen('pulang'),
          ),
        ],

        const SizedBox(height: ClayTheme.sLg),
        Text(
          'Foto diambil langsung dari kamera saat menekan tombol, beserta '
          'titik lokasi dan waktunya. Ketiganya tersimpan sebagai bukti '
          'kehadiran Anda.',
          style: TextStyle(
            fontSize: 11.5,
            color: ClayTheme.textMuted,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

/// Kartu status lokasi: jarak, ketelitian, dan apa yang harus dilakukan.
class _KartuLokasi extends StatelessWidget {
  const _KartuLokasi({
    required this.mencari,
    required this.galat,
    required this.jarak,
    required this.radius,
    required this.akurasi,
    required this.onUlangi,
  });

  final bool mencari;
  final String? galat;
  final double? jarak;
  final int radius;
  final double? akurasi;
  final VoidCallback onUlangi;

  @override
  Widget build(BuildContext context) {
    if (mencari) {
      return ClaySurface(
        padding: const EdgeInsets.all(ClayTheme.sXl),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
            const SizedBox(width: ClayTheme.sMd),
            Text(
              'Membaca lokasi Anda…',
              style: TextStyle(fontSize: 13, color: ClayTheme.textBody),
            ),
          ],
        ),
      );
    }

    if (galat != null) {
      return _Kotak(
        warna: ClayTheme.danger,
        latar: ClayTheme.dangerSoft,
        ikon: Icons.location_off_rounded,
        judul: 'Lokasi tidak terbaca',
        pesan: galat!,
        onUlangi: onUlangi,
      );
    }

    if (jarak == null) {
      return _Kotak(
        warna: ClayTheme.warning,
        latar: ClayTheme.warningSoft,
        ikon: Icons.my_location_rounded,
        judul: 'Lokasi belum dibaca',
        pesan: 'Ketuk untuk membaca lokasi Anda sekarang.',
        onUlangi: onUlangi,
      );
    }

    final dekat = jarak! <= radius;
    final m = jarak!.round();

    return _Kotak(
      warna: dekat ? ClayTheme.success : ClayTheme.danger,
      latar: dekat ? ClayTheme.successSoft : ClayTheme.dangerSoft,
      ikon: dekat ? Icons.where_to_vote_rounded : Icons.wrong_location_rounded,
      judul: dekat ? 'Anda di lokasi PKL' : 'Anda di luar radius',
      pesan: dekat
          ? '$m m dari titik, dalam radius $radius m.'
                '${akurasi != null ? ' Ketelitian GPS ±${akurasi!.round()} m.' : ''}'
          : '$m m dari titik, sedangkan radiusnya $radius m. '
                'Absen hanya dapat dilakukan di tempat PKL.',
      onUlangi: onUlangi,
    );
  }
}

class _Kotak extends StatelessWidget {
  const _Kotak({
    required this.warna,
    required this.latar,
    required this.ikon,
    required this.judul,
    required this.pesan,
    required this.onUlangi,
  });

  final Color warna;
  final Color latar;
  final IconData ikon;
  final String judul;
  final String pesan;
  final VoidCallback onUlangi;

  @override
  Widget build(BuildContext context) {
    return ClaySurface(
      padding: const EdgeInsets.all(ClayTheme.sXl),
      color: latar,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ikon, color: warna, size: ClayTheme.iconIllustration),
          const SizedBox(width: ClayTheme.sMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  judul,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: ClayTheme.textStrong,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  pesan,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: ClayTheme.textBody,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onUlangi,
            icon: Icon(Icons.refresh_rounded, color: warna),
            tooltip: 'Baca ulang lokasi',
          ),
        ],
      ),
    );
  }
}
