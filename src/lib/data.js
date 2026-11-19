// ===============================================================
// Sumber data layer.
// - mode "static"  : baca file GeoJSON di public/data (cadangan demo)
// - mode "supabase": panggil fungsi SQL (RPC) di Supabase (langkah 10)
// Halaman lain cukup memanggil ambilLayer('titik_infrastruktur'), dst.
// ===============================================================
import { supabase } from './supabase.js';

const MODE = import.meta.env.VITE_DATA_MODE || 'static';

// Nama layer -> nama fungsi RPC di Supabase (dibuat di langkah 10)
const RPC = {
  titik_infrastruktur: 'get_titik_infrastruktur',
  ruas_jalan: 'get_ruas_jalan',
  pemukiman: 'get_pemukiman',
  segmen_jalan: 'get_segmen_jalan', // langkah 12 (file statis menyusul di langkah 27)
};

export async function ambilLayer(nama) {
  if (MODE === 'supabase' && supabase) {
    const { data, error } = await supabase.rpc(RPC[nama]);
    if (!error && data) return data; // fungsi RPC mengembalikan FeatureCollection
    console.warn(`Supabase gagal untuk ${nama}, pakai data statis.`, error);
  }
  const res = await fetch(`${import.meta.env.BASE_URL}data/${nama}.geojson`);
  return res.json();
}
