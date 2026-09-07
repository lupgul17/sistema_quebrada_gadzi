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
  .header { text-align: center; margin-bottom: 18px; }
  .header img { max-height: 60px; margin-bottom: 6px; }
  .header h1 { color: #093509; margin: 4px 0; font-size: 18px; }
  .header p { margin: 2px 0; color: #666; font-size: 11px; }
  table { width: 100%; border-collapse: collapse; }
  th { background: #093509; color: white; text-align: left; padding: 5px 6px; font-size: 9px; text-transform: uppercase; }
  td { padding: 4px 6px; border-bottom: 1px solid #eee; }
  tr:nth-child(even) { background: #fafafa; }
  .footer { margin-top: 15px; font-size: 8px; color: #999; text-align: right; }
</style>
</head>
<body>
  <div class="header">
    <img src="${d.logoUrl}" alt="Logo" />
    <h1>${d.titulo}</h1>
    ${d.subtitulo ? `<p>${d.subtitulo}</p>` : ''}
  </div>
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