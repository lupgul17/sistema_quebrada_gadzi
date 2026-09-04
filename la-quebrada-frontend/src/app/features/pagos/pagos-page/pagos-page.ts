import { Component } from '@angular/core';
import { Tabs, TabList, Tab, TabPanels, TabPanel } from 'primeng/tabs';
import { PagosPendientes } from '../pagos-pendientes/pagos-pendientes';
import { PagosVerificados } from '../pagos-verificados/pagos-verificados';

@Component({
  selector: 'app-pagos-page',
  standalone: true,
  imports: [Tabs, TabList, Tab, TabPanels, TabPanel, PagosPendientes, PagosVerificados],
  templateUrl: './pagos-page.html',
})
export class PagosPage {}