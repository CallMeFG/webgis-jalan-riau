import { resolve } from 'node:path';
import { defineConfig } from 'vite';

// Tiga halaman: Home, Peta, Hasil Analisis
export default defineConfig({
  build: {
    rollupOptions: {
      input: {
        home: resolve(import.meta.dirname, 'index.html'),
        peta: resolve(import.meta.dirname, 'peta.html'),
        analisis: resolve(import.meta.dirname, 'analisis.html'),
      },
    },
  },
});
