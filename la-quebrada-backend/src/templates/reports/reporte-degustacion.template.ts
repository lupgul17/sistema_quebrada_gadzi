interface ComponenteMenu {
  categoria: string;
  nombre: string;
}

interface MenuDegustacion {
  menu: string;
  es_adicional: boolean;
  componentes: ComponenteMenu[];
}

interface CardDegustacion {
  cliente: string;
  tipoEvento: string | null;
  fechaEvento: string;
  menus: MenuDegustacion[];
}

interface SesionDegustacion {
  titulo: string;
  cards: CardDegustacion[];
}

interface DatosDegustaciones {
  logoUrl: string;
  subtitulo: string;
  sesiones: SesionDegustacion[];
}

function agruparPorCategoria(componentes: ComponenteMenu[]): [string, string[]][] {
  const mapa = new Map<string, string[]>();
  for (const c of componentes) {
    if (!mapa.has(c.categoria)) mapa.set(c.categoria, []);
    mapa.get(c.categoria)!.push(c.nombre);
  }
  return Array.from(mapa.entries());
}

export function armarHtmlDegustaciones(d: DatosDegustaciones): string {
  const menuHtml = (m: MenuDegustacion) => `
    <div class="menu">
      <div class="menu-nombre">${m.menu}${m.es_adicional ? ' <span class="tag-extra">Extra</span>' : ''}</div>
      ${
        m.componentes.length === 0
          ? '<div class="comp vacio">Sin componentes definidos</div>'
          : agruparPorCategoria(m.componentes)
              .map(([cat, nombres]) => `<div class="comp"><span class="cat">${cat}:</span> ${nombres.join(', ')}</div>`)
              .join('')
      }
    </div>
  `;

  const cardHtml = (c: CardDegustacion) => `
    <div class="card">
      <h3>${c.cliente} — ${c.fechaEvento}</h3>
      <div class="sub">${c.tipoEvento ?? 'Evento'}</div>
      ${
        c.menus.length === 0
          ? '<div class="comp vacio">Sin menús seleccionados</div>'
          : `<div class="menus">${c.menus.map(menuHtml).join('')}</div>`
      }
    </div>
  `;

  const sesionHtml = (s: SesionDegustacion) => `
    <div class="sesion">
      <h2>${s.titulo}</h2>
      <div class="cards">${s.cards.map(cardHtml).join('')}</div>
    </div>
  `;

  return `
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  body { font-family: Arial, sans-serif; font-size: 11px; color: #222; margin: 0; padding: 25px; }
  .header { text-align: center; margin-bottom: 18px; }
  .header img { max-height: 60px; margin-bottom: 6px; }
  .header h1 { color: #093509; margin: 4px 0; font-size: 18px; }
  .header p { margin: 2px 0; color: #666; font-size: 11px; }
  .sesion { margin-bottom: 18px; }
  .sesion h2 { background: #093509; color: white; font-size: 12px; padding: 6px 10px; border-radius: 4px; margin: 0 0 8px; text-transform: capitalize; }
  .cards { display: grid; grid-template-columns: 1fr; gap: 10px; }
  .card { border: 1px solid #c2c8d0; border-radius: 8px; padding: 10px 12px; break-inside: avoid; page-break-inside: avoid; }
  .card h3 { margin: 0 0 2px; font-size: 12px; color: #093509; }
  .card .sub { color: #777; font-size: 9px; margin-bottom: 8px; }
  .menus { display: grid; grid-template-columns: repeat(2, 1fr); gap: 0 20px; }
  .menu { border-top: 1px dashed #d5d9de; padding: 6px 0 4px; }
  .menu-nombre { font-weight: bold; font-size: 11px; margin-bottom: 3px; }
  .comp { padding: 1px 0 1px 8px; font-size: 10px; }
  .comp .cat { color: #555; font-weight: bold; }
  .comp.vacio { color: #999; }
  .tag-extra { display: inline-block; padding: 1px 5px; border-radius: 4px; font-size: 8px; font-weight: bold; background: #fff3cd; color: #856404; }
  .footer { margin-top: 15px; font-size: 8px; color: #999; text-align: right; }
</style>
</head>
<body>
  <div class="header">
    <img src="${d.logoUrl}" alt="Logo" />
    <h1>Degustaciones — Detallado</h1>
    <p>${d.subtitulo}</p>
  </div>
  ${d.sesiones.length === 0 ? '<p>No hay degustaciones en este rango.</p>' : d.sesiones.map(sesionHtml).join('')}
  <div class="footer">
    <p>Generado el ${new Date().toLocaleDateString('es-GT')} — La Quebrada / GADZI</p>
  </div>
</body>
</html>
  `;
}