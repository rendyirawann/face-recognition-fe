"""Pembangkit lambang Jargon GO.

Digambar sebagai kode, bukan berkas biner yang diedit tangan, supaya seluruh
ukuran berasal dari satu sumber dan dapat dibangkitkan ulang bila palet
temanya berubah.

BENTUKNYA

Empat siku pembentuk bingkai pindai, dengan centang di dalamnya. Dipilih
karena itulah yang sebenarnya dilakukan aplikasi ini: mengarahkan wajah ke
dalam bingkai lalu tercatat hadir. Lambang bertema buku atau topi wisuda
akan menyamakannya dengan ratusan aplikasi sekolah lain dan tidak
memberi tahu apa pun tentang cara kerjanya.

Digambar pada kanvas 8x lalu dikecilkan dengan LANCZOS; PIL tidak punya
anti-alias pada primitifnya, dan tepi bergerigi paling terlihat justru pada
ukuran ikon yang kecil.
"""
from PIL import Image, ImageDraw

S = 8  # faktor supersampling

NAVY_ATAS = (27, 37, 64)     # #1B2540  surface gelap
NAVY_BAWAH = (19, 26, 46)    # #131A2E  background gelap
BIRU = (76, 125, 240)        # #4C7DF0  primary
TEAL = (45, 212, 191)        # #2DD4BF  secondary


def _gradasi(ukuran):
    """Latar navy yang menggelap ke bawah."""
    g = Image.new('RGB', (1, ukuran))
    d = ImageDraw.Draw(g)
    for y in range(ukuran):
        t = y / max(ukuran - 1, 1)
        d.point((0, y), fill=tuple(
            round(a + (b - a) * t) for a, b in zip(NAVY_ATAS, NAVY_BAWAH)
        ))
    return g.resize((ukuran, ukuran), Image.NEAREST)


def _siku(d, kotak, tebal, panjang, warna):
    """Empat siku bingkai pindai."""
    x0, y0, x1, y1 = kotak
    # Radius TIDAK boleh melebihi separuh tebal lengan: di atas itu,
    # `rounded_rectangle` menggelembungkan ujungnya alih-alih membulatkannya.
    r = tebal / 2
    for (cx, cy, dx, dy) in (
        (x0, y0, 1, 1), (x1, y0, -1, 1), (x0, y1, 1, -1), (x1, y1, -1, -1)
    ):
        # lengan mendatar
        d.rounded_rectangle(
            [min(cx, cx + dx * panjang), min(cy, cy + dy * tebal),
             max(cx, cx + dx * panjang), max(cy, cy + dy * tebal)],
            radius=r, fill=warna,
        )
        # lengan tegak
        d.rounded_rectangle(
            [min(cx, cx + dx * tebal), min(cy, cy + dy * panjang),
             max(cx, cx + dx * tebal), max(cy, cy + dy * panjang)],
            radius=r, fill=warna,
        )


def _centang(d, pusat, lebar, tebal, warna):
    """Centang di tengah bingkai."""
    cx, cy = pusat
    a = (cx - lebar * 0.46, cy + lebar * 0.02)
    b = (cx - lebar * 0.12, cy + lebar * 0.33)
    c = (cx + lebar * 0.47, cy - lebar * 0.34)
    d.line([a, b, c], fill=warna, width=int(tebal), joint='curve')
    for titik in (a, b, c):
        d.ellipse(
            [titik[0] - tebal / 2, titik[1] - tebal / 2,
             titik[0] + tebal / 2, titik[1] + tebal / 2],
            fill=warna,
        )


def mark(px, *, latar=True, isi=0.62, radius_rel=0.235):
    """Satu lambang berukuran `px`.

    `isi` = bagian kanvas yang ditempati bingkai pindai. Ikon adaptif Android
    memangkas sampai 33% tiap sisi, jadi lapisan depannya memakai nilai yang
    lebih kecil agar marknya tidak ikut terpotong.
    """
    n = px * S
    im = Image.new('RGBA', (n, n), (0, 0, 0, 0))

    if latar:
        bg = _gradasi(n).convert('RGBA')
        masker = Image.new('L', (n, n), 0)
        ImageDraw.Draw(masker).rounded_rectangle(
            [0, 0, n - 1, n - 1], radius=int(n * radius_rel), fill=255,
        )
        im.paste(bg, (0, 0), masker)

    d = ImageDraw.Draw(im)
    sisi = n * isi
    o = (n - sisi) / 2
    tebal = sisi * 0.098
    _siku(d, (o, o, o + sisi, o + sisi), tebal, sisi * 0.3, BIRU)
    _centang(d, (n / 2, n / 2), sisi * 0.46, tebal * 1.05, TEAL)

    return im.resize((px, px), Image.LANCZOS)


if __name__ == '__main__':
    mark(1024).save('jargon-icon-1024.png')
    mark(1024, latar=False, isi=0.78).save('jargon-mark-1024.png')
    print('contoh dibuat')
