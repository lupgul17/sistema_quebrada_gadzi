interface DatosRecordatorio {
  cliente: string;
  fechaEvento: string;
  saldoPendiente: number;
  totalAPagar: number;
  tipoRecordatorio: string;
  eventoLocacion: string;
}

const TITULO_POR_TIPO: Record<string, string> = {
  checkpoint_50_proximo: 'Recordatorio de pago',
  checkpoint_50_vencido: 'Pago pendiente',
  checkpoint_100_proximo: 'Recordatorio de pago final',
  checkpoint_100_vencido: 'Saldo pendiente urgente',
};

const COLOR_POR_TIPO: Record<string, string> = {
  checkpoint_50_proximo: '#093509',
  checkpoint_50_vencido: '#856404',
  checkpoint_100_proximo: '#093509',
  checkpoint_100_vencido: '#721c24',
};

export function armarHtmlRecordatorio(d: DatosRecordatorio): string {
  const titulo = TITULO_POR_TIPO[d.tipoRecordatorio] ?? 'Recordatorio de pago';
  const color = COLOR_POR_TIPO[d.tipoRecordatorio] ?? '#093509';
  const fechaLegible = new Date(d.fechaEvento).toLocaleDateString('es-GT', { day: 'numeric', month: 'long', year: 'numeric' });

  return `
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"></head>
<body style="margin:0; padding:0; background:#f4f4f4; font-family:Arial, sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f4f4f4; padding:30px 0;">
    <tr>
      <td align="center">
        <table width="500" cellpadding="0" cellspacing="0" style="background:white; border-radius:8px; overflow:hidden;">
          <tr>
            <td style="background:white; padding:20px; text-align:center; border-bottom:3px solid ${color};">
                <img src="cid:logo-la-quebrada" alt="La Quebrada" style="max-height:100px; margin-bottom:8px;" />
                <p style="color:${color}; margin:4px 0 0; font-size:13px; font-weight:600;">${titulo}</p>
            </td>
            </tr>
          <tr>
            <td style="padding:25px;">
              <p style="font-size:14px; color:#222;">Hola <strong>${d.cliente}</strong>,</p>
              <p style="font-size:14px; color:#222; line-height:1.5;">
                Le escribimos respecto a su evento programado para el <strong>${fechaLegible}</strong>.
              </p>
              <table width="100%" cellpadding="10" style="background:#f8f9fa; border-radius:6px; margin:15px 0;">
                <tr>
                  <td style="font-size:13px; color:#666;">Total a pagar</td>
                  <td align="right" style="font-size:13px; color:#222;">Q${d.totalAPagar.toFixed(2)}</td>
                </tr>
                <tr>
                  <td style="font-size:14px; font-weight:bold; color:${color};">Saldo pendiente</td>
                  <td align="right" style="font-size:16px; font-weight:bold; color:${color};">Q${d.saldoPendiente.toFixed(2)}</td>
                </tr>
              </table>
              <p style="font-size:13px; color:#666; line-height:1.5;">
                Por favor comuníquese con nosotros para coordinar el pago y confirmar los detalles de su evento.
              </p>
            </td>
          </tr>
          <tr>
            <td style="background:#f4f4f4; padding:15px; text-align:center;">
              <p style="font-size:11px; color:#999; margin:0;">${d.eventoLocacion} — El escenario perfecto para su evento</p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
  `;
}