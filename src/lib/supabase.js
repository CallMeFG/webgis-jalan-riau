// ===============================================================
// Koneksi Supabase (langkah 10). Dipakai bila VITE_DATA_MODE=supabase.
// ===============================================================
import { createClient } from '@supabase/supabase-js';

const url = import.meta.env.VITE_SUPABASE_URL;
const key = import.meta.env.VITE_SUPABASE_ANON_KEY;

export const supabase = url && key ? createClient(url, key) : null;
