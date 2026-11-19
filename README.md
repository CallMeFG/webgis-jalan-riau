# WebGIS Jalan Riau

Pemetaan kondisi infrastruktur jalan dan prioritas perbaikan di Kawasan Jalan Riau, Kota Pekanbaru.
Proyek Akhir Bengkel Sistem Informasi Geografis — Kelompok 3, 3 TI B, Politeknik Caltex Riau.

## Menjalankan

Prasyarat: Node.js 20 atau lebih baru, Git.

```bash
npm install
cp .env.example .env     # Windows: copy .env.example .env
npm run dev
```

Buka alamat yang muncul di terminal (biasanya http://localhost:5173/).

- `index.html` → Home (profil web)
- `peta.html` → Peta
- `analisis.html` → Hasil Analisis

Secara bawaan data dibaca dari file GeoJSON di `public/data` (`VITE_DATA_MODE=static`).
Setelah Supabase siap (langkah 10), isi `VITE_SUPABASE_URL` dan `VITE_SUPABASE_ANON_KEY` di `.env`, lalu ubah `VITE_DATA_MODE=supabase`.

## Struktur folder

```
webgis-jalan-riau/
├─ index.html, peta.html, analisis.html   halaman
├─ src/
│  ├─ home.js, peta.js, analisis.js       logika tiap halaman
│  ├─ lib/data.js                         sumber data (statis / Supabase)
│  ├─ lib/supabase.js                     koneksi Supabase
│  ├─ lib/gaya.js                         simbol & warna layer
│  └─ style.css
├─ public/
│  ├─ data/      titik_infrastruktur, ruas_jalan, pemukiman (.geojson)
│  ├─ foto/      foto survey, nama = kode titik (P01.jpg ...)
│  └─ icon/      ikon titik per jenis (.svg)
├─ supabase/     SQL tabel & fungsi analisis (langkah 10–22)
└─ docs/
   ├─ ceklis.md          progres 40 langkah
   ├─ kamus-data.md      kamus data (BAB 3)
   └─ bobot-analisis.md  bobot dari Saleh dkk. (2013)
```

## Teknologi

Vite · OpenLayers 10 · Bootstrap 5 · Supabase (PostgreSQL + PostGIS). JavaScript biasa, tanpa framework JS.
