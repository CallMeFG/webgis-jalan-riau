-- ===============================================================
-- 05_segmen.sql — Langkah 12: pecah ruas jalan menjadi segmen ±50 m
-- Setiap ruas dibagi rata menjadi n bagian, n = pembulatan ke atas
-- dari panjang/50, sehingga tiap segmen panjangnya ≤ 50 m.
-- Aman dijalankan ulang (segmen lama dihapus dulu).
-- ===============================================================

delete from public.segmen_jalan;

insert into public.segmen_jalan (ruas_kode, urutan, panjang_m, geom)
select
  r.kode,
  s.i + 1                                                   as urutan,
  round(extensions.ST_Length(x.seg::extensions.geography)::numeric, 1) as panjang_m,
  x.seg
from public.ruas_jalan r
cross join lateral (
  select ceil(extensions.ST_Length(r.geom::extensions.geography) / 50)::int as n
) k
cross join lateral generate_series(0, k.n - 1) as s(i)
cross join lateral (
  select extensions.ST_LineSubstring(r.geom, s.i::float8 / k.n, (s.i + 1)::float8 / k.n) as seg
) x;

-- Fungsi RPC untuk menampilkan segmen di peta
create or replace function public.get_segmen_jalan()
returns json
language sql
stable
set search_path = public, extensions
as $$
  select json_build_object(
    'type', 'FeatureCollection',
    'features', coalesce(json_agg(ST_AsGeoJSON(s.*, 'geom', 7)::json order by s.ruas_kode, s.urutan), '[]'::json)
  )
  from public.segmen_jalan s;
$$;

grant execute on function public.get_segmen_jalan() to anon, authenticated;

-- Cek jumlah dan panjang segmen per ruas
select ruas_kode,
       count(*)              as jumlah_segmen,
       min(panjang_m)        as terpendek_m,
       max(panjang_m)        as terpanjang_m,
       sum(panjang_m)        as total_m
from public.segmen_jalan
group by ruas_kode
order by ruas_kode;
