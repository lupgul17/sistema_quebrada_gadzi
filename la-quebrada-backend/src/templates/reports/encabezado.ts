/**
 * Encabezado compartido de los PDF: logo chico a la izquierda y título/datos a la derecha en una
 * sola franja, para no gastar un tercio de la hoja en el membrete.
 */
export const ENCABEZADO_CSS = `
  .encabezado {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 20px;
    padding-bottom: 10px;
    margin-bottom: 16px;
    border-bottom: 2px solid #093509;
  }
  .encabezado img { max-height: 56px; display: block; }
  .encabezado .enc-derecha { text-align: right; }
  .encabezado .enc-etiqueta { font-size: 9px; letter-spacing: 1px; color: #777; text-transform: uppercase; margin: 0; }
  .encabezado h1 { color: #093509; margin: 2px 0 0; font-size: 17px; }
  .encabezado .enc-sub { margin: 2px 0 0; color: #666; font-size: 10px; }
`;

interface Encabezado {
  logoUrl: string;
  /** Texto chico arriba del título (ej. "Cotización de servicio") */
  etiqueta?: string;
  titulo: string;
  /** Líneas chicas debajo del título (ej. versión y fecha) */
  lineas?: (string | null | undefined)[];
}

export function encabezadoHtml(e: Encabezado): string {
  const lineas = (e.lineas ?? []).filter(Boolean);
  return `
  <div class="encabezado">
    <img src="${e.logoUrl}" alt="Logo" />
    <div class="enc-derecha">
      ${e.etiqueta ? `<p class="enc-etiqueta">${e.etiqueta}</p>` : ''}
      <h1>${e.titulo}</h1>
      ${lineas.map((l) => `<p class="enc-sub">${l}</p>`).join('')}
    </div>
  </div>`;
}
