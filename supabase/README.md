# Supabase

Project: `webgis-jalan-riau` · Region: Southeast Asia (Singapore) · Database: `postgres`

## Urutan menjalankan (SQL Editor > New query > tempel > Run)

| File | Isi | Hasil yang diharapkan |
|---|---|---|
| `01_tabel.sql` | Aktifkan PostGIS, buat tabel `ruas_jalan`, `titik_infrastruktur`, `pemukiman`, `segmen_jalan`, indeks spasial, izin baca publik | "Success. No rows returned" (NOTICE "policy does not exist, skipping" itu normal) |
| `02_data.sql` | Isi data survey dari `public/data/*.geojson` | Tabel cek: ruas_jalan 6, titik_infrastruktur 41, pemukiman 11 |
| `03_fungsi_layer.sql` | Fungsi RPC `get_ruas_jalan`, `get_titik_infrastruktur`, `get_pemukiman` | "Success. No rows returned" |

Ketiga file aman dijalankan ulang. `02_data.sql` menghapus data lama dulu sebelum mengisi.

Uji cepat setelah semuanya jalan:

```sql
select json_array_length(get_titik_infrastruktur()->'features');  -- 41
```

## Menyambungkan website

1. Supabase: Project Settings > API (atau API Keys). Salin **Project URL** dan **anon / publishable key**.
2. Isi file `.env` di root proyek:
   ```
   VITE_DATA_MODE=supabase
   VITE_SUPABASE_URL=https://xxxx.supabase.co
   VITE_SUPABASE_ANON_KEY=kunci-anon-atau-publishable
   ```
3. Jalankan ulang `npm run dev`. Kalau Supabase gagal, website otomatis kembali memakai file GeoJSON.

Jangan pernah menaruh **service_role / secret key** di `.env` website atau di GitHub.

## Foto dan segmen (langkah 11–12)

| File | Isi | Hasil yang diharapkan |
|---|---|---|
| `04_foto_storage.sql` Tahap A | Buat bucket publik `foto-survey` | "Success" |
| (dashboard) | Storage > `foto-survey` > Upload files > pilih 38 file di `public/foto` | 38 file P01.jpg … P41.jpg |
| `04_foto_storage.sql` Tahap B | Ubah kolom `foto` jadi URL Supabase | Cek: foto_url 38, tanpa_foto 3 |
| `05_segmen.sql` | Pecah 6 ruas jadi segmen ≤ 50 m + fungsi `get_segmen_jalan` | 70 segmen (L01 25, L02 6, L03 7, L04 6, L05 6, L06 20) |

## Analisis spasial (langkah 19–22) — `06_analisis.sql`

Jalankan seluruh isi file sekaligus. Hasil cek di akhir: bobot dipakai 0,524 / 0,294 / 0,182 dan skor ruas L01 0,96 · L02 0,84 · L04 0,73 · L03 0,48 · L06 0,47 · L05 0,18.

| Fungsi RPC | Jenis analisis | Parameter (bawaan) | Isi hasil |
|---|---|---|---|
| `buffer_lampu` | Buffer | `radius_m` (25) | 1 polygon gabungan jangkauan 11 lampu |
| `penerangan_ruas` | Buffer + overlay (difference) | `radius_m` (25) | Bagian tiap ruas di luar jangkauan lampu, `persen_gelap` |
| `kerusakan_segmen` | Spatial query | `radius_m` (15) | 70 segmen + jumlah lubang/rusak + kerusakan per 100 m |
| `pemukiman_terdampak` | Buffer + overlay (intersect) | `radius_m` (50) | 11 pemukiman + jumlah kerusakan + persen luas terdampak |
| `prioritas_segmen` | Weighted scoring | `filter_kelas` (semua) | 70 segmen + skor + kelas (Tinggi 5 · Sedang 59 · Rendah 6) |
| `prioritas_ruas` | Weighted scoring | – | 6 ruas + skor + kelas, untuk tabel Hasil Analisis |

Tabel `bobot_kriteria` dan view `v_bobot_dipakai` menyimpan bobot dari Saleh dkk. (2013), jadi angka bobot bisa ditunjukkan langsung dari database.
