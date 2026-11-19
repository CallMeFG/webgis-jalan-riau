# Kamus Data — WebGIS Jalan Riau

Sumber: survey lapangan Avenza Maps, 1 dan 8 Oktober 2026, Kawasan Jalan Riau, Kota Pekanbaru.
Sistem koordinat: WGS 84 (EPSG:4326), longitude–latitude. Peta web menampilkan dalam Web Mercator (EPSG:3857).
Panjang dan luas dihitung geodesik (elipsoid WGS 84), dalam meter dan meter persegi.

## 1. Titik Infrastruktur (`titik_infrastruktur`)

Geometri: **Point** · Jumlah: **41 titik** · Berfoto: 38

| Kolom | Tipe | Keterangan | Nilai yang diizinkan / contoh |
|---|---|---|---|
| `kode` | teks | ID unik, urut waktu survey | `P01` – `P41` |
| `nama` | teks | Nama titik (ejaan dirapikan) | `Lubang jalan 4`, `Halte 1` |
| `nama_asli` | teks | Nama asli di Avenza | `Lobang jalan 4`, `Jala rusa 17` |
| `jenis` | teks (kategori) | Jenis infrastruktur | `Lubang jalan`, `Jalan rusak`, `Lampu jalan`, `Halte`, `Rambu` |
| `keterangan` | teks, boleh kosong | Catatan tambahan | `Kerusakan akibat drainase/genangan`, `Lampu lalu lintas`, `Lampu lalu lintas tidak berfungsi` |
| `ruas_kode` | teks | Ruas jalan terdekat (≤ 15 m) | `L01` – `L06` |
| `elevasi_m` | desimal | Ketinggian dari GPS HP | 9,0 – 14,1 |
| `waktu_survey` | tanggal-waktu (WIB) | Waktu titik direkam | `2026-10-01T09:33:37+07:00` |
| `foto` | teks, boleh kosong | Path foto (lebar maks. 1280 px) | `foto/P01.jpg`; kosong untuk 3 lubang Jl. Haji Guru |

Rekap: lubang jalan 15 · jalan rusak 10 · lampu jalan 11 · halte 3 · rambu 2.

## 2. Ruas Jalan (`ruas_jalan`)

Geometri: **LineString** · Jumlah: **6 ruas** · Total panjang ±3,3 km

| Kolom | Tipe | Keterangan | Nilai yang diizinkan / contoh |
|---|---|---|---|
| `kode` | teks | ID unik | `L01` – `L06` |
| `nama` | teks | Nama jalan | `Jl. Riau`, `Gg. Darul Akbar`, `Jl. Mutiara`, `Gg. Sepakat`, `Gg. Geliga`, `Jl. Haji Guru` |
| `jenis_jalan` | teks (kategori) | Fungsi jalan | `kolektor`, `lokal`, `lingkungan` |
| `kondisi` | teks (kategori) | Penilaian visual saat survey | `bagus`, `sedang`, `rusak` |
| `lebar_m` | desimal | Lebar jalan | 3,5 – 10 |
| `kepadatan` | teks (kategori) | Kepadatan lalu lintas (pengamatan) | `rendah`, `sedang`, `tinggi` |
| `pedestrian` | boolean | Ada trotoar/jalur pejalan kaki | `true` / `false` (semua `false`) |
| `drainase` | teks (kategori) | Kondisi drainase | `baik`, `cukup baik`, `buruk`, `tidak ada` |
| `panjang_m` | desimal | Panjang ruas hasil hitung | 262,1 – 1.234,3 |
| `keterangan` | teks | Catatan surveyor | bebas |
| `waktu_survey` | tanggal-waktu (WIB) | Waktu ruas direkam | `2026-10-08T11:29:41+07:00` |

## 3. Pemukiman (`pemukiman`)

Geometri: **Polygon** · Jumlah: **11 area**

| Kolom | Tipe | Keterangan | Nilai yang diizinkan / contoh |
|---|---|---|---|
| `kode` | teks | ID unik | `A01` – `A11` |
| `nama` | teks | Nama kawasan pemukiman | `Mutiara Indah 2`, `Sepakat 1`, `Komplek Riau Lestari A`, `Marbung 1` |
| `luas_m2` | desimal | Luas hasil hitung | 983,4 – 5.660,1 |
| `ruas_terdekat` | teks | Ruas terdekat (≤ 50 m) | `L02` – `L06` |
| `waktu_survey` | tanggal-waktu (WIB) | Waktu area direkam | `2026-10-08T15:52:09+07:00` |

## 4. Pembersihan data yang dilakukan

1. Titik percobaan "Lobang 1" dan "Tanda tempat 1" dibuang.
2. Ejaan nama dirapikan ("Lobang" → "Lubang", "Jala rusa 17" → "Jalan rusak 17"); nama asli disimpan di `nama_asli`.
3. Kode ruas diseragamkan menjadi huruf besar (`l01` → `L01`); lebar diubah dari teks ("10 meter") menjadi angka.
4. Titik ganda berturut-turut pada garis dan polygon dihapus; polygon A03 diperbaiki karena tidak valid.
5. Panjang dan luas dihitung ulang dari geometri agar satu sumber.
6. Foto diambil dari ekspor KMZ Avenza, diputar sesuai EXIF, diperkecil ke maks. 1280 px, dan dinamai sesuai `kode` titik.
7. Dua titik "Rambu" berupa lampu lalu lintas, tetap dikategorikan Rambu (berbeda dari lampu jalan).
8. Keterangan Jl. Mutiara menyebut "banyak lubang", tetapi tidak ada titik lubang yang terekam di ruas ini (batas jumlah titik survey). Dicatat sebagai batasan.
