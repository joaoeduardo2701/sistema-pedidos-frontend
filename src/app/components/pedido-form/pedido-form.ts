import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, FormArray, ReactiveFormsModule, Validators } from '@angular/forms';
import { PedidoService } from '../../services/pedido.service';
import { Router, RouterLink } from '@angular/router';

@Component({
  selector: 'app-pedido-form',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  templateUrl: './pedido-form.html'
})
export class PedidoFormComponent {
  form: FormGroup;

  constructor(
    private fb: FormBuilder,
    private service: PedidoService,
    private router: Router
  ) {
    this.form = this.fb.group({
      idMesa: [null, [Validators.required]],
      observacoes: [''],
      itens: this.fb.array([]) // Array dinâmico
    });

    // Adiciona um item inicial
    this.adicionarItem();
  }

  // Getter para facilitar o acesso no HTML
  get itensForm(): FormArray {
    return this.form.get('itens') as FormArray;
  }

  adicionarItem() {
    const itemGroup = this.fb.group({
      id_item: [null, Validators.required],
      quantidade: [1, [Validators.required, Validators.min(1)]],
      observacao: ['']
    });
    this.itensForm.push(itemGroup);
  }

  removerItem(index: number) {
    this.itensForm.removeAt(index);
  }

  salvar() {
    if (this.form.valid) {
      this.service.criarPedido(this.form.value).subscribe({
        next: () => {
          alert('Pedido criado com sucesso!');
          this.router.navigate(['/']); // Volta para a listagem
        },
        error: (err) => alert('Erro ao criar pedido. Verifique os IDs dos itens.')
      });
    }
  }
}
