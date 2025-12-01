import { Routes } from '@angular/router';
import { PedidoListComponent } from './components/pedido-list/pedido-list';
import { PedidoFormComponent } from './components/pedido-form/pedido-form';

export const routes: Routes = [
  { path: '', component: PedidoListComponent }, // Rota padrão (Home)
  { path: 'novo', component: PedidoFormComponent } // Rota de criação
];
