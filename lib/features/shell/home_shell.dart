import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';

import '../../core/failure.dart';
import '../../core/theme/clay_backdrop.dart';
import '../../core/theme/clay_theme.dart';
import '../../core/theme/clay_widgets.dart';
import '../../data/jargon_models.dart';
import '../../providers.dart';
import '../absensi/absensi_screen.dart';
import '../berkas/berkas_screen.dart';
import '../panic/panic_feed_screen.dart';
import 'beranda_tab.dart';
import 'notifikasi_screen.dart';
import 'profile_screen.dart';
import 'sidebar_menu.dart';
import 'server_settings_screen.dart';

/// Kerangka utama Jargon GO: beranda + tiga menu.
///
/// Menu yang muncul ditentukan `available_menus` dari server, bukan disimpulkan
/// dari peran di sisi aplikasi. Dengan begitu, menambah peran baru atau
/// mengubah izin di dashboard langsung berlaku tanpa merilis aplikasi baru —
/// penting untuk sistem yang dipakai ribuan sekolah dengan siklus pembaruan
/// aplikasi yang lambat.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  /// Kendali drawer dipegang di sini, bukan lewat `ZoomDrawer.of(context)`:
  /// bilah navigasi dibangun pada build yang sama, sehingga contextnya berada
  /// di atas drawer dan `ZoomDrawer.of` mengembalikan null tanpa pesan galat.
  final ZoomDrawerController _drawer = ZoomDrawerController();

  int _index = 0;
  HomeSummary? _summary;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary = await ref.read(repositoryProvider).home();
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _loading = false;
      });
      // Lencana lonceng ikut disegarkan saat beranda ditarik ulang.
      ref.invalidate(unreadNotificationProvider);
    } on ApiFailure catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat beranda: $e';
          _loading = false;
        });
      }
    }
  }

  /// Tab yang tersedia beserta layarnya, disusun dari izin akun.
  ({List<ClayNavItem> items, List<Widget> pages}) _buildTabs() {
    final summary = _summary;
    final items = <ClayNavItem>[
      const ClayNavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Beranda',
      ),
    ];
    final pages = <Widget>[BerandaTab(summary: summary, onRefresh: _load)];

    if (summary?.hasMenu('absensi') ?? false) {
      items.add(
        const ClayNavItem(
          icon: Icons.fact_check_outlined,
          activeIcon: Icons.fact_check_rounded,
          label: 'Absensi',
        ),
      );
      pages.add(const AbsensiScreen());
    }

    if (summary?.hasMenu('panic_button') ?? false) {
      items.add(
        ClayNavItem(
          icon: Icons.campaign_outlined,
          activeIcon: Icons.campaign_rounded,
          label: 'Lapor',
          badge: summary?.panicUpdates ?? 0,
        ),
      );
      pages.add(const PanicFeedScreen());
    }

    if (summary?.hasMenu('pemberkasan') ?? false) {
      items.add(
        ClayNavItem(
          icon: Icons.folder_outlined,
          activeIcon: Icons.folder_rounded,
          label: 'Berkas',
          badge: summary?.documentActions ?? 0,
        ),
      );
      pages.add(const BerkasScreen());
    }

    return (items: items, pages: pages);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final tabs = _buildTabs();

    // Bila jumlah tab menyusut (mis. izin dicabut lalu beranda dimuat ulang),
    // indeks lama bisa menunjuk tab yang sudah tidak ada.
    final index = _index.clamp(0, tabs.pages.length - 1);

    return ZoomDrawer(
      controller: _drawer,
      // Layar utama dimiringkan dan dikecilkan; sudut kecil (-5) dipilih
      // karena sudut besar membuat teks di tepi kanan terlihat terdistorsi
      // pada layar ponsel kecil.
      angle: -5,
      mainScreenScale: 0.14,
      slideWidth: MediaQuery.of(context).size.width * 0.74,
      borderRadius: 30,
      showShadow: true,
      menuBackgroundColor: ClayTheme.sidebarBg,
      drawerShadowsBackgroundColor: ClayTheme.surface,
      // Gestur geser dimatikan: layar Absensi dan Lapor punya daftar yang
      // digulir, dan gestur drawer akan merebut sentuhan itu.
      disableDragGesture: true,

      // Ketuk di mana pun untuk menutup. Aman terhadap salah sentuh:
      // `mainScreenAbsorbPointer` bawaan paket bernilai true dan
      // GestureDetector penutupnya berada di luar AbsorbPointer itu, jadi
      // ketukan tidak menembus ke tombol di bawahnya. Baris menu tetap bisa
      // diketuk karena detektornya lebih dalam.
      mainScreenTapClose: true,
      menuScreenTapClose: true,

      // Tombol kembali Android menutup drawer, bukan keluar dari aplikasi.
      androidCloseOnBackTap: true,
      menuScreen: SidebarMenu(
        nama: user?.name ?? 'Pengguna',
        // Label peran diambil dari server (`role_label`), bukan dipetakan
        // di klien. Pemetaan di klien akan tertinggal setiap kali peran baru
        // ditambahkan di dashboard — dan sekarang perannya jadi delapan.
        peran: _summary?.roleLabel ?? user?.roleLabel ?? 'Jargon GO',
        aktif: index,
        onTutup: () => _drawer.close?.call(),
        gelap: ref.watch(temaGelapProvider),
        onGantiTema: (gelap) {
          // Disimpan DAN dipasang ke state provider. Menyimpan saja tidak
          // mengubah tampilan sampai aplikasi dibuka lagi; menyetel provider
          // saja membuat pilihannya hilang setelah aplikasi ditutup.
          ref.read(storageProvider).simpanTemaGelap(gelap);
          ref.read(temaGelapProvider.notifier).state = gelap;
        },
        onPilihTab: (i) => setState(() => _index = i),
        tab: [
          for (final it in tabs.items)
            SidebarItem(icon: it.activeIcon, label: it.label, badge: it.badge),
        ],
        lainnya: [
          SidebarItem(
            icon: Icons.person_outline_rounded,
            label: 'Profil Saya',
            keterangan: 'Lengkapi data diri',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          SidebarItem(
            icon: Icons.dns_outlined,
            label: 'Alamat Server',
            keterangan: 'Untuk pengujian jaringan',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ServerSettingsScreen()),
            ),
          ),
        ],
      ),
      mainScreen: ClayBackdrop(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            // Tombol sidebar di ATAS, pada posisi leading — tempat yang memang
            // dicari orang untuk menu. Sebelumnya ditaruh di bilah bawah agar
            // tetap terlihat saat digulir, tetapi itu menempatkannya di tempat
            // yang tidak lazim: bilah bawah dibaca sebagai perpindahan tab,
            // bukan sebagai pembuka menu.
            leadingWidth: 60,
            leading: Padding(
              padding: const EdgeInsets.only(left: ClayTheme.sLg),
              // `Center` WAJIB di sini. AppBar memberi slot `leading` tinggi
              // penuh toolbar, dan ClaySurface tanpa tinggi sendiri akan
              // meregang mengisinya — tombolnya jadi lonjong memanjang ke
              // bawah alih-alih bulat.
              child: Center(
                child: ClaySurface(
                  radius: ClayTheme.radiusPill,
                  padding: const EdgeInsets.all(ClayTheme.sSm + 2),
                  depth: 0.7,
                  onTap: () => _drawer.toggle?.call(),
                  child: Icon(
                    Icons.menu_rounded,
                    size: ClayTheme.icon,
                    color: ClayTheme.primary,
                  ),
                ),
              ),
            ),
            titleSpacing: 8,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _summary?.greeting ?? 'Jargon GO',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: ClayTheme.textStrong,
                  ),
                ),
                Text(
                  _summary?.roleLabel ?? user?.roleLabel ?? '',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: ClayTheme.textMuted,
                  ),
                ),
              ],
            ),
            actions: [
              _LonengNotifikasi(
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotifikasiScreen()),
                  );
                  if (mounted) ref.invalidate(unreadNotificationProvider);
                },
              ),
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: ClaySurface(
                  radius: ClayTheme.radiusPill,
                  padding: const EdgeInsets.all(12),
                  depth: 0.7,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                  child: Icon(
                    Icons.person_outline_rounded,
                    size: 20,
                    color: ClayTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? ClayEmpty(
                  icon: Icons.cloud_off_rounded,
                  title: 'Tidak dapat memuat data',
                  message: _error,
                  action: ClayButton(
                    label: 'Coba Lagi',
                    icon: Icons.refresh_rounded,
                    expanded: false,
                    onPressed: _load,
                  ),
                )
              : IndexedStack(index: index, children: tabs.pages),
          bottomNavigationBar:
              _loading || _error != null || tabs.items.length < 2
              ? null
              : ClayNavBar(
                  items: tabs.items,
                  currentIndex: index,
                  onSelected: (i) => setState(() => _index = i),
                ),
        ),
      ),
    );
  }
}

/// Ikon lonceng dengan lencana jumlah notifikasi belum dibaca.
class _LonengNotifikasi extends ConsumerWidget {
  const _LonengNotifikasi({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Lencana gagal-diam: kegagalan jaringan mengembalikan 0, bukan galat.
    // Angka di pojok atas bukan informasi yang layak menghentikan beranda.
    final belum = ref.watch(unreadNotificationProvider).value ?? 0;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: ClaySurface(
        radius: ClayTheme.radiusPill,
        padding: const EdgeInsets.all(12),
        depth: 0.7,
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              belum > 0
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_none_rounded,
              size: ClayTheme.icon,
              color: belum > 0 ? ClayTheme.primary : ClayTheme.textBody,
            ),
            if (belum > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  constraints: const BoxConstraints(minWidth: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ClayTheme.danger,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    belum > 9 ? '9+' : '$belum',
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
      ),
    );
  }
}
