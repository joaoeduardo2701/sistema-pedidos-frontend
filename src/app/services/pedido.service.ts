import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { NovoPedidoDTO, Pedido } from '../models/pedido.models';

@Injectable({
  providedIn: 'root'
})
export class PedidoService {
  // ATENÇÃO: Verifique a porta da sua API C# (ex: 7001, 5000, 7213)
  private apiUrl = 'https://localhost:7213/api/Pedidos';

  constructor(private http: HttpClient) { }

  listarPedidos(): Observable<Pedido[]> {
    return this.http.get<Pedido[]>(this.apiUrl);
  }

  criarPedido(pedido: NovoPedidoDTO): Observable<any> {
    return this.http.post(this.apiUrl, pedido);
  }

  atualizarStatus(id: number, novoStatus: string): Observable<any> {
    return this.http.put(`${this.apiUrl}/${id}/status`, { status: novoStatus });
  }

  excluirPedido(id: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/${id}`);
  }
}
