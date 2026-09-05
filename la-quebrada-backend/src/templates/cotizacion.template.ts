interface PagoResumen {
  fecha: string;
  concepto: string;
  monto: number;
}

interface DatosPlantilla {
  clienteNombre: string;
  clienteTelefono: string | null;
  fechaCotizacion: string;
  eventoTipo: string | null;
  eventoFecha: string;
  eventoSalones: string;
  eventoLocacion: string;
  eventoHorario: string;
  version: number;
  vigenciaDias: number;
  vendedor: string | null;
  menus: { nombre: string; precio: number; subtotal: number }[];
  servicios: { nombre: string; cantidad: number; precio: number; subtotal: number }[];
  subtotalMenus: number;
  subtotalServicios: number;
  depositoGarantia: number;
  totalDescuento: number;
  total: number;
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

export function armarHtmlCotizacion(d: DatosPlantilla): string {
  const filaMenu = (m: { nombre: string; precio: number; subtotal: number }) => `
    <tr><td>${m.nombre}</td><td class="num">Q${m.precio.toFixed(2)}</td><td class="num">Q${m.subtotal.toFixed(2)}</td></tr>
  `;
  const filaServicio = (s: { nombre: string; cantidad: number; precio: number; subtotal: number }) => `
    <tr><td>${s.nombre}</td><td class="num">${s.cantidad}</td><td class="num">Q${s.precio.toFixed(2)}</td><td class="num">Q${s.subtotal.toFixed(2)}</td></tr>
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
  .header { text-align: center; margin-bottom: 20px; }
  .header .etiqueta { font-size: 11px; letter-spacing: 1px; color: #666; text-transform: uppercase; }
  .header h1 { color: #093509; margin: 4px 0; font-size: 22px; }
  .header p { margin: 2px 0; color: #555; }
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
  .totales .total-final { font-weight: bold; font-size: 15px; border-top: 2px solid #093509; padding-top: 6px; margin-top: 6px; }
  .saldo-caja { background: #fff3cd; border: 1px solid #ffe08a; border-radius: 6px; padding: 10px; text-align: center; margin-top: 8px; }
  .saldo-caja .label { font-size: 11px; text-transform: uppercase; color: #856404; }
  .saldo-caja .monto { font-size: 20px; font-weight: bold; color: #856404; }
  .detalles { margin-top: 20px; border-top: 1px solid #ccc; padding-top: 10px; font-size: 11px; }
  .detalles-grid { display: flex; flex-wrap: wrap; gap: 15px; }
  .footer { margin-top: 25px; font-size: 9px; color: #777; border-top: 1px solid #eee; padding-top: 10px; }
  .footer p { margin: 2px 0; }
</style>
</head>
<body>
  <div class="header">
    <p class="etiqueta">Cotización de servicio</p>
    <h1>${d.eventoLocacion}</h1>
    <p>El escenario perfecto para su evento</p>
  </div>

  <div class="info-boxes">
    <div class="info-box">
      <h3>Cliente</h3>
      <p><strong>Nombre:</strong> ${d.clienteNombre}</p>
      <p><strong>Teléfono:</strong> ${d.clienteTelefono || '—'}</p>
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
      <thead><tr><th>Descripción</th><th>P/unitario</th><th>Total</th></tr></thead>
      <tbody>${d.menus.map(filaMenu).join('')}</tbody>
    </table>
  ` : ''}

  ${d.servicios.length > 0 ? `
    <div class="seccion-titulo">Descripción — Servicios</div>
    <table>
      <thead><tr><th>Descripción</th><th>Cant.</th><th>P/unitario</th><th>Total</th></tr></thead>
      <tbody>${d.servicios.map(filaServicio).join('')}</tbody>
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
        <div class="total-final"><span>Total</span><span>Q${d.total.toFixed(2)}</span></div>
      </div>
    </div>
    <div class="col-abonos">
      <div class="seccion-titulo">Abonos recibidos</div>
      ${d.pagos.length > 0 ? `
        <table>
          <thead><tr><th>Fecha</th><th>Concepto</th><th>Monto</th></tr></thead>
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