import { Component, OnInit, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Button } from 'primeng/button';
import { AuthService } from '../../core/auth.service';
import { API_URL } from '../../core/api-config';

interface Salon {
  id_salon: number;
  nombre: string;
  capacidad: number;
  descripcion: string;
  locacion: string;
}

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [Button],
  templateUrl: './home.html',
  styleUrl: './home.scss',
})
export class Home implements OnInit {
  readonly salones = signal<Salon[]>([]);
  readonly usuario;

  constructor(
    private http: HttpClient,
    private authService: AuthService
  ) {
    this.usuario = this.authService.usuario;
  }

  ngOnInit(): void {
    this.http.get<Salon[]>(`${API_URL}/salones`).subscribe((data) => this.salones.set(data));
  }

  logout(): void {
    this.authService.logout();
  }
}