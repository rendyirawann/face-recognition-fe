import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/api_config.dart';
import 'core/storage.dart';
import 'core/theme/clay_theme.dart';
import 'data/offline_queue.dart';
import 'features/auth/login_screen.dart';
import 'features/shell/home_shell.dart';
import 'providers.dart';

/// **Jargon GO** — Super Apps Dinas Pendidikan Provinsi Sumatera Utara.
///
/// Satu aplikasi untuk beberapa peran yang sangat berbeda:
///   * siswa & orang tua : memantau absensi, mengirim pengaduan
///   * guru & staff      : memantau kelas, mengurus pemberkasan
///   * tablet sekolah    : mode kios absensi wajah (lewat menu Profil)
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(DeviceOrientation.values);

  // Bilah status menyatu dengan latar clay; ikonnya digelapkan karena
  // latarnya terang.
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: ClayTheme.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Storage dan antrean offline dibuka SEBELUM aplikasi berjalan, lalu
  // di-override ke dalam graf provider — tidak ada layar yang perlu
  // menangani keadaan "belum siap".
  final storage = await Storage.open();
  final queue = await OfflineQueue.open();

  // Alamat server pilihan pengguna dipulihkan SEBELUM aplikasi berjalan,
  // supaya request pertama pun sudah menuju server yang benar. Tanpa ini,
  // pemulihan sesi di layar pertama akan menembak alamat bawaan build.
  ApiConfig.load(storage);

  runApp(
    ProviderScope(
      overrides: [
        storageProvider.overrideWithValue(storage),
        offlineQueueProvider.overrideWithValue(queue),
      ],
      child: const JargonApp(),
    ),
  );
}

/// Kunci navigator global, dipakai saat sesi berakhir.
///
/// Menyetel `currentUserProvider` ke null saja tidak memindahkan layar: login
/// memakai `pushReplacement`, sehingga rute yang memegang `home:` sudah tidak
/// ada di stack. Klien HTTP yang mendeteksi sesi mati juga tidak punya
/// BuildContext.
final navigatorKey = GlobalKey<NavigatorState>();

class JargonApp extends ConsumerStatefulWidget {
  const JargonApp({super.key});

  @override
  ConsumerState<JargonApp> createState() => _JargonAppState();
}

class _JargonAppState extends ConsumerState<JargonApp> {
  @override
  void initState() {
    super.initState();

    // Dipanggil klien HTTP ketika penyegaran token gagal. Profil disetel ke
    // null DAN stack dikosongkan — keduanya perlu, lihat doc `navigatorKey`.
    ref.read(apiClientProvider).onSessionExpired = () {
      if (!mounted) return;
      ref.read(currentUserProvider.notifier).state = null;

      // Sama seperti tombol Keluar; tanpa ini pengguna tertinggal di layar
      // yang gagal memuat.
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    // Sesi sebelumnya dipulihkan dari secure storage, sehingga pengguna tidak
    // perlu login ulang setiap membuka aplikasi.
    final user = ref.watch(currentUserProvider);

    // Efek samping di dalam build, disengaja: warna dibaca lewat getter
    // statis di seluruh aplikasi, jadi nilainya harus benar sebelum widget
    // mana pun dibangun — dan build inilah yang berjalan ulang saat tema
    // diganti.
    final gelap = ref.watch(temaGelapProvider);
    ClayTheme.pakai(gelap: gelap);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Ikon bilah status berlawanan dengan latar. Nilai yang dipasang
      // sekali di `main()` menjadi salah begitu tema bisa diganti.
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: gelap ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: ClayTheme.background,
        systemNavigationBarIconBrightness: gelap
            ? Brightness.light
            : Brightness.dark,
      ),
      child: MaterialApp(
        title: 'Jargon GO',
        navigatorKey: navigatorKey,

        // Android mengizinkan skala font sampai 200%; pada nilai itu angka jam
        // masuk terpotong. Yang dibatasi hanya rentangnya — font besar tetap
        // tampil lebih besar.
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(
              textScaler: mq.textScaler.clamp(
                minScaleFactor: 0.9,
                maxScaleFactor: 1.3,
              ),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        debugShowCheckedModeBanner: false,
        locale: const Locale('id'),
        supportedLocales: const [Locale('id'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ClayTheme.build(),
        home: user == null ? const LoginScreen() : const HomeShell(),
      ),
    );
  }
}
