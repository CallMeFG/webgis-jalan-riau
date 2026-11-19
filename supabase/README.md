# Supabase

Folder ini akan berisi file SQL (langkah 10–22):

- `01_tabel.sql` — tabel `titik_infrastruktur`, `ruas_jalan`, `segmen_jalan`, `pemukiman` (PostGIS, EPSG:4326)
- `02_data.sql` — isi data dari `public/data/*.geojson`
- `03_fungsi_layer.sql` — fungsi RPC `get_titik_infrastruktur`, `get_ruas_jalan`, `get_pemukiman`
- `04_fungsi_analisis.sql` — `buffer_lampu`, `kerusakan_per_segmen`, `pemukiman_terdampak`, `prioritas`

Belum diisi.
