// ===============================================================
// Halaman Home — angka statistik diambil dari data
// ===============================================================
import 'bootstrap/dist/css/bootstrap.min.css';
import './style.css';
import { ambilLayer } from './lib/data.js';

const [titik, ruas, pemukiman] = await Promise.all([
  ambilLayer('titik_infrastruktur'),
  ambilLayer('ruas_jalan'),
  ambilLayer('pemukiman'),
]);

const hitungJenis = (jenis) => titik.features.filter((f) => f.properties.jenis === jenis).length;

const stat = {
  lubang: hitungJenis('Lubang jalan'),
  rusak: hitungJenis('Jalan rusak'),
  ruas: ruas.features.length,
  pemukiman: pemukiman.features.length,
};

document.querySelectorAll('[data-stat]').forEach((el) => {
  el.textContent = stat[el.dataset.stat];
});
