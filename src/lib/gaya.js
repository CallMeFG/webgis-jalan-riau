// ===============================================================
// Gaya (simbol) setiap layer — ketentuan no. 4 visualisasi data
// ===============================================================
import { Fill, Icon, Stroke, Style, Text } from 'ol/style.js';

// ---------- Titik infrastruktur: ikon berbeda per jenis ----------
export const IKON = {
  'Lubang jalan': 'icon/lubang.svg',
  'Jalan rusak': 'icon/rusak.svg',
  'Lampu jalan': 'icon/lampu.svg',
  'Halte': 'icon/halte.svg',
  'Rambu': 'icon/rambu.svg',
};

const cacheIkon = {};
export function gayaTitik(feature) {
  const jenis = feature.get('jenis');
  if (!cacheIkon[jenis]) {
    cacheIkon[jenis] = new Style({
      image: new Icon({ src: IKON[jenis], width: 24, height: 24, anchor: [0.5, 0.5] }),
    });
  }
  return cacheIkon[jenis];
}

// ---------- Ruas jalan: warna per kondisi survey, tebal per kepadatan ----------
// TODO langkah 22: ganti warna dengan kelas prioritas (Tinggi/Sedang/Rendah)
const WARNA_KONDISI = { rusak: '#B42318', sedang: '#E8A33D', bagus: '#2E7D5B' };
const TEBAL_KEPADATAN = { rendah: 3, sedang: 5, tinggi: 8 };

export function gayaRuas(feature) {
  return [
    new Style({ stroke: new Stroke({ color: '#ffffff', width: TEBAL_KEPADATAN[feature.get('kepadatan')] + 3 }) }),
    new Style({
      stroke: new Stroke({
        color: WARNA_KONDISI[feature.get('kondisi')] || '#666666',
        width: TEBAL_KEPADATAN[feature.get('kepadatan')] || 4,
      }),
    }),
  ];
}

// ---------- Pemukiman: polygon semi-transparan + label ----------
export function gayaPemukiman(feature) {
  return new Style({
    fill: new Fill({ color: 'rgba(91, 123, 166, 0.30)' }),
    stroke: new Stroke({ color: '#5B7BA6', width: 1.2 }),
    text: new Text({
      text: feature.get('nama'),
      font: '600 11px sans-serif',
      fill: new Fill({ color: '#1B1F24' }),
      stroke: new Stroke({ color: '#ffffff', width: 3 }),
      overflow: false,
    }),
  });
}

export const LEGENDA_RUAS = WARNA_KONDISI;
