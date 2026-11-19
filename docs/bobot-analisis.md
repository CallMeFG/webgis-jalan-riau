# Bobot Analisis Prioritas Perbaikan Jalan

## Rujukan

Saleh, S. M., Majid, I. A., & Firdasari. (2013). Penerapan Metode Analytical Hierarchy Process dalam Penentuan Prioritas Penanganan Pemeliharaan Jalan di Kota Banda Aceh. *Jurnal Transportasi*, 13(2), 75–84.
Unduh: https://core.ac.uk/download/235703146.pdf

Bobot dalam jurnal diperoleh dengan AHP dari 20 responden (instansi terkait, kantor kecamatan, masyarakat, akademisi), semua rasio konsistensi (CR) < 0,1.

## Bobot dari jurnal

| Kriteria | Bobot jurnal | Sub-kriteria (bobot) |
|---|---|---|
| Kondisi jalan | 0,454 | Lubang 0,558 · Amblas 0,352 · Retak 0,090 |
| Volume lalu lintas | 0,255 | Truk ringan & mobil 0,496 · Truk sedang & berat 0,234 · Bus 0,161 · Sepeda motor 0,109 |
| Tata guna lahan | 0,158 | Pembangunan & permukiman 0,409 · Perdagangan 0,325 · Pusat ekonomi rakyat 0,139 · Pariwisata 0,127 |
| Kebijakan | 0,133 | Bottom-up/Musrenbang 0,647 · Top-down 0,257 · Lainnya 0,096 |

## Penyesuaian untuk proyek ini

Kriteria **kebijakan** tidak dipakai karena tidak ada data kebijakan per ruas. Tiga kriteria lain dinormalisasi ulang supaya totalnya 1 (dibagi 0,867):

| Kriteria | Bobot dipakai | Data dari survey | Cara memberi nilai (0–1) |
|---|---|---|---|
| Kondisi jalan | **0,524** | Titik lubang & jalan rusak per ruas | Kerusakan berbobot per 100 m = (lubang × 0,558 + jalan rusak × 0,442) / panjang × 100, lalu dibagi nilai terbesar. Jalan rusak = gabungan sub-kriteria amblas + retak (0,352 + 0,090) |
| Volume lalu lintas | **0,294** | Atribut `kepadatan` | rendah 0 · sedang 0,5 · tinggi 1 |
| Tata guna lahan | **0,182** | Guna lahan dominan di sisi ruas | permukiman 1,00 (0,409/0,409) · perdagangan 0,79 (0,325/0,409) |

Skor prioritas = 0,524 × kondisi + 0,294 × lalu lintas + 0,182 × tata guna lahan.
Kelas: **Tinggi** ≥ 0,66 · **Sedang** 0,33 – < 0,66 · **Rendah** < 0,33.

Guna lahan per ruas (perlu dikonfirmasi kelompok): L01 Jl. Riau = perdagangan (ruko); L02–L06 = permukiman.

## Hasil sementara (data 19 Nov 2026)

| Ruas | Lubang | Jalan rusak | Kerusakan /100 m | Kepadatan | Guna lahan | Skor | Kelas |
|---|---|---|---|---|---|---|---|
| L01 Jl. Riau | 9 | 7 | 0,66 | tinggi | perdagangan | 0,96 | Tinggi |
| L02 Gg. Darul Akbar | 3 | 0 | 0,64 | sedang | permukiman | 0,84 | Tinggi |
| L04 Gg. Sepakat | 0 | 3 | 0,50 | sedang | permukiman | 0,73 | Tinggi |
| L03 Jl. Mutiara | 0 | 0 | 0,00 | tinggi | permukiman | 0,48 | Sedang |
| L06 Jl. Haji Guru | 3 | 0 | 0,17 | sedang | permukiman | 0,47 | Sedang |
| L05 Gg. Geliga | 0 | 0 | 0,00 | rendah | permukiman | 0,18 | Rendah |

## Analisis pendukung (tidak masuk skor)

Penerangan dan drainase tidak ada di jurnal, jadi tidak ikut skor. Keduanya tetap disajikan sebagai analisis terpisah:
- **Buffer lampu jalan** (radius 25 m): persen panjang ruas di luar jangkauan lampu → rekomendasi penambahan lampu.
- **Drainase**: ditampilkan di popup ruas dan dibahas di BAB 4 sebagai penyebab kerusakan (2 titik jalan rusak tercatat akibat drainase).
