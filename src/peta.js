// ===============================================================
// Halaman Peta — OpenLayers
// Struktur mengikuti modul P10/P12: VectorLayer + VectorSource +
// GeoJSON, popup lewat Overlay, checkbox untuk visibilitas layer.
// ===============================================================
import 'bootstrap/dist/css/bootstrap.min.css';
import 'ol/ol.css';
import './style.css';

import { Map, View } from 'ol';
import TileLayer from 'ol/layer/Tile';
import VectorLayer from 'ol/layer/Vector';
import OSM from 'ol/source/OSM';
import VectorSource from 'ol/source/Vector';
import GeoJSON from 'ol/format/GeoJSON.js';
import Overlay from 'ol/Overlay.js';
import { fromLonLat } from 'ol/proj.js';

import { ambilLayer } from './lib/data.js';
import { gayaTitik, gayaRuas, gayaPemukiman, IKON, LEGENDA_RUAS } from './lib/gaya.js';

// ---------------------------------------------------------------
// 1. Layer data (urutan: pemukiman di bawah, titik di atas)
// ---------------------------------------------------------------
const format = new GeoJSON({ featureProjection: 'EPSG:3857' });

function buatLayer(nama, style) {
  return new VectorLayer({ source: new VectorSource(), style, properties: { nama } });
}

const pemukiman = buatLayer('pemukiman', gayaPemukiman);
const ruas = buatLayer('ruas_jalan', gayaRuas);
const titik = buatLayer('titik_infrastruktur', gayaTitik);

// ---------------------------------------------------------------
// 2. Popup (Overlay)
// ---------------------------------------------------------------
const container = document.getElementById('popup');
const contentElement = document.getElementById('popup-content');
const closer = document.getElementById('popup-closer');

const overlay = new Overlay({
  element: container,
  autoPan: { animation: { duration: 250 } },
});

closer.onclick = function () {
  overlay.setPosition(undefined);
  closer.blur();
  return false;
};

// ---------------------------------------------------------------
// 3. Map dan View (tengah kawasan Jalan Riau)
// ---------------------------------------------------------------
const map = new Map({
  target: 'map',
  layers: [new TileLayer({ source: new OSM() }), pemukiman, ruas, titik],
  overlays: [overlay],
  view: new View({ center: fromLonLat([101.4295, 0.5335]), zoom: 16 }),
});
// TODO langkah 18: pilihan basemap satelit

// ---------------------------------------------------------------
// 4. Isi layer dari sumber data (statis atau Supabase)
// ---------------------------------------------------------------
const pasangan = [
  [pemukiman, 'pemukiman'],
  [ruas, 'ruas_jalan'],
  [titik, 'titik_infrastruktur'],
];
await Promise.all(
  pasangan.map(async ([layer, nama]) => {
    const fc = await ambilLayer(nama);
    layer.getSource().addFeatures(format.readFeatures(fc));
  }),
);

// ---------------------------------------------------------------
// 5. Isi popup per jenis data
// ---------------------------------------------------------------
const baris = (label, nilai) => (nilai === null || nilai === undefined || nilai === '' ? '' : `<tr><td class="text-secondary">${label}</td><td>${nilai}</td></tr>`);
const tanggal = (iso) => new Date(iso).toLocaleString('id-ID', { dateStyle: 'medium', timeStyle: 'short' });

function isiPopup(feature, namaLayer) {
  const p = feature.getProperties();
  if (namaLayer === 'titik_infrastruktur') {
    return `<strong>${p.kode} · ${p.nama}</strong><table>${baris('Jenis', p.jenis)}${baris('Keterangan', p.keterangan)}${baris('Ruas', p.ruas_kode)}${baris('Waktu survey', tanggal(p.waktu_survey))}</table>${p.foto ? `<img src="${p.foto}" alt="Foto ${p.nama}">` : '<p class="small text-secondary mt-2 mb-0">Tidak ada foto</p>'}`;
  }
  if (namaLayer === 'ruas_jalan') {
    return `<strong>${p.kode} · ${p.nama}</strong><table>${baris('Jenis', p.jenis_jalan)}${baris('Kondisi', p.kondisi)}${baris('Lebar', p.lebar_m + ' m')}${baris('Panjang', p.panjang_m.toLocaleString('id-ID') + ' m')}${baris('Kepadatan', p.kepadatan)}${baris('Drainase', p.drainase)}${baris('Keterangan', p.keterangan)}</table>`;
  }
  return `<strong>${p.kode} · ${p.nama}</strong><table>${baris('Luas', p.luas_m2.toLocaleString('id-ID') + ' m²')}${baris('Ruas terdekat', p.ruas_terdekat)}</table>`;
}

map.on('singleclick', function (evt) {
  let hasil = null;
  map.forEachFeatureAtPixel(
    evt.pixel,
    (feature, layer) => {
      hasil = { feature, nama: layer.get('nama') };
      return true;
    },
    { layerFilter: (layer) => layer.get('nama') !== undefined },
  );
  if (!hasil) {
    overlay.setPosition(undefined);
    return;
  }
  contentElement.innerHTML = isiPopup(hasil.feature, hasil.nama);
  overlay.setPosition(evt.coordinate);
});

map.on('pointermove', function (evt) {
  map.getTargetElement().style.cursor = map.hasFeatureAtPixel(evt.pixel) ? 'pointer' : '';
});

// ---------------------------------------------------------------
// 6. Checkbox visibilitas layer (pola modul P12)
// ---------------------------------------------------------------
[
  ['lyr-titik', titik],
  ['lyr-ruas', ruas],
  ['lyr-pemukiman', pemukiman],
].forEach(([id, layer]) => {
  const cb = document.getElementById(id);
  cb.addEventListener('change', () => layer.setVisible(cb.checked));
});

// ---------------------------------------------------------------
// 7. Legenda
// ---------------------------------------------------------------
document.getElementById('legenda').innerHTML =
  Object.entries(IKON).map(([jenis, src]) => `<div class="legenda-item"><img src="${src}" alt="">${jenis}</div>`).join('') +
  Object.entries(LEGENDA_RUAS).map(([k, warna]) => `<div class="legenda-item"><span class="legenda-garis" style="background:${warna}"></span>Ruas kondisi ${k}</div>`).join('') +
  '<div class="legenda-item"><span class="legenda-garis" style="background:rgba(91,123,166,.5);height:14px"></span>Pemukiman</div>';

// TODO langkah 16: filter jenis titik, kondisi ruas, kelas prioritas
// TODO langkah 19–23: layer buffer lampu, heatmap, segmen prioritas
