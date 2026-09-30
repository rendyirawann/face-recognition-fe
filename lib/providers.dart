import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/api_client.dart';
import 'core/api_config.dart';
import 'core/theme/clay_theme.dart';
import 'core/storage.dart';
import 'data/models.dart';
import 'data/offline_queue.dart';
import 'data/repository.dart';
import 'data/jargon_models.dart';

/// Dependensi yang disiapkan sebelum aplikasi berjalan (lihat main.dart),
/// lalu di-override ke dalam graf provider. Dengan begitu tidak ada layar
/// yang perlu menunggu inisialisasi asinkron.
final storageProvider = Provider<Storage>((_) {
  throw StateError('storageProvider harus di-override di main()');
});

final offlineQueueProvider = Provider<OfflineQueue>((_) {
  throw StateError('offlineQueueProvider harus di-override di main()');
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(storageProvider));
});

final repositoryProvider = Provider<AbsensiRepository>((ref) {
  return AbsensiRepository(
    ref.watch(apiClientProvider),
    ref.watch(storageProvider),
    ref.watch(offlineQueueProvider),
  );
});

/// Alamat server API yang sedang dipakai.
///
/// [ApiConfig] adalah sumber kebenarannya — klien HTTP membacanya langsung
/// pada tiap request. Provider ini hanya cerminnya untuk UI, supaya layar yang
/// menampilkan alamat ikut berubah begitu pengguna menyimpannya, tanpa perlu
/// keluar-masuk halaman.
final apiBaseUrlProvider = StateProvider<String>((ref) => ApiConfig.baseUrl);

/// Ringkasan beranda terakhir yang dimuat.
///
/// Diisi `HomeShell` sekali per pemuatan, lalu dibaca layar detail yang
/// membutuhkan penanda kemampuan (`canHandlePanic`, `canVerifyDocument`).
/// Alternatifnya adalah memanggil `/me/home` lagi setiap kali satu detail
/// dibuka — satu permintaan jaringan tambahan hanya untuk memutuskan
/// apakah sebuah tombol tampil.
final homeSummaryProvider = StateProvider<HomeSummary?>((ref) => null);

/// Profil perangkat kios yang tersimpan lokal. `null` bila belum dipasangkan.
final deviceProfileProvider = StateProvider<Map<String, dynamic>?>((ref) {
  return ref.watch(storageProvider).deviceProfile();
});

/// Profil pengguna yang sedang masuk (guru / kepala sekolah).
final currentUserProvider = StateProvider<UserProfile?>((ref) {
  return ref.watch(repositoryProvider).cachedUser();
});

/// Tema gelap aktif atau tidak. Bawaannya gelap.
///
/// `ClayTheme.pakai` dipanggil di sini juga, bukan hanya di UI: warna dibaca
/// lewat getter statis dan harus sudah benar sebelum widget dibangun.
final temaGelapProvider = StateProvider<bool>((ref) {
  final tersimpan = ref.watch(storageProvider).temaGelap() ?? true;
  ClayTheme.pakai(gelap: tersimpan);
  return tersimpan;
});

/// Jumlah notifikasi belum dibaca, untuk lencana ikon lonceng.
///
/// Future, bukan Stream: notifikasi dibuat sekali sehari oleh pekerja server.
/// Disegarkan saat beranda dimuat ulang dan setelah kotak masuk dibuka.
final unreadNotificationProvider = FutureProvider<int>((ref) async {
  try {
    return (await ref.watch(repositoryProvider).notifications()).unread;
  } catch (_) {
    // Gagal-diam: lencana tidak layak memunculkan galat di beranda.
    return 0;
  }
});

/// Jumlah absensi yang masih menunggu terkirim.
final pendingCountProvider = StreamProvider<int>((ref) async* {
  final repo = ref.watch(repositoryProvider);
  // Angka ini muncul sebagai lencana di layar kios; interval 5 detik cukup
  // responsif tanpa membebani penyimpanan tablet.
  while (true) {
    yield await repo.pendingCount();
    await Future<void>.delayed(const Duration(seconds: 5));
  }
});
