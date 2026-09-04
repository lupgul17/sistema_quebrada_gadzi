import { Component } from '@angular/core';
import { Dialog } from 'primeng/dialog';
import { VisorArchivoService } from '../visor-archivo.service';

@Component({
  selector: 'app-visor-archivo-dialog',
  standalone: true,
  imports: [Dialog],
  templateUrl: './visor-archivo-dialog.html',
  styleUrl: './visor-archivo-dialog.scss',
})
export class VisorArchivoDialog {
  constructor(public visor: VisorArchivoService) {}
}