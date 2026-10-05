import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const RUTA_LOGO = path.join(__dirname, '..', '..', 'assets', 'logo-quebrada.png');

let logoEnCache: string | null = null;

/** Logo de La Quebrada como data URI, para incrustarlo en los PDF. Se lee del disco una sola vez. */
export function logoDataUri(): string {
  if (!logoEnCache) {
    logoEnCache = `data:image/png;base64,${fs.readFileSync(RUTA_LOGO).toString('base64')}`;
  }
  return logoEnCache;
}
