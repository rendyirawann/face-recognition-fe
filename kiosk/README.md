# Jargon GO Kios

APK tipis untuk tablet absensi di sekolah. Isinya **hanya WebView** yang
membuka dua halaman dashboard:

| Menu | Halaman |
|---|---|
| Absensi | `/admin/biometric/scan` |
| Pendaftaran Wajah | `/admin/biometric` |

## Mengapa WebView, bukan pengenalan wajah di dalam aplikasi

Yang menghitung angka wajah adalah **face-api.js** di dalam halaman
dashboard. Angka dari model yang berbeda tidak dapat dibandingkan —
mendaftarkan wajah dengan satu model lalu mencocokkannya dengan model
lain **tidak** menurunkan akurasi, melainkan menghasilkan identifikasi
acak.

Dengan membuka halaman yang sama dengan yang dipakai operator di
komputer, tablet dijamin memakai model yang sama persis. Aplikasi ini
karena itu tidak memuat kamera, ML, maupun berkas model apa pun.

## Mengapa proyek terpisah dari aplikasi siswa

Flutter menyertakan pustaka native setiap paket yang terdaftar di
`pubspec.yaml`, dipakai atau tidak. Bila kios hanya menjadi entry point
kedua di proyek aplikasi siswa, APK-nya tetap membawa pustaka kamera dan
GPS yang tidak pernah disentuhnya.

Hasilnya nyata: aplikasi siswa 108 MB, kios ini **14,9 MB** (arm64).

## Build

```bash
flutter build apk --release --split-per-abi \
  --dart-define=BASE_URL=https://absensi.sekolah.id
```

`BASE_URL` **tanpa garis miring di ujung**, dan **wajib https**:
`getUserMedia` hanya berjalan pada konteks aman, dan di atas `http`
kamera ditolak browser tanpa pesan yang jelas.

Pasang `app-arm64-v8a-release.apk` pada tablet. Berkas `x86_64` hanya
untuk emulator.

## Yang sudah diatur untuk pemakaian kios

* Layar penuh tanpa bilah status dan tombol navigasi.
* Layar tidak pernah tidur selama aplikasi terbuka.
* Izin kamera halaman diberikan otomatis — tanpa itu layar absensi hanya
  menampilkan kotak hitam.
* Tautan ke luar `BASE_URL` diblokir: tablet tanpa bilah alamat tidak
  punya cara kembali bila tersesat.

Pairing perangkat dilakukan di halaman absensinya sendiri, memakai kode
8 digit dari **Perangkat Tablet** di dashboard. Cukup sekali per tablet.
