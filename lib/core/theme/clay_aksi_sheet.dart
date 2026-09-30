import 'package:flutter/material.dart';

import 'clay_theme.dart';
import 'clay_widgets.dart';

/// Satu pilihan status pada lembar penanganan.
class ClayPilihanStatus {
  const ClayPilihanStatus({
    required this.nilai,
    required this.label,
    required this.warna,
    this.keterangan,
  });

  /// Nilai yang dikirim ke server, mis. `ditindaklanjuti`.
  final String nilai;
  final String label;
  final Color warna;
  final String? keterangan;
}

/// Hasil lembar penanganan.
class ClayHasilAksi {
  const ClayHasilAksi({required this.status, required this.catatan});

  final String status;
  final String catatan;
}

/// Lembar penanganan: pilih status, tulis catatan.
///
/// MENGAPA CATATAN WAJIB
///
/// Server menolak catatan di bawah tiga karakter, dan itu bukan kerewelan.
/// Laporan berpindah tangan antar jenjang — sekolah, Cabang Dinas, Dinas —
/// dan penangan berikutnya hanya punya lini masa ini untuk tahu apa yang
/// sudah dikerjakan. Perubahan status tanpa keterangan membuat laporan
/// sampai ke Dinas sebagai deretan status tanpa cerita.
///
/// Dipakai bersama layar laporan dan pemberkasan: keduanya menanyakan hal
/// yang sama persis, dan dua lembar terpisah yang mirip pasti menyimpang
/// satu sama lain.
Future<ClayHasilAksi?> tampilkanLembarAksi(
  BuildContext context, {
  required String judul,
  required List<ClayPilihanStatus> pilihan,
  String labelCatatan = 'Catatan penanganan',
}) {
  return showModalBottomSheet<ClayHasilAksi>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) =>
        _LembarAksi(judul: judul, pilihan: pilihan, labelCatatan: labelCatatan),
  );
}

class _LembarAksi extends StatefulWidget {
  const _LembarAksi({
    required this.judul,
    required this.pilihan,
    required this.labelCatatan,
  });

  final String judul;
  final List<ClayPilihanStatus> pilihan;
  final String labelCatatan;

  @override
  State<_LembarAksi> createState() => _LembarAksiState();
}

class _LembarAksiState extends State<_LembarAksi> {
  final _catatan = TextEditingController();
  String? _status;

  @override
  void initState() {
    super.initState();
    // Catatan ikut memicu penilaian ulang tombol Simpan.
    _catatan.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _catatan.dispose();
    super.dispose();
  }

  bool get _siap => _status != null && _catatan.text.trim().length >= 3;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Papan ketik menutupi lembar ini tanpa penyesuaian ini, dan kotak
      // catatannya justru yang tertutup.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ClaySurface(
        radius: ClayTheme.radius,
        padding: const EdgeInsets.fromLTRB(
          ClayTheme.sXl,
          ClayTheme.sLg,
          ClayTheme.sXl,
          ClayTheme.sXl,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ClayTheme.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(ClayTheme.radiusPill),
                  ),
                ),
              ),
              const SizedBox(height: ClayTheme.sLg),

              Text(
                widget.judul,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: ClayTheme.textStrong,
                ),
              ),
              const SizedBox(height: ClayTheme.sLg),

              for (final p in widget.pilihan) ...[
                _BarisPilihan(
                  pilihan: p,
                  terpilih: _status == p.nilai,
                  onTap: () => setState(() => _status = p.nilai),
                ),
                const SizedBox(height: ClayTheme.sSm),
              ],

              const SizedBox(height: ClayTheme.sMd),
              ClayField(
                controller: _catatan,
                label: widget.labelCatatan,
                hint: 'Wajib diisi, minimal 3 karakter',
                maxLines: 3,
              ),
              const SizedBox(height: ClayTheme.sXl),

              ClayButton(
                label: 'Simpan',
                expanded: true,
                onPressed: !_siap
                    ? null
                    : () => Navigator.of(context).pop(
                        ClayHasilAksi(
                          status: _status!,
                          catatan: _catatan.text.trim(),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarisPilihan extends StatelessWidget {
  const _BarisPilihan({
    required this.pilihan,
    required this.terpilih,
    required this.onTap,
  });

  final ClayPilihanStatus pilihan;
  final bool terpilih;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClaySurface(
      radius: ClayTheme.radiusSmall,
      padding: const EdgeInsets.symmetric(
        horizontal: ClayTheme.sLg,
        vertical: ClayTheme.sMd,
      ),
      color: terpilih ? ClayTheme.primarySoft : ClayTheme.surface,
      depth: terpilih ? 0.4 : 0.7,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: pilihan.warna,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: ClayTheme.sMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pilihan.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: ClayTheme.textStrong,
                  ),
                ),
                if (pilihan.keterangan != null)
                  Text(
                    pilihan.keterangan!,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: ClayTheme.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          if (terpilih)
            Icon(
              Icons.check_circle_rounded,
              size: ClayTheme.icon,
              color: ClayTheme.primary,
            ),
        ],
      ),
    );
  }
}
