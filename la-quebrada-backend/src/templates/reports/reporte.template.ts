import { ENCABEZADO_CSS, encabezadoHtml } from './encabezado.js';
interface ReportePlantilla {
  titulo: string;
  subtitulo?: string;
  columnas: string[];
  filas: (string | number)[][];
  logoUrl: string;
}

export function armarHtmlReporte(d: ReportePlantilla): string {
  const filaHtml = (fila: (string | number)[]) => `
    <tr>${fila.map((celda) => `<td>${celda}</td>`).join('')}</tr>
  `;

  return `
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  body { font-family: Arial, sans-serif; font-size: 10px; color: #222; margin: 0; padding: 25px; }
  ${ENCABEZADO_CSS}
  table { width: 100%; border-collapse: collapse; }
  th { background: #093509; color: white; text-align: left; padding: 5px 6px; font-size: 9px; text-transform: uppercase; }
  td { padding: 4px 6px; border-bottom: 1px solid #eee; }
  tr:nth-child(even) { background: #fafafa; }
  .footer { margin-top: 15px; font-size: 8px; color: #999; text-align: right; }
</style>
</head>
<body>
  ${encabezadoHtml({ logoUrl: d.logoUrl, etiqueta: 'Reporte', titulo: d.titulo, lineas: [d.subtitulo] })}
  <table>
    <thead>
      <tr>${d.columnas.map((c) => `<th>${c}</th>`).join('')}</tr>
    </thead>
    <tbody>
      ${d.filas.map(filaHtml).join('')}
    </tbody>
  </table>
  <div class="footer">
    <p>Generado el ${new Date().toLocaleDateString('es-GT')} — La Quebrada / GADZI</p>
  </div>
</body>
</html>
  `;
}