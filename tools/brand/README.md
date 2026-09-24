# Lambang Jargon GO

Lambangnya digambar sebagai kode, bukan berkas biner yang diedit tangan.
Seluruh ukuran — ikon peluncur, ikon adaptif, layar peluncuran, dan logo di
layar login — berasal dari satu sumber dan dapat dibangkitkan ulang bila
palet temanya berubah.

## Menjalankan

```bash
pip install pillow
cd tools/brand
python ekspor.py
```

Yang ditulis ulang:

| Tujuan | Berkas |
|---|---|
| Logo dalam aplikasi | `assets/brand/jargon-mark.png` |
| Ikon toko / berkas rujukan | `assets/brand/jargon-icon.png`, `jargon-icon-512.png` |
| Ikon peluncur (Android 7-) | `android/.../mipmap-*/ic_launcher.png` |
| Lapisan depan ikon adaptif | `android/.../mipmap-*/ic_launcher_foreground.png` |

Layar peluncuran (`drawable-*/splash_logo.png`) dibangkitkan terpisah; lihat
riwayat commit bila perlu dibuat ulang.

## Yang perlu diperhatikan

**Ikon adaptif berbeda ukuran dengan ikon warisan.** Android memangkas ikon
adaptif hingga 33% tiap sisi dan memotongnya menjadi bentuk apa pun yang
dipilih peluncur — lingkaran, kotak membulat, tetesan. Karena itu marknya
dibuat jauh lebih kecil pada lapisan depan (`isi=0.44`); memakai ukuran
penuh akan membuat sikunya terpotong pada peluncur berbentuk lingkaran.

**Latar ikon adaptif ada di XML, bukan di gambar.** Warnanya di
`values/ic_launcher_background.xml`. Menggambar latar pada PNG lapisan depan
akan menghasilkan kotak yang terlihat di dalam potongan peluncur.
