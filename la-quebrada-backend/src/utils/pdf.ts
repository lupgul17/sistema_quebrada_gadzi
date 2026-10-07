import puppeteer, { type Browser, type PDFOptions } from 'puppeteer';

/**
 * Un solo Chrome para todo el servidor: abrirlo es lo más lento de generar un PDF.
 * Si se cae o se cierra, se vuelve a abrir en el siguiente pedido.
 */
let navegador: Promise<Browser> | null = null;

function obtenerNavegador(): Promise<Browser> {
  if (!navegador) {
    navegador = puppeteer
      .launch({
        // Dentro de un contenedor Chrome no puede usar su sandbox ni un /dev/shm grande.
        // PUPPETEER_EXECUTABLE_PATH (si existe) apunta al Chromium del sistema; puppeteer lo lee solo.
        args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage'],
      })
      .then((browser) => {
        browser.on('disconnected', () => {
          navegador = null;
        });
        return browser;
      })
      .catch((err) => {
        navegador = null; // que el próximo intento vuelva a probar
        throw err;
      });
  }
  return navegador;
}

/** Convierte HTML en PDF. La pestaña se cierra siempre, aunque falle la generación. */
export async function htmlAPdf(html: string, opciones: PDFOptions): Promise<Buffer> {
  const browser = await obtenerNavegador();
  const page = await browser.newPage();
  try {
    await page.setContent(html, { waitUntil: 'domcontentloaded' });
    return Buffer.from(await page.pdf(opciones));
  } finally {
    await page.close().catch(() => undefined);
  }
}

/** Cierra Chrome al apagar el servidor. */
export async function cerrarNavegadorPdf(): Promise<void> {
  if (!navegador) return;
  const browser = await navegador.catch(() => null);
  navegador = null;
  await browser?.close().catch(() => undefined);
}
