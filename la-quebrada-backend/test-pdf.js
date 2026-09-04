import puppeteer from 'puppeteer';
import fs from 'fs';

const browser = await puppeteer.launch();
const page = await browser.newPage();
await page.setContent('<h1>Funciona</h1><p>Si ves esto en el PDF, Puppeteer está instalado bien.</p>');
const pdf = await page.pdf({ format: 'A4' });
fs.writeFileSync('prueba.pdf', pdf);
await browser.close();
console.log('PDF generado: prueba.pdf');