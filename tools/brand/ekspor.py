"""Ekspor lambang ke seluruh aset yang dibutuhkan Android dan aplikasi."""
import os
from buat_logo import mark

FE = r"c:/xampp/htdocs/myProject/face-recognition-only/face-recognition-fe"
RES = f"{FE}/android/app/src/main/res"

# Kepadatan layar Android. Ikon warisan 48dp, ikon adaptif 108dp.
KEPADATAN = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}

os.makedirs(f"{FE}/assets/brand", exist_ok=True)

# --- Aset dalam aplikasi ------------------------------------------------
mark(1024, latar=False, isi=0.78).save(f"{FE}/assets/brand/jargon-mark.png")
mark(1024).save(f"{FE}/assets/brand/jargon-icon.png")
mark(512).save(f"{FE}/assets/brand/jargon-icon-512.png")   # untuk Play Store

# --- Ikon peluncur ------------------------------------------------------
for nama, k in KEPADATAN.items():
    d = f"{RES}/mipmap-{nama}"
    os.makedirs(d, exist_ok=True)

    # Warisan: persegi membulat penuh, dipakai Android 7 ke bawah.
    mark(round(48 * k)).save(f"{d}/ic_launcher.png")

    # Adaptif: hanya lapisan DEPAN, latarnya warna solid dari XML.
    #
    # Android memangkas ikon adaptif hingga 33% tiap sisi dan memotongnya
    # menjadi bentuk apa pun yang dipilih peluncur — lingkaran, kotak
    # membulat, tetesan. Marknya karena itu dibuat jauh lebih kecil: pada
    # kanvas 108dp, bingkai pindai hanya menempati 44%, sehingga seluruh
    # sikunya tetap berada di dalam lingkaran aman berapa pun bentuk
    # potongannya.
    mark(round(108 * k), latar=False, isi=0.44).save(
        f"{d}/ic_launcher_foreground.png"
    )

print("ikon peluncur + aset aplikasi selesai")
