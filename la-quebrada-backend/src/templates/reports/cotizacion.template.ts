import { ENCABEZADO_CSS, encabezadoHtml } from './encabezado.js';
interface PagoResumen {
  fecha: string;
  concepto: string;
  monto: number;
}

interface LineaExtra {
  nombre: string;
  etiqueta: string;
  cantidad: number;
  precio: number;
  subtotal: number;
}

interface DatosPlantilla {
  logoUrl: string;
  clienteNombre: string;
  clienteTelefono: string | null;
  fechaCotizacion: string;
  eventoTipo: string | null;
  eventoFecha: string;
  eventoSalones: string;
  eventoLocacion: string;
  /** Escribir la locación debajo del título (cuando el logo no es el de esa locación) */
  mostrarLocacion?: boolean;
  eventoHorario: string;
  version: number;
  vigenciaDias: number;
  vendedor: string | null;
  menus: { nombre: string; detalle?: string | null; cantidad: number; precio: number; subtotal: number; esExtraDegustacion: boolean }[];
  /** Paquetes aplicados: lo que incluyen (textos) y las horas de instalaciones */
  paquetes?: { nombre: string; incluye: string[]; horasIncluidas: number | null }[];
  servicios: { nombre: string; cantidad: number; precio: number; subtotal: number }[];
  extras: LineaExtra[];
  subtotalMenus: number;
  subtotalServicios: number;
  depositoGarantia: number;
  totalDescuento: number;
  total: number;
  totalExtras: number;
  brindis: boolean;
  cantidadMesaPrincipal: number | null;
  cantidadMesasReservadas: number | null;
  colorMantel: string | null;
  colorCubremanteles: string | null;
  boquitas: string | null;
  observaciones: string | null;
  pagos: PagoResumen[];
  saldoPendiente: number;
}

const NOMBRE_CONCEPTO: Record<string, string> = {
  reserva: 'Abono inicial (reserva)',
  abono: 'Abono adicional',
  saldo: 'Pago de saldo',
  recargo: 'Recargo',
};

/** Teléfono como 5502-4196 (igual que en el sistema); si no son 8 dígitos se deja tal cual. */
function mostrarTelefono(t: string | null): string | null {
  return t && /^\d{8}$/.test(t) ? `${t.slice(0, 4)}-${t.slice(4)}` : t;
}

export function armarHtmlCotizacion(d: DatosPlantilla): string {
  const hayExtras = d.extras.length > 0;
  const totalGeneral = d.total + d.totalExtras;

  const paquetes = (d.paquetes ?? []).filter((p) => p.incluye.length > 0);
  const filaMenu = (m: DatosPlantilla['menus'][number]) => `
    <tr>
      <td>${m.nombre}${m.esExtraDegustacion ? ' <span class="tag-degustacion">Degustación</span>' : ''}
        ${m.detalle ? `<div class="detalle-linea">${m.detalle}</div>` : ''}</td>
      <td class="num">${m.cantidad}</td>
      <td class="num">Q${m.precio.toFixed(2)}</td>
      <td class="num">Q${m.subtotal.toFixed(2)}</td>
    </tr>
  `;
  const filaServicio = (s: { nombre: string; cantidad: number; precio: number; subtotal: number }) => `
    <tr><td>${s.nombre}</td><td class="num">${s.cantidad}</td><td class="num">Q${s.precio.toFixed(2)}</td><td class="num">Q${s.subtotal.toFixed(2)}</td></tr>
  `;
  const filaExtra = (e: LineaExtra) => `
    <tr>
      <td>${e.nombre} <span class="tag-extra">${e.etiqueta}</span></td>
      <td class="num">${e.cantidad}</td>
      <td class="num">Q${e.precio.toFixed(2)}</td>
      <td class="num">Q${e.subtotal.toFixed(2)}</td>
    </tr>
  `;
  const filaPago = (p: PagoResumen) => `
    <tr><td>${new Date(p.fecha).toLocaleDateString('es-GT')}</td><td>${NOMBRE_CONCEPTO[p.concepto] ?? p.concepto}</td><td class="num">Q${p.monto.toFixed(2)}</td></tr>
  `;

  return `
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  body { font-family: Arial, sans-serif; font-size: 12px; color: #222; margin: 0; padding: 30px; }
  ${ENCABEZADO_CSS}
  .info-boxes { display: flex; gap: 20px; margin-bottom: 20px; }
  .info-box { flex: 1; border: 1px solid #ccc; border-radius: 6px; padding: 10px; }
  .info-box h3 { margin: 0 0 8px; font-size: 13px; color: #093509; text-transform: uppercase; }
  .info-box p { margin: 3px 0; }
  table { width: 100%; border-collapse: collapse; margin-bottom: 15px; }
  th { background: #093509; color: white; text-align: left; padding: 6px 8px; font-size: 11px; }
  td { padding: 6px 8px; border-bottom: 1px solid #eee; }
  .num { text-align: right; }
  .seccion-titulo { background: #f0f0f0; font-weight: bold; padding: 6px 8px; margin-top: 10px; text-transform: uppercase; font-size: 11px; }
  .resumen-financiero { display: flex; gap: 20px; align-items: flex-start; margin-top: 15px; }
  .col-totales, .col-abonos { flex: 1; }
  .totales div { display: flex; justify-content: space-between; padding: 3px 0; }
  .totales .linea-sub { font-weight: bold; border-top: 1px solid #ccc; margin-top: 4px; padding-top: 6px; }
  .totales .total-final { font-weight: bold; font-size: 15px; border-top: 2px solid #093509; padding-top: 6px; margin-top: 6px; }
  .saldo-caja { background: #fff3cd; border: 1px solid #ffe08a; border-radius: 6px; padding: 10px; text-align: center; margin-top: 8px; }
  .saldo-caja .label { font-size: 11px; text-transform: uppercase; color: #856404; }
  .saldo-caja .monto { font-size: 20px; font-weight: bold; color: #856404; }
  .detalles { margin-top: 20px; border-top: 1px solid #ccc; padding-top: 10px; font-size: 11px; }
  .detalles-grid { display: flex; flex-wrap: wrap; gap: 15px; }
  .tag-degustacion { display: inline-block; padding: 1px 5px; border-radius: 4px; font-size: 8px; font-weight: bold; background: #fff3cd; color: #856404; margin-left: 4px; }
  .tag-extra { display: inline-block; padding: 1px 5px; border-radius: 4px; font-size: 8px; font-weight: bold; background: #e9ecef; color: #495057; margin-left: 4px; }
  .detalle-linea { font-size: 10px; color: #666; margin-top: 2px; }
  .incluye { margin: 0 0 15px; padding: 6px 8px 6px 24px; }
  .incluye li { margin: 2px 0; }
  .footer { margin-top: 25px; font-size: 9px; color: #777; border-top: 1px solid #eee; padding-top: 10px; }
  .footer p { margin: 2px 0; }
</style>
</head>
<body>
  ${encabezadoHtml({
    logoUrl: d.logoUrl,
    etiqueta: 'Cotización de servicio',
    titulo: d.eventoTipo ? `${d.eventoTipo} · ${d.eventoFecha}` : d.eventoFecha,
    lineas: [
      // La locación solo se escribe si el logo no es el suyo (y nunca "La Quebrada": ya lo dice el logo)
      d.mostrarLocacion && !/la quebrada/i.test(d.eventoLocacion) ? d.eventoLocacion : null,
      `Versión ${d.version}`,
    ],
  })}

  <div class="info-boxes">
    <div class="info-box">
      <h3>Cliente</h3>
      <p><strong>Nombre:</strong> ${d.clienteNombre}</p>
      <p><strong>Teléfono:</strong> ${mostrarTelefono(d.clienteTelefono) || '—'}</p>
      <p><strong>Fecha de cotización:</strong> ${d.fechaCotizacion}</p>
    </div>
    <div class="info-box">
      <h3>Evento</h3>
      <p><strong>Evento:</strong> ${d.eventoTipo || '—'}</p>
      <p><strong>Lugar:</strong> ${d.eventoSalones}</p>
      <p><strong>Fecha:</strong> ${d.eventoFecha}</p>
      <p><strong>Horario:</strong> ${d.eventoHorario}</p>
    </div>
    <div class="info-box">
      <h3>Vigencia</h3>
      <p>Versión ${d.version}</p>
      <p>${d.vigenciaDias} días desde la emisión</p>
      ${d.vendedor ? `<p>Vendedor: ${d.vendedor}</p>` : ''}
    </div>
  </div>

  ${d.menus.length > 0 ? `
    <div class="seccion-titulo">Descripción — Menú</div>
    <table>
      <thead><tr><th>Descripción</th><th class="num">Cant.</th><th class="num">P/unitario</th><th class="num">Total</th></tr></thead>
      <tbody>${d.menus.map(filaMenu).join('')}</tbody>
    </table>
  ` : ''}

  ${paquetes.map((p) => `
    <div class="seccion-titulo">Incluye — ${p.nombre}</div>
    <ul class="incluye">${p.incluye.map((t) => `<li>${t}</li>`).join('')}</ul>
  `).join('')}

  ${d.servicios.length > 0 ? `
    <div class="seccion-titulo">Descripción — Servicios</div>
    <table>
      <thead><tr><th>Descripción</th><th class="num">Cant.</th><th class="num">P/unitario</th><th class="num">Total</th></tr></thead>
      <tbody>${d.servicios.map(filaServicio).join('')}</tbody>
    </table>
  ` : ''}

  ${hayExtras ? `
    <div class="seccion-titulo">Descripción — Extras</div>
    <table>
      <thead><tr><th>Descripción</th><th class="num">Cant.</th><th class="num">P/unitario</th><th class="num">Total</th></tr></thead>
      <tbody>${d.extras.map(filaExtra).join('')}</tbody>
    </table>
  ` : ''}

  <div class="resumen-financiero">
    <div class="col-totales">
      <div class="seccion-titulo">Resumen</div>
      <div class="totales">
        <div><span>Subtotal menú</span><span>Q${d.subtotalMenus.toFixed(2)}</span></div>
        <div><span>Subtotal servicios</span><span>Q${d.subtotalServicios.toFixed(2)}</span></div>
        <div><span>Depósito de garantía</span><span>Q${d.depositoGarantia.toFixed(2)}</span></div>
        ${d.totalDescuento > 0 ? `<div><span>Descuento</span><span>-Q${d.totalDescuento.toFixed(2)}</span></div>` : ''}
        ${
          hayExtras
            ? `
          <div class="linea-sub"><span>Total cotización</span><span>Q${d.total.toFixed(2)}</span></div>
          <div><span>Extras</span><span>+Q${d.totalExtras.toFixed(2)}</span></div>
          <div class="total-final"><span>Total general</span><span>Q${totalGeneral.toFixed(2)}</span></div>
        `
            : `<div class="total-final"><span>Total</span><span>Q${d.total.toFixed(2)}</span></div>`
        }
      </div>
    </div>
    <div class="col-abonos">
      <div class="seccion-titulo">Abonos recibidos</div>
      ${d.pagos.length > 0 ? `
        <table>
          <thead><tr><th>Fecha</th><th>Concepto</th><th class="num">Monto</th></tr></thead>
          <tbody>${d.pagos.map(filaPago).join('')}</tbody>
        </table>
      ` : '<p style="font-size:10px;color:#777;">Sin abonos registrados todavía.</p>'}
      <div class="saldo-caja">
        <div class="label">Saldo actual</div>
        <div class="monto">Q${d.saldoPendiente.toFixed(2)}</div>
      </div>
    </div>
  </div>

  <div class="detalles">
    <div class="seccion-titulo">Detalles del evento</div>
    <div class="detalles-grid">
      ${d.cantidadMesaPrincipal ? `<span>Mesa principal: ${d.cantidadMesaPrincipal} personas</span>` : ''}
      ${d.cantidadMesasReservadas ? `<span>Mesas reservadas: ${d.cantidadMesasReservadas}</span>` : ''}
      <span>Brindis: ${d.brindis ? 'Sí' : 'No'}</span>
      ${d.colorMantel ? `<span>Mantel: ${d.colorMantel}</span>` : ''}
      ${d.colorCubremanteles ? `<span>Cubremanteles: ${d.colorCubremanteles}</span>` : ''}
    </div>
    ${d.boquitas ? `<p><strong>Boquitas:</strong> ${d.boquitas}</p>` : ''}
    ${d.observaciones ? `<p><strong>Observaciones:</strong> ${d.observaciones}</p>` : ''}
  </div>

  <div class="footer">
    <p><strong>Para confirmar el evento se requiere un abono no reembolsable.</strong> El evento debe estar cancelado a más tardar diez días antes en caso contrario no se llevará a cabo.</p>
    <p>Todo servicio adicional tendrá un costo aparte. Vigencia de esta cotización: ${d.vigenciaDias} días desde la fecha de emisión.</p>
  </div>
</body>
</html>
  `;
}