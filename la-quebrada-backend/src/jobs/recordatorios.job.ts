import cron from 'node-cron';
import nodemailer from 'nodemailer';
import { pool } from '../db/pool.js';
import path from 'path';
import { fileURLToPath } from 'url';
import { armarHtmlRecordatorio } from '../templates/emails/recordatorio.templates.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.GMAIL_USER,
    pass: process.env.GMAIL_APP_PASSWORD,
  },
});

const ASUNTO_POR_TIPO: Record<string, string> = {
  checkpoint_50_proximo: 'Recordatorio: 50% de su evento se acerca la fecha límite',
  checkpoint_50_vencido: 'Su evento tiene un pago pendiente (50%)',
  checkpoint_100_proximo: 'Recordatorio: pago completo de su evento se acerca',
  checkpoint_100_vencido: 'Su evento tiene saldo pendiente urgente',
};

function armarMensaje(tipo: string, cliente: string, fecha: string, saldoPendiente: number): string {
  const fechaLegible = new Date(fecha).toLocaleDateString('es-GT', { day: 'numeric', month: 'long', year: 'numeric' });
  return `Hola ${cliente},\n\nLe escribimos de La Quebrada / GADZI respecto a su evento del ${fechaLegible}.\n\nSaldo pendiente actual: Q${saldoPendiente.toFixed(2)}.\n\nPor favor comuníquese con nosotros para coordinar el pago.\n\nGracias.`;
}

export async function ejecutarRecordatorios(): Promise<{ enviados: number }> {
  const result = await pool.query('SELECT * FROM fn_eventos_checkpoint_pendiente()');
  let enviados = 0;

  for (const fila of result.rows) {
    try {
      const saldoPendiente = Number(fila.total_a_pagar) - Number(fila.total_pagado);

      const html = armarHtmlRecordatorio({
        cliente: fila.cliente,
        fechaEvento: fila.fecha,
        saldoPendiente,
        totalAPagar: Number(fila.total_a_pagar),
        tipoRecordatorio: fila.tipo_recordatorio,
        eventoLocacion: 'La Quebrada',
      });

      await transporter.sendMail({
        from: `"La Quebrada / GADZI" <${process.env.GMAIL_USER}>`,
        to: fila.correo_cliente,
        subject: ASUNTO_POR_TIPO[fila.tipo_recordatorio] ?? 'Recordatorio de pago',
        html,
        attachments: [
            {
                filename: 'logo.png',
                path: path.join(__dirname, '..', '..', 'assets', 'logo-quebrada.png'),
                cid: 'logo-la-quebrada',
            },
            ],
        });

      await pool.query('CALL sp_registrar_recordatorio_enviado($1::integer, $2::integer, $3::varchar)', [
        fila.id_evento,
        fila.id_tipo_recordatorio,
        fila.correo_cliente,
      ]);

      enviados++;
    } catch (err) {
      console.error(`Error enviando recordatorio a evento ${fila.id_evento}:`, err);
    }
  }

  return { enviados };
}

export function iniciarJobRecordatorios(): void {
  // Corre todos los días a las 8:00 AM
  // Zona fija: en Railway el servidor corre en UTC (sin esto saldrían a las 2 AM de Guatemala)
  cron.schedule('0 8 * * *', () => {
    console.log('Ejecutando job de recordatorios...');
    ejecutarRecordatorios().then((r) => console.log(`Recordatorios enviados: ${r.enviados}`));
  }, { timezone: 'America/Guatemala' });
}