import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/failure.dart';
import '../../core/theme/clay_aksi_sheet.dart';
import '../../core/theme/clay_error.dart';
import '../../core/theme/clay_theme.dart';
import '../../core/theme/clay_widgets.dart';
import '../../data/jargon_models.dart';
import '../../providers.dart';

/// Detail pengajuan: daftar periksa dokumen, unggah, dan pengiriman.
///
/// Daftar periksa adalah inti layar ini. Tanpa daftar yang menunjukkan apa
/// yang masih kurang, guru akan mengirim pengajuan tak lengkap dan berkasnya
/// memantul bolak-balik antara dirinya dan verifikator selama berminggu-minggu.
class BerkasDetailScreen extends ConsumerStatefulWidget {
  const BerkasDetailScreen({super.key, required this.submissionId});

  final String submissionId;

  @override
  ConsumerState<BerkasDetailScreen> createState() => _BerkasDetailScreenState();
}

class _BerkasDetailScreenState extends ConsumerState<BerkasDetailScreen> {
  SubmissionDetail? _detail;
  bool _loading = true;
  bool _periksaSedangJalan = false;
  String? _uploadingTypeId;
  ApiFailure? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final detail = await ref
          .read(repositoryProvider)
          .submissionDetail(widget.submissionId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } on ApiFailure catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  Future<void> _upload(ChecklistItem item) async {
    // Ekstensi dibatasi di pemilih berkas sebagai kenyamanan; server tetap
    // memeriksa isi berkasnya dari magic bytes, karena nama "ijazah.pdf"
    // tidak menjamin isinya benar-benar PDF.
    final picked = await FilePickerPlatform.instance.pickFiles(
      dialogTitle: item.name,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );

    final file = picked.firstOrNull;
    if (file == null) return;

    setState(() => _uploadingTypeId = item.documentTypeId);
    try {
      final bytes = await file.readAsBytes();
      final message = await ref
          .read(repositoryProvider)
          .uploadDocument(
            submissionId: widget.submissionId,
            originalName: file.name,
            content: bytes,
            documentTypeId: item.documentTypeId,
          );
      if (!mounted) return;
      showClaySnack(context, message);
      await _load();
    } on ApiFailure catch (e) {
      if (mounted) showClaySnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _uploadingTypeId = null);
    }
  }

  Future<void> _submit() async {
    final detail = _detail;
    if (detail == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajukan berkas?'),
        content: const Text(
          'Setelah diajukan, berkas terkunci dan tidak dapat diganti sampai '
          'verifikator meminta perbaikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ajukan'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(repositoryProvider).submitDocuments(widget.submissionId);
      if (!mounted) return;
      showClaySnack(context, 'Pengajuan terkirim dan menunggu pemeriksaan.');
      await _load();
    } on ApiFailure catch (e) {
      if (mounted) showClaySnack(context, e.message, error: true);
    }
  }

  /// Putuskan hasil pemeriksaan. Hanya untuk peran verifikator.
  Future<void> _periksa() async {
    final hasil = await tampilkanLembarAksi(
      context,
      judul: 'Hasil pemeriksaan berkas',
      labelCatatan: 'Catatan pemeriksaan',
      pilihan: const [
        ClayPilihanStatus(
          nilai: 'disetujui',
          label: 'Disetujui',
          warna: Color(0xFF1E9E5A),
          keterangan: 'Seluruh berkas lengkap dan sah',
        ),
        ClayPilihanStatus(
          nilai: 'revisi',
          label: 'Perlu revisi',
          warna: Color(0xFFB9740B),
          keterangan: 'Ada berkas yang harus diperbaiki pemohon',
        ),
        ClayPilihanStatus(
          nilai: 'ditolak',
          label: 'Ditolak',
          warna: Color(0xFFCE2F35),
          keterangan: 'Pengajuan tidak dapat dilanjutkan',
        ),
      ],
    );
    if (hasil == null || !mounted) return;

    setState(() => _periksaSedangJalan = true);
    try {
      await ref
          .read(repositoryProvider)
          .reviewSubmission(
            submissionId: widget.submissionId,
            status: hasil.status,
            note: hasil.catatan,
          );
      if (!mounted) return;
      showClaySnack(context, 'Hasil pemeriksaan tersimpan.');
      await _load();
    } on ApiFailure catch (e) {
      if (mounted) showClaySnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _periksaSedangJalan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pengajuan'),
        actions: [
          // Hanya untuk peran verifikator, dan hanya selama pengajuannya
          // belum diputuskan — memeriksa ulang yang sudah disetujui akan
          // menimpa keputusan yang mungkin dibuat orang lain.
          if ((ref.watch(homeSummaryProvider)?.canVerifyDocument ?? false) &&
              const [
                'diajukan',
                'diperiksa',
              ].contains(detail?.submission.status))
            Padding(
              padding: const EdgeInsets.only(right: ClayTheme.sLg),
              child: Center(
                child: ClayButton(
                  label: 'Periksa',
                  compact: true,
                  expanded: false,
                  busy: _periksaSedangJalan,
                  onPressed: _periksaSedangJalan ? null : _periksa,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : detail == null
          ? ClayError(failure: _error!, onRetry: _load)
          : ListView(
              // 32 + inset sistem: pada navigasi gestur Android, bilah bawah
              // menutupi isi terakhir bila paddingnya dipatok tetap.
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                32 + MediaQuery.viewPaddingOf(context).bottom,
              ),
              children: [
                _HeaderCard(detail: detail),

                if (detail.reviewNote != null) ...[
                  const SizedBox(height: 16),
                  ClaySurface(
                    color: detail.submission.status == 'revisi'
                        ? ClayTheme.warningSoft
                        : ClayTheme.infoSoft,
                    depth: 0.6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.rate_review_rounded,
                              size: 17,
                              color: detail.submission.status == 'revisi'
                                  ? ClayTheme.warning
                                  : ClayTheme.info,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Catatan Verifikator'
                              '${detail.reviewerName != null ? ' · ${detail.reviewerName}' : ''}',
                              style: TextStyle(
                                color: detail.submission.status == 'revisi'
                                    ? ClayTheme.warning
                                    : ClayTheme.info,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          detail.reviewNote!,
                          style: TextStyle(
                            color: ClayTheme.textBody,
                            fontSize: 12.5,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                const _SectionTitle('Daftar Berkas'),

                ...detail.checklist.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ChecklistCard(
                      item: item,
                      editable: detail.isEditable,
                      uploading: _uploadingTypeId == item.documentTypeId,
                      onUpload: () => _upload(item),
                    ),
                  ),
                ),

                if (detail.isEditable) ...[
                  const SizedBox(height: 20),
                  if (detail.missingRequired.isNotEmpty)
                    ClaySurface(
                      sunken: true,
                      radius: ClayTheme.radiusSmall,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: ClayTheme.warning,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Masih kurang ${detail.missingRequired.length} '
                              'dokumen wajib: '
                              '${detail.missingRequired.map((c) => c.name).join(', ')}.',
                              style: TextStyle(
                                color: ClayTheme.textBody,
                                fontSize: 11.5,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  ClayButton(
                    label: 'Ajukan untuk Diperiksa',
                    icon: Icons.send_rounded,
                    onPressed: detail.canSubmit ? _submit : null,
                  ),
                  if (!detail.canSubmit) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Lengkapi seluruh dokumen wajib untuk dapat mengajukan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: ClayTheme.textMuted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ],

                if (detail.timeline.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  const _SectionTitle('Riwayat'),
                  ClaySurface(
                    child: Column(
                      children: detail.timeline
                          .map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(top: 4),
                                    decoration: BoxDecoration(
                                      color: ClayTheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          e.note ?? e.status,
                                          style: TextStyle(
                                            color: ClayTheme.textBody,
                                            fontSize: 12.5,
                                            height: 1.45,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          [
                                            if (e.actorLabel != null)
                                              e.actorLabel!,
                                            '${e.createdAt.day}/${e.createdAt.month}/${e.createdAt.year}',
                                          ].join(' · '),
                                          style: TextStyle(
                                            color: ClayTheme.textMuted,
                                            fontSize: 10.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.detail});

  final SubmissionDetail detail;

  @override
  Widget build(BuildContext context) {
    final s = detail.submission;
    final total = detail.checklist.where((c) => c.isRequired).length;
    final done = detail.checklist
        .where((c) => c.isRequired && c.uploaded)
        .length;
    final progress = total == 0 ? 1.0 : done / total;

    return ClaySurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.title,
            style: TextStyle(
              color: ClayTheme.textStrong,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            [
              Submission.purposeLabel(s.purpose),
              if (s.period != null) s.period!,
            ].join(' · '),
            style: TextStyle(color: ClayTheme.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ClayBadge(
            label: s.statusLabel,
            color: switch (s.status) {
              'disetujui' => ClayTheme.success,
              'ditolak' => ClayTheme.danger,
              'revisi' => ClayTheme.warning,
              _ => ClayTheme.info,
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 9,
                    color: progress >= 1
                        ? ClayTheme.success
                        : ClayTheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$done/$total wajib',
                style: TextStyle(
                  color: ClayTheme.textBody,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  const _ChecklistCard({
    required this.item,
    required this.editable,
    required this.uploading,
    required this.onUpload,
  });

  final ChecklistItem item;
  final bool editable;
  final bool uploading;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final (color, background, icon) = item.isRejected
        ? (ClayTheme.danger, ClayTheme.dangerSoft, Icons.close_rounded)
        : item.isApproved
        ? (ClayTheme.success, ClayTheme.successSoft, Icons.check_rounded)
        : item.uploaded
        ? (ClayTheme.info, ClayTheme.infoSoft, Icons.schedule_rounded)
        : (
            ClayTheme.textMuted,
            ClayTheme.background,
            Icons.upload_file_rounded,
          );

    return ClaySurface(
      padding: const EdgeInsets.all(16),
      depth: 0.65,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClayIcon(
                icon: icon,
                color: color,
                background: background,
                size: 17,
                padding: 10,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              color: ClayTheme.textStrong,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (item.isRequired) ...[
                          const SizedBox(width: 8),
                          Text(
                            '*',
                            style: TextStyle(
                              color: ClayTheme.danger,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (item.description != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.description!,
                        style: TextStyle(
                          color: ClayTheme.textMuted,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (editable)
                uploading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : ClayGhostButton(
                        label: item.uploaded ? 'Ganti' : 'Unggah',
                        icon: Icons.attach_file_rounded,
                        onPressed: onUpload,
                      ),
            ],
          ),

          // Alasan penolakan ditampilkan menonjol: inilah satu-satunya
          // informasi yang menentukan apa yang harus guru perbaiki.
          if (item.isRejected && item.rejectReason != null) ...[
            const SizedBox(height: 12),
            ClaySurface(
              sunken: true,
              radius: ClayTheme.radiusSmall,
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 15,
                    color: ClayTheme.danger,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.rejectReason!,
                      style: TextStyle(
                        color: ClayTheme.danger,
                        fontSize: 11.5,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 8, bottom: 12),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        color: ClayTheme.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
      ),
    ),
  );
}
