export interface PedidoItemDTO {
  id_item: number;
  quantidade: number;
  observacao?: string;
}

export interface NovoPedidoDTO {
  idMesa: number;
  observacoes?: string;
  itens: PedidoItemDTO[];
}

export interface Pedido {
  idPedido: number;
  dataHora: string;
  status: number; 
  valorTotal: number;
  observacoes?: string;
  idMesa: number;
}
