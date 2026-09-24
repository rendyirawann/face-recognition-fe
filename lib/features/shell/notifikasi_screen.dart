import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/failure.dart';
import '../../core/theme/clay_loading.dart';
import '../../core/theme/clay_theme.dart';
import '../../core/theme/clay_widgets.dart';
import '../../core/theme/clay_motion.dart';
import '../../data/jargon_models.dart';
import '../../providers.dart';

/// Kotak masuk notifikasi dalam aplikasi.
///
/// Seluruh notifikasi ditandai terbaca saat layar dibuka, bukan per baris.
/// Pilihan ini disengaja: lencana di ikon lonceng menjawab "ada yang baru?",
/// dan begitu daftarnya dilihat, pertanyaan itu sudah terjawab.
class NotifikasiScreen extends ConsumerStatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  ConsumerState<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends ConsumerState<NotifikasiScreen> {
  NotificationList? _data;
  String? _error;
  bool _loading = true;

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
      final repo = ref.read(repositoryProvider);
      final data = await repo.notifications();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });

      if (data.unread > 0) {
        await repo.markNotificationsRead();
        // Lencana dibaca dari provider terpisah supaya AppBar ikut berubah
        // tanpa menunggu layar ini ditutup.
        ref.invalidate(unreadNotificationProvider);
      }
    } on ApiFailure catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi')),
      body: _loading
          ? const ClayShimmer(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  children: [
                    ClaySkeleton(height: 74, radius: 18),
                    SizedBox(height: 12),
                    ClaySkeleton(height: 74, radius: 18),
                    SizedBox(height: 12),
                    ClaySkeleton(height: 74, radius: 18),
                  ],
                ),
              ),
            )
          : _error != null
          ? ClayEmpty(
              icon: Icons.cloud_off_rounded,
              title: 'Tidak dapat memuat notifikasi',
              message: _error,
              action: ClayButton(
                label: 'Coba Lagi',
                icon: Icons.refresh_rounded,
                expanded: false,
                onPressed: _muat,
              ),
            )
          : (_data?.items.isEmpty ?? true)
          ? const ClayEmpty(
              icon: Icons.notifications_none_rounded,
              title: 'Belum ada notifikasi',
              message: 'Pemberitahuan penting akan muncul di sini.',
            )
          : ClayRefresh(
              onRefresh: _muat,
              child: ClayConstrained(
                child: ClayAnimatedList(
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      12,
                      20,
                      32 + MediaQuery.viewPaddingOf(context).bottom,
                    ),
                    itemCount: _data!.items.length,
                    itemBuilder: (_, i) => ClayStaggered(
                      index: i,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _Kartu(item: _data!.items[i]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _Kartu extends StatelessWidget {
  const _Kartu({required this.item});

  final AppNotification item;

  @override
  Widget build(BuildContext context) {
    final (ikon, warna) = switch (item.kind) {
      'telat_beruntun' => (
        Icons.running_with_errors_rounded,
        ClayTheme.warning,
      ),
      'panic_escalated' => (Icons.campaign_rounded, ClayTheme.danger),
      _ => (Icons.notifications_rounded, ClayTheme.info),
    };

    return ClaySurface(
      radius: ClayTheme.radiusSmall,
      depth: item.isRead ? 0.5 : 0.9,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: warna.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(ikon, size: ClayTheme.icon, color: warna),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                    color: ClayTheme.textStrong,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.body,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: ClayTheme.textBody,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _relatif(item.createdAt),
                  style: TextStyle(fontSize: 11, color: ClayTheme.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _relatif(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'baru saja';
    if (d.inMinutes < 60) return '${d.inMinutes} menit lalu';
    if (d.inHours < 24) return '${d.inHours} jam lalu';
    if (d.inDays < 30) return '${d.inDays} hari lalu';
    return '${t.day}/${t.month}/${t.year}';
  }
}
