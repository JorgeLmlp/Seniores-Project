import 'package:flutter/material.dart';

import '../models/notificacao.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../widgets/custom_menu.dart';
import 'tela_consultas_exames.dart';
import 'tela_estoque.dart';
import 'tela_incidentes.dart';
import 'tela_medicamentos.dart';
import 'tela_seguranca.dart';

class Notificacoes extends StatefulWidget {
  const Notificacoes({super.key});

  @override
  State<Notificacoes> createState() => _NotificacoesState();
}

class _NotificacoesState extends State<Notificacoes> {
  List<Notificacao> _notificacoes = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final notificacoes = await ApiService().listarNotificacoes(
        SessionService.instance.pacienteId,
      );
      if (!mounted) return;
      setState(() {
        _notificacoes = notificacoes;
        _carregando = false;
      });
    } on ApiException catch (exception) {
      _mostrarErro(exception.message);
    } on StateError catch (exception) {
      _mostrarErro(exception.message);
    } catch (_) {
      _mostrarErro('Não foi possível carregar as notificações.');
    }
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    setState(() {
      _carregando = false;
      _erro = mensagem;
    });
  }

  Future<void> _alternar(Notificacao notificacao) async {
    try {
      final atualizada = notificacao.lida
          ? await ApiService().marcarNotificacaoNaoLida(notificacao.id)
          : await ApiService().marcarNotificacaoLida(notificacao.id);
      if (!mounted) return;
      setState(() {
        _notificacoes = _notificacoes
            .map((item) => item.id == atualizada.id ? atualizada : item)
            .toList();
      });
    } on ApiException catch (exception) {
      _mostrarMensagem(exception.message);
    } catch (_) {
      _mostrarMensagem('Não foi possível atualizar a notificação.');
    }
  }

  Future<void> _abrir(Notificacao notificacao) async {
    if (!notificacao.lida) await _alternar(notificacao);
    if (!mounted) return;
    final Widget? pagina = switch (notificacao.tipo) {
      'estoque' => Estoque(itemId: notificacao.referenciaId),
      'consulta' || 'exame' => const ConsultasExames(),
      'incidente' => const Incidentes(),
      'emergencia' => const Seguranca(),
      'medicamento' => Medicamentos(medicamentoId: notificacao.referenciaId),
      _ => null,
    };
    if (pagina != null) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => pagina));
    }
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    final naoLidas = _notificacoes.where((item) => !item.lida).length;
    return Scaffold(
      appBar: AppBar(
        title: Text('Notificações${naoLidas == 0 ? '' : ' ($naoLidas)'}'),
      ),
      body: RefreshIndicator(
        onRefresh: _carregar,
        child: _carregando
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 280),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _erro != null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  Text(_erro!, textAlign: TextAlign.center),
                  TextButton(
                    onPressed: _carregar,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              )
            : _notificacoes.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: const [
                  SizedBox(height: 220),
                  Center(child: Text('Nenhuma notificação disponível.')),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _notificacoes.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final notificacao = _notificacoes[index];
                  return Card(
                    color: notificacao.lida ? null : const Color(0xFFEAF1FF),
                    child: ListTile(
                      leading: Icon(
                        notificacao.lida
                            ? Icons.notifications_none
                            : Icons.notifications_active,
                      ),
                      title: Text(
                        notificacao.titulo,
                        style: TextStyle(
                          fontWeight: notificacao.lida
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(notificacao.mensagem),
                      onTap: () => _abrir(notificacao),
                      trailing: IconButton(
                        tooltip: notificacao.lida
                            ? 'Marcar como não lida'
                            : 'Marcar como lida',
                        icon: Icon(
                          notificacao.lida
                              ? Icons.markunread_outlined
                              : Icons.drafts_outlined,
                        ),
                        onPressed: () => _alternar(notificacao),
                      ),
                    ),
                  );
                },
              ),
      ),
      bottomNavigationBar: const Menu(paginaAtual: 4),
    );
  }
}
