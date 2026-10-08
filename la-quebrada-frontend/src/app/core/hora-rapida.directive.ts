import { Directive, Input, OnDestroy, OnInit, inject } from '@angular/core';
import { Subscription } from 'rxjs';
import { DatePicker } from 'primeng/datepicker';

/** Minutos a los que se redondea la hora sugerida (y el paso de las flechas). */
const PASO_MINUTOS = 15;

/**
 * Para los p-datepicker de solo hora: los minutos avanzan de 15 en 15 y, si el campo está vacío
 * al abrirlo, se llena solo (así no hay que mover minuto por minuto ni dar clic en las flechas
 * para que tome el valor):
 *   - con [horaRapidaDesde] (la hora de inicio): esa hora + [horaRapidaDuracion] horas (4 por defecto)
 *   - sin ella: la hora actual redondeada
 * Uso: <p-datepicker [timeOnly]="true" horaRapida [horaRapidaDesde]="horaInicio" ... />
 */
@Directive({
  selector: 'p-datepicker[horaRapida]',
  standalone: true,
})
export class HoraRapida implements OnInit, OnDestroy {
  /** Hora de inicio, para sugerir la de fin. */
  @Input() horaRapidaDesde: Date | null | undefined = null;
  @Input() horaRapidaDuracion = 4;

  private readonly picker = inject(DatePicker);
  private sub?: Subscription;

  ngOnInit(): void {
    this.picker.stepMinute = PASO_MINUTOS;
    this.sub = this.picker.onShow.subscribe(() => {
      if (this.picker.value) return;
      const desde = this.horaRapidaDesde instanceof Date ? this.horaRapidaDesde : null;
      const sugerida = desde ? new Date(desde) : new Date();
      if (desde) sugerida.setHours(sugerida.getHours() + this.horaRapidaDuracion);
      const minutos = Math.round(sugerida.getMinutes() / PASO_MINUTOS) * PASO_MINUTOS;
      sugerida.setMinutes(minutos, 0, 0); // 60 pasa solo a la hora siguiente
      // La hora de fin no puede pasar de la medianoche (la base exige fin > inicio el mismo día)
      if (desde && sugerida.getDate() !== desde.getDate()) {
        sugerida.setTime(desde.getTime());
        sugerida.setHours(23, 45, 0, 0);
      }
      // writeValue pinta el campo; onModelChange avisa al formulario (ngModel o formControlName)
      this.picker.writeValue(sugerida);
      this.picker.onModelChange(sugerida);
    });
  }

  ngOnDestroy(): void {
    this.sub?.unsubscribe();
  }
}
