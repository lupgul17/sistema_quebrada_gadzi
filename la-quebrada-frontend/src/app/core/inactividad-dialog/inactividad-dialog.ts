import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Dialog } from 'primeng/dialog';
import { Button } from 'primeng/button';
import { InactividadService } from '../inactividad.service';

@Component({
  selector: 'app-inactividad-dialog',
  standalone: true,
  imports: [CommonModule, Dialog, Button],
  templateUrl: './inactividad-dialog.html',
  styleUrl: './inactividad-dialog.scss',
})
export class InactividadDialog {
  constructor(public inactividadService: InactividadService) {}

  seguirActivo(): void {
    this.inactividadService.seguirActivo();
  }
}