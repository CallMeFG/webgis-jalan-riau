-- ===============================================================
-- 06_analisis.sql — Langkah 19–22: fungsi analisis spasial
--   19. buffer_lampu / penerangan_ruas    (buffer)
--   20. kerusakan_segmen                  (spatial query)
--   21. pemukiman_terdampak               (buffer + overlay intersect)
--   22. prioritas_segmen / prioritas_ruas (weighted scoring)
-- Bobot: Saleh, Majid & Firdasari (2013), Jurnal Transportasi 13(2): 75–84
-- Jalankan setelah 01–05. Aman dijalankan ulang.
-- ===============================================================


-- ---------------------------------------------------------------
-- 0. Tabel bobot kriteria (dari jurnal) — dasar perhitungan skor
-- ---------------------------------------------------------------
create table if not exists public.bobot_kriteria (
  kode          text primary key,
  nama          text not null,
  induk         text,                 -- null = kriteria utama; isi = sub-kriteria dari kriteria itu
  bobot_jurnal  numeric(5,3) not null,
  dipakai       boolean not null default true,
  catatan       text
);

insert into public.bobot_kriteria (kode, nama, induk, bobot_jurnal, dipakai, catatan) values
  ('kondisi_jalan',   'Kondisi jalan',        null,              0.454, true,  'Dinilai dari titik lubang & jalan rusak per 100 m'),
  ('volume_lalin',    'Volume lalu lintas',   null,              0.255, true,  'Dinilai dari atribut kepadatan'),
  ('tata_guna_lahan', 'Tata guna lahan',      null,              0.158, true,  'Dinilai dari guna lahan dominan di sisi ruas'),
  ('kebijakan',       'Kebijakan',            null,              0.133, false, 'Tidak dipakai: tidak ada data kebijakan per ruas'),
  ('lubang',          'Lubang',               'kondisi_jalan',   0.558, true,  'Jenis titik "Lubang jalan"'),
  ('amblas',          'Amblas',               'kondisi_jalan',   0.352, true,  'Digabung dengan retak menjadi "Jalan rusak"'),
  ('retak',           'Retak',                'kondisi_jalan',   0.090, true,  'Digabung dengan amblas menjadi "Jalan rusak"'),
  ('permukiman',      'Pembangunan & permukiman', 'tata_guna_lahan', 0.409, true, null),
  ('perdagangan',     'Perdagangan',          'tata_guna_lahan', 0.325, true,  null)
on conflict (kode) do update
  set nama = excluded.nama, induk = excluded.induk, bobot_jurnal = excluded.bobot_jurnal,
      dipakai = excluded.dipakai, catatan = excluded.catatan;

alter table public.bobot_kriteria enable row level security;
drop policy if exists "baca publik" on public.bobot_kriteria;
create policy "baca publik" on public.bobot_kriteria for select to anon, authenticated using (true);

-- Bobot kriteria utama setelah "kebijakan" dibuang dan dinormalisasi ulang (total = 1)
create or replace view public.v_bobot_dipakai
with (security_invoker = true) as
select kode, nama, bobot_jurnal,
       round(bobot_jurnal / sum(bobot_jurnal) over (), 3) as bobot_dipakai
from public.bobot_kriteria
where induk is null and dipakai;


-- ---------------------------------------------------------------
-- 19. Buffer lampu jalan
-- ---------------------------------------------------------------
-- Area jangkauan semua lampu (satu polygon gabungan)
create or replace function public.buffer_lampu(radius_m double precision default 25)
returns json
language sql stable
set search_path = public, extensions
as $$
  select json_build_object('type', 'FeatureCollection', 'features',
           coalesce(json_agg(ST_AsGeoJSON(q.*, 'geom', 7)::json), '[]'::json))
  from (
    select radius_m as radius_m,
           count(*) as jumlah_lampu,
           ST_Union(ST_Buffer(geom::geography, radius_m)::geometry) as geom
    from public.titik_infrastruktur
    where jenis = 'Lampu jalan'
  ) q
  where q.geom is not null;
$$;

-- Bagian tiap ruas yang TIDAK terjangkau lampu (geometri = ruas yang gelap)
create or replace function public.penerangan_ruas(radius_m double precision default 25)
returns json
language sql stable
set search_path = public, extensions
as $$
  with jangkauan as (
    select ST_Union(ST_Buffer(geom::geography, radius_m)::geometry) as g
    from public.titik_infrastruktur
    where jenis = 'Lampu jalan'
  )
  select json_build_object('type', 'FeatureCollection', 'features',
           coalesce(json_agg(ST_AsGeoJSON(q.*, 'geom', 7)::json order by q.kode), '[]'::json))
  from (
    select r.kode, r.nama, r.panjang_m,
           round(ST_Length(d.gelap::geography)::numeric, 1)                                   as panjang_gelap_m,
           round((100 * ST_Length(d.gelap::geography) / ST_Length(r.geom::geography))::numeric) as persen_gelap,
           radius_m                                                                           as radius_m,
           d.gelap                                                                            as geom
    from public.ruas_jalan r
    cross join jangkauan j
    cross join lateral (select coalesce(ST_Difference(r.geom, j.g), r.geom) as gelap) d
  ) q;
$$;


-- ---------------------------------------------------------------
-- 20. Kerusakan per segmen (spatial query)
-- Tiap titik lubang/jalan rusak masuk ke SATU segmen terdekat
-- yang jaraknya <= radius_m, supaya tidak terhitung dua kali.
-- ---------------------------------------------------------------
create or replace function public.hitung_kerusakan_segmen(radius_m double precision default 15)
returns table (
  id integer, ruas_kode text, urutan integer, panjang_m numeric,
  jumlah_lubang integer, jumlah_rusak integer, kerusakan_per_100m numeric,
  geom extensions.geometry
)
language sql stable
set search_path = public, extensions
as $$
  with sub as (
    select max(bobot_jurnal) filter (where kode = 'lubang')                    as w_lubang,
           sum(bobot_jurnal) filter (where kode in ('amblas', 'retak'))        as w_rusak
    from public.bobot_kriteria
  ),
  titik_segmen as (
    select t.jenis, s.id as segmen_id
    from public.titik_infrastruktur t
    cross join lateral (
      select s.id, s.geom from public.segmen_jalan s
      order by s.geom <-> t.geom
      limit 1
    ) s
    where t.jenis in ('Lubang jalan', 'Jalan rusak')
      and ST_DWithin(t.geom::geography, s.geom::geography, radius_m)
  )
  select s.id, s.ruas_kode, s.urutan, s.panjang_m,
         count(ts.*) filter (where ts.jenis = 'Lubang jalan')::int as jumlah_lubang,
         count(ts.*) filter (where ts.jenis = 'Jalan rusak')::int  as jumlah_rusak,
         round(((count(ts.*) filter (where ts.jenis = 'Lubang jalan') * sub.w_lubang
               + count(ts.*) filter (where ts.jenis = 'Jalan rusak')  * sub.w_rusak)
               / s.panjang_m * 100)::numeric, 3)                     as kerusakan_per_100m,
         s.geom
  from public.segmen_jalan s
  cross join sub
  left join titik_segmen ts on ts.segmen_id = s.id
  group by s.id, s.ruas_kode, s.urutan, s.panjang_m, s.geom, sub.w_lubang, sub.w_rusak;
$$;

create or replace function public.kerusakan_segmen(radius_m double precision default 15)
returns json
language sql stable
set search_path = public, extensions
as $$
  select json_build_object('type', 'FeatureCollection', 'features',
           coalesce(json_agg(ST_AsGeoJSON(k.*, 'geom', 7)::json order by k.ruas_kode, k.urutan), '[]'::json))
  from public.hitung_kerusakan_segmen(radius_m) k;
$$;


-- ---------------------------------------------------------------
-- 21. Pemukiman terdampak (buffer kerusakan ∩ pemukiman)
-- ---------------------------------------------------------------
create or replace function public.pemukiman_terdampak(radius_m double precision default 50)
returns json
language sql stable
set search_path = public, extensions
as $$
  with zona as (
    select ST_Union(ST_Buffer(geom::geography, radius_m)::geometry) as g
    from public.titik_infrastruktur
    where jenis in ('Lubang jalan', 'Jalan rusak')
  )
  select json_build_object('type', 'FeatureCollection', 'features',
           coalesce(json_agg(ST_AsGeoJSON(q.*, 'geom', 7)::json order by q.jumlah_kerusakan desc, q.kode), '[]'::json))
  from (
    select p.kode, p.nama, p.luas_m2,
           (select count(*) from public.titik_infrastruktur t
             where t.jenis in ('Lubang jalan', 'Jalan rusak')
               and ST_DWithin(t.geom::geography, p.geom::geography, radius_m))::int       as jumlah_kerusakan,
           round(coalesce(ST_Area(ST_Intersection(p.geom, z.g)::geography), 0)::numeric, 1) as luas_terdampak_m2,
           round((100 * coalesce(ST_Area(ST_Intersection(p.geom, z.g)::geography), 0) / p.luas_m2)::numeric) as persen_terdampak,
           radius_m as radius_m,
           p.geom
    from public.pemukiman p
    cross join zona z
  ) q;
$$;


-- ---------------------------------------------------------------
-- 22. Skor prioritas (weighted scoring)
-- skor = w_kondisi × nilai_kondisi + w_lalin × nilai_lalin + w_lahan × nilai_lahan
--   nilai_kondisi = kerusakan per 100 m ÷ nilai terbesar
--   nilai_lalin   = rendah 0 · sedang 0,5 · tinggi 1
--   nilai_lahan   = sub-bobot guna lahan ÷ sub-bobot permukiman
-- Kelas: Tinggi ≥ 0,66 · Sedang ≥ 0,33 · Rendah < 0,33
-- ---------------------------------------------------------------
create or replace function public.kelas_prioritas(skor numeric)
returns text
language sql immutable
as $$
  select case when skor >= 0.66 then 'Tinggi' when skor >= 0.33 then 'Sedang' else 'Rendah' end;
$$;

-- Per segmen (untuk peta)
create or replace function public.prioritas_segmen(filter_kelas text default null)
returns json
language sql stable
set search_path = public, extensions
as $$
  with w as (
    select max(bobot_dipakai) filter (where kode = 'kondisi_jalan')   as w_kondisi,
           max(bobot_dipakai) filter (where kode = 'volume_lalin')    as w_lalin,
           max(bobot_dipakai) filter (where kode = 'tata_guna_lahan') as w_lahan
    from public.v_bobot_dipakai
  ),
  lahan as (
    select kode, bobot_jurnal / (select bobot_jurnal from public.bobot_kriteria where kode = 'permukiman') as nilai
    from public.bobot_kriteria where induk = 'tata_guna_lahan'
  ),
  k as (select * from public.hitung_kerusakan_segmen(15)),
  dasar as (
    select k.id, k.ruas_kode, r.nama as nama_ruas, k.urutan, k.panjang_m,
           k.jumlah_lubang, k.jumlah_rusak, k.kerusakan_per_100m,
           coalesce(k.kerusakan_per_100m / nullif(max(k.kerusakan_per_100m) over (), 0), 0) as nilai_kondisi,
           case r.kepadatan when 'tinggi' then 1 when 'sedang' then 0.5 else 0 end          as nilai_lalin,
           l.nilai                                                                          as nilai_lahan,
           k.geom
    from k
    join public.ruas_jalan r on r.kode = k.ruas_kode
    join lahan l on l.kode = r.guna_lahan
  ),
  hasil as (
    select d.*, round(w.w_kondisi * d.nilai_kondisi + w.w_lalin * d.nilai_lalin + w.w_lahan * d.nilai_lahan, 2) as skor
    from dasar d cross join w
  )
  select json_build_object('type', 'FeatureCollection', 'features',
           coalesce(json_agg(ST_AsGeoJSON(q.*, 'geom', 7)::json order by q.skor desc, q.ruas_kode, q.urutan), '[]'::json))
  from (
    select h.id, h.ruas_kode, h.nama_ruas, h.urutan, h.panjang_m, h.jumlah_lubang, h.jumlah_rusak,
           h.kerusakan_per_100m, round(h.nilai_kondisi, 2) as nilai_kondisi, h.nilai_lalin,
           round(h.nilai_lahan, 2) as nilai_lahan, h.skor, public.kelas_prioritas(h.skor) as kelas, h.geom
    from hasil h
  ) q
  where filter_kelas is null or q.kelas = filter_kelas;
$$;

-- Per ruas (untuk tabel di halaman Hasil Analisis)
create or replace function public.prioritas_ruas()
returns json
language sql stable
set search_path = public, extensions
as $$
  with w as (
    select max(bobot_dipakai) filter (where kode = 'kondisi_jalan')   as w_kondisi,
           max(bobot_dipakai) filter (where kode = 'volume_lalin')    as w_lalin,
           max(bobot_dipakai) filter (where kode = 'tata_guna_lahan') as w_lahan
    from public.v_bobot_dipakai
  ),
  sub as (
    select max(bobot_jurnal) filter (where kode = 'lubang')             as w_lubang,
           sum(bobot_jurnal) filter (where kode in ('amblas', 'retak')) as w_rusak
    from public.bobot_kriteria
  ),
  lahan as (
    select kode, bobot_jurnal / (select bobot_jurnal from public.bobot_kriteria where kode = 'permukiman') as nilai
    from public.bobot_kriteria where induk = 'tata_guna_lahan'
  ),
  k as (
    select ruas_kode, sum(jumlah_lubang)::int as jumlah_lubang, sum(jumlah_rusak)::int as jumlah_rusak
    from public.hitung_kerusakan_segmen(15)
    group by ruas_kode
  ),
  dasar as (
    select r.kode, r.nama, r.panjang_m, r.kepadatan, r.guna_lahan, r.drainase,
           k.jumlah_lubang, k.jumlah_rusak,
           round(((k.jumlah_lubang * sub.w_lubang + k.jumlah_rusak * sub.w_rusak) / r.panjang_m * 100)::numeric, 3) as kerusakan_per_100m,
           case r.kepadatan when 'tinggi' then 1 when 'sedang' then 0.5 else 0 end as nilai_lalin,
           l.nilai as nilai_lahan,
           r.geom
    from public.ruas_jalan r
    join k on k.ruas_kode = r.kode
    join lahan l on l.kode = r.guna_lahan
    cross join sub
  ),
  hasil as (
    select d.*,
           coalesce(d.kerusakan_per_100m / nullif(max(d.kerusakan_per_100m) over (), 0), 0) as nilai_kondisi
    from dasar d
  )
  select json_build_object('type', 'FeatureCollection', 'features',
           coalesce(json_agg(ST_AsGeoJSON(q.*, 'geom', 7)::json order by q.skor desc), '[]'::json))
  from (
    select h.kode, h.nama, h.panjang_m, h.kepadatan, h.guna_lahan, h.drainase,
           h.jumlah_lubang, h.jumlah_rusak, h.kerusakan_per_100m,
           round(h.nilai_kondisi, 2) as nilai_kondisi, h.nilai_lalin, round(h.nilai_lahan, 2) as nilai_lahan,
           round(w.w_kondisi * h.nilai_kondisi + w.w_lalin * h.nilai_lalin + w.w_lahan * h.nilai_lahan, 2) as skor,
           public.kelas_prioritas(round(w.w_kondisi * h.nilai_kondisi + w.w_lalin * h.nilai_lalin + w.w_lahan * h.nilai_lahan, 2)) as kelas,
           h.geom
    from hasil h cross join w
  ) q;
$$;


-- ---------------------------------------------------------------
-- Izin panggil untuk website (anon)
-- ---------------------------------------------------------------
grant select on public.v_bobot_dipakai to anon, authenticated;
grant execute on function public.buffer_lampu(double precision)            to anon, authenticated;
grant execute on function public.penerangan_ruas(double precision)         to anon, authenticated;
grant execute on function public.hitung_kerusakan_segmen(double precision) to anon, authenticated;
grant execute on function public.kerusakan_segmen(double precision)        to anon, authenticated;
grant execute on function public.pemukiman_terdampak(double precision)     to anon, authenticated;
grant execute on function public.kelas_prioritas(numeric)                  to anon, authenticated;
grant execute on function public.prioritas_segmen(text)                    to anon, authenticated;
grant execute on function public.prioritas_ruas()                          to anon, authenticated;


-- ---------------------------------------------------------------
-- Cek hasil
-- ---------------------------------------------------------------
select * from public.v_bobot_dipakai;

select f->'properties'->>'kode' as ruas, f->'properties'->>'nama' as nama,
       f->'properties'->>'jumlah_lubang' as lubang, f->'properties'->>'jumlah_rusak' as rusak,
       f->'properties'->>'skor' as skor, f->'properties'->>'kelas' as kelas
from json_array_elements(public.prioritas_ruas()->'features') f;
