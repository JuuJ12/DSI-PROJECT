import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'rota.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final NutricionistaService _service = NutricionistaService();
  final TextEditingController _controller = TextEditingController();

  // CRUD Firestore
  Future<void> salvarMensagemFirestore(String texto, String role) async {
    await FirebaseFirestore.instance.collection('mensagens').add({
      'texto': texto,
      'role': role,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> editarMensagem(String id, String novoTexto) async {
    // Atualiza a mensagem do usuário
    await FirebaseFirestore.instance.collection('mensagens').doc(id).update({
      'texto': novoTexto,
    });
  }

  Future<void> editarUltimaMensagemEAtualizarResposta({
    required String userMsgId,
    required String novaMensagem,
    required String botMsgId,
  }) async {
    // Atualiza a mensagem do usuário
    await editarMensagem(userMsgId, novaMensagem);
    // Gera nova resposta do bot
    String novaResposta;
    try {
      novaResposta = await _service.enviarMensagem(novaMensagem);
    } catch (e) {
      novaResposta = 'Erro ao conectar com a API: $e';
    }
    // Atualiza a resposta do bot
    await FirebaseFirestore.instance
        .collection('mensagens')
        .doc(botMsgId)
        .update({'texto': novaResposta});
  }

  Future<void> apagarMensagem(String id) async {
    await FirebaseFirestore.instance.collection('mensagens').doc(id).delete();
  }

  Future<void> _talkToChatbot() async {
    final userMessage = _controller.text.trim();
    if (userMessage.isEmpty) return;

    // Salva mensagem do usuário
    await salvarMensagemFirestore(userMessage, 'user');
    _controller.clear();

    try {
      final botResponse = await _service.enviarMensagem(userMessage);
      // Salva resposta do bot
      await salvarMensagemFirestore(botResponse, 'bot');
    } catch (e) {
      await salvarMensagemFirestore('Erro ao conectar com a API: $e', 'bot');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chatbot Nutricionista')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('mensagens')
                    .orderBy('timestamp')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Erro ao carregar mensagens: \\n'
                        '${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  // Identifica a última mensagem do usuário
                  int lastUserMsgIndex = -1;
                  for (int i = docs.length - 1; i >= 0; i--) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    if (data['role'] == 'user') {
                      lastUserMsgIndex = i;
                      break;
                    }
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final isUser = data['role'] == 'user';
                      final isLastUserMsg = isUser && index == lastUserMsgIndex;

                      // Só permite editar/excluir a última mensagem do usuário
                      return Dismissible(
                        key: Key(doc.id),
                        background: isLastUserMsg && isUser
                            ? Container(color: Colors.red)
                            : Container(),
                        confirmDismiss: isLastUserMsg && isUser
                            ? (direction) async {
                                // Ao excluir, também exclui a resposta do bot seguinte (se houver)
                                // Busca a próxima mensagem do bot
                                String? botMsgId;
                                if (index + 1 < docs.length) {
                                  final nextData =
                                      docs[index + 1].data()
                                          as Map<String, dynamic>;
                                  if (nextData['role'] == 'bot') {
                                    botMsgId = docs[index + 1].id;
                                  }
                                }
                                await apagarMensagem(doc.id);
                                if (botMsgId != null) {
                                  await apagarMensagem(botMsgId);
                                }
                                return true;
                              }
                            : (direction) async => false,
                        child: ListTile(
                          title: Align(
                            alignment: isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? Colors.blue[100]
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(data['texto'] ?? ''),
                            ),
                          ),
                          trailing: isLastUserMsg && isUser
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () async {
                                        final controller =
                                            TextEditingController(
                                              text: data['texto'],
                                            );
                                        final result = await showDialog<String>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text(
                                              'Editar mensagem',
                                            ),
                                            content: TextField(
                                              controller: controller,
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('Cancelar'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  controller.text,
                                                ),
                                                child: const Text('Salvar'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (result != null &&
                                            result.trim().isNotEmpty) {
                                          // Ao editar, também atualiza a resposta do bot seguinte
                                          String? botMsgId;
                                          if (index + 1 < docs.length) {
                                            final nextData =
                                                docs[index + 1].data()
                                                    as Map<String, dynamic>;
                                            if (nextData['role'] == 'bot') {
                                              botMsgId = docs[index + 1].id;
                                            }
                                          }
                                          if (botMsgId != null) {
                                            await editarUltimaMensagemEAtualizarResposta(
                                              userMsgId: doc.id,
                                              novaMensagem: result.trim(),
                                              botMsgId: botMsgId,
                                            );
                                          } else {
                                            // Se não houver resposta do bot, só edita a mensagem
                                            await editarMensagem(
                                              doc.id,
                                              result.trim(),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text(
                                              'Excluir mensagem',
                                            ),
                                            content: const Text(
                                              'Tem certeza que deseja excluir esta mensagem e a resposta do agente?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                                child: const Text('Cancelar'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                                child: const Text('Excluir'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          // Exclui a mensagem do usuário e a resposta do bot seguinte (se houver)
                                          String? botMsgId;
                                          if (index + 1 < docs.length) {
                                            final nextData =
                                                docs[index + 1].data()
                                                    as Map<String, dynamic>;
                                            if (nextData['role'] == 'bot') {
                                              botMsgId = docs[index + 1].id;
                                            }
                                          }
                                          await apagarMensagem(doc.id);
                                          if (botMsgId != null) {
                                            await apagarMensagem(botMsgId);
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Digite sua mensagem',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _talkToChatbot,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
