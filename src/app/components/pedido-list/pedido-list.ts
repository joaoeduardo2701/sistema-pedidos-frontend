import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { PedidoService } from '../../services/pedido.service';
import { Pedido } from '../../models/pedido.models';
import { RouterLink } from '@angular/router';

@Component({
  selector: 'app-pedido-list',
  standalone: true,
  imports: [CommonModule, RouterLink], // Importe RouterLink para navegação
  templateUrl: './pedido-list.html',
  styleUrl: './pedido-list.css'
})
export class PedidoListComponent implements OnInit {
  pedidos: Pedido[] = [];

  // ⚠️ MAPA DE STATUS: Traduz o número do JSON para o texto e o slug (nome do Enum C#)
  statusMap: { [key: number]: { text: string, slug: string } } = {
    0: { text: 'Em Preparo', slug: 'EmPreparo' },
    1: { text: 'Aguardando Entrega', slug: 'AguardandoEntrega' },
    2: { text: 'Pronto', slug: 'Pronto' },
    3: { text: 'Entregue', slug: 'Entregue' },
    4: { text: 'Cancelado', slug: 'Cancelado' }
  };

  constructor(private service: PedidoService) {}

  ngOnInit(): void {
    this.carregarPedidos();
  }

  carregarPedidos() {
    this.service.listarPedidos().subscribe({
      next: (dados) => this.pedidos = dados,
      error: (e) => console.error('Erro ao carregar', e)
    });
 }

  /**
   * Retorna a string formatada para exibição na UI (Ex: 'Em Preparo')
   * @param statusNum O valor numérico do status vindo do backend (0, 1, 2...)
   */
  formatarStatus(statusNum: number): string {
    // Verifica se o statusNum é válido e existe no mapa, caso contrário, retorna desconhecido
    return this.statusMap[statusNum]?.text || 'Status Desconhecido';
  }

  /**
   * Retorna o nome do Enum C# sem espaço (slug) para uso nas comparações e envios.
   * @param statusNum O valor numérico do status vindo do backend (0, 1, 2...)
   */
  getStatusSlug(statusNum: number): string {
    return this.statusMap[statusNum]?.slug || '';
  }

  mudarStatus(pedido: Pedido, novoStatusSlug: string) {
    if(confirm(`Mudar status para ${novoStatusSlug}?`)) {
      this.service.atualizarStatus(pedido.idPedido, novoStatusSlug).subscribe(() => {
        this.carregarPedidos(); // Recarrega a lista
      });
    }
  }
 
  excluir(id: number) {
    if(confirm('Tem certeza que deseja excluir?')) {
      this.service.excluirPedido(id).subscribe(() => {
        this.carregarPedidos();
      });
    }
  }
}
