-- ===============================================================
-- 04_foto_storage.sql — Langkah 11: foto survey di Supabase Storage
-- Jalankan dalam DUA tahap:
--   Tahap A  -> jalankan dulu, lalu unggah foto lewat dashboard
--   Tahap B  -> jalankan setelah 38 foto selesai diunggah
-- ===============================================================

-- ---------- Tahap A: buat bucket publik "foto-survey" ----------
-- Publik = foto bisa dibuka lewat URL tanpa login (hanya baca).
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('foto-survey', 'foto-survey', true, 2097152, array['image/jpeg'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- Setelah ini: Storage > foto-survey > Upload files >
-- pilih semua file di folder public/foto (P01.jpg ... P41.jpg, total 38 file).


-- ---------- Tahap B: ubah kolom foto menjadi URL Supabase ----------
-- Jalankan HANYA setelah foto selesai diunggah.
update public.titik_infrastruktur
set foto = 'https://cgwbtnygggqmhbzthfny.supabase.co/storage/v1/object/public/foto-survey/' || kode || '.jpg'
where foto is not null;

-- Cek: harus 38 baris berisi URL, 3 baris kosong (lubang Jl. Haji Guru)
select count(*) filter (where foto like 'https://%') as foto_url,
       count(*) filter (where foto is null)          as tanpa_foto
from public.titik_infrastruktur;
