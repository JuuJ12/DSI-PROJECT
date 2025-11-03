import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'model/atividade_fisica.dart';
import 'ui_helpers.dart';
import 'create_edit_atividade_screen.dart';
import 'atividade_repository.dart';

class VisualizarAtividadeScreen extends StatelessWidget {
  final AtividadeFisica atividade;
  const VisualizarAtividadeScreen({super.key, required this.atividade});

  @override
  Widget build(BuildContext context) {
    final color = colorForIntensidade(atividade.intensidade);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(iconForTipo(atividade.tipo), size: 36, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              atividade.tipo,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${atividade.duracao} minutos',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(atividade.intensidade),
              backgroundColor: color.withOpacity(0.15),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Data'),
              subtitle: Text(
                DateFormat('dd/MM/yyyy').format(atividade.dataHora),
              ),
            ),
            ListTile(
              title: const Text('Hora'),
              subtitle: Text(DateFormat('HH:mm').format(atividade.dataHora)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text('Observações: ${atividade.observacoes ?? '-'}'),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    // navigate to edit screen
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            CreateEditAtividadeScreen(atividade: atividade),
                      ),
                    );
                    // after edit, pop this screen so list refreshes naturally
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Confirmar exclusão'),
                        content: const Text('Deseja remover esta atividade?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Excluir'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      final repo = AtividadeRepository();
                      if (atividade.id != null) {
                        await repo.delete(atividade.id!);
                      }
                      Navigator.pop(context); // close details
                    }
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text('Excluir'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
