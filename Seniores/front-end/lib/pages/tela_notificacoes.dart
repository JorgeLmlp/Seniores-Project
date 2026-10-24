import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/session_service.dart';
import '../services/local_store.dart';
import 'cuidados/tela_consultas.dart';
import 'cuidados/tela_exames.dart';
import 'medicamentos/tela_medicamentos.dart';
import 'modulos_clinicos.dart';
import '../widgets/custom_menu.dart';
import 'tela_vinculos.dart';

class Notificacoes extends StatefulWidget {
  const Notificacoes({super.key});

  @override
  State<Notificacoes> createState() => _NotificacoesState();
}

class _NotificacoesState extends State<Notificacoes> {
  late Future<List<Map<String, dynamic>>> carregamento;
  Set<String> _lidos = {};

  String get _chaveDoPaciente => 'avisos_lidos:${SessionService.instance.pacienteId}';

  String _idAviso(Map<String, dynamic> aviso) =>
      '${aviso['tipo']}:${aviso['medicamento_id'] ?? aviso['estoque_id'] ?? aviso['registro_id'] ?? aviso['id'] ?? ''}:${aviso['data'] ?? aviso['horario'] ?? ''}';

  Future<void> _restaurarLidos() async {
    try {
      final dados = await LocalStore.instance.get(
          SessionService.instance.escopo, _chaveDoPaciente);
      if (!mounted) return;
      final ids = dados is Map ? dados['ids'] : null;
      if (ids is List) setState(() => _lidos = ids.map((e) => '$e').toSet());
    } catch (_) {
      // Estado local opcional; avisos continuam acessiveis sem cache.
    }
  }

  Future<void> _marcarLido(Map<String, dynamic> aviso) async {
    setState(() {
      final chave = _idAviso(aviso);
      if (!_lidos.add(chave)) _lidos.remove(chave);
    });
    try {
      await LocalStore.instance.put(SessionService.instance.escopo,
          _chaveDoPaciente, {'ids': _lidos.toList()});
    } catch (_) {
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Não foi possível salvar a leitura neste aparelho.')));
      }
    }
  }

  Future<void> _abrirRelacionado(Map<String, dynamic> aviso) async {
    final tipo = '${aviso['tipo'] ?? ''}';
    Widget? pagina;
    if (tipo.startsWith('medicamento')) {
      pagina = Medicamentos(registroDestaque: (aviso['medicamento_id'] as num?)?.toInt());
    } else if (tipo == 'estoque_baixo') {
      pagina = ModuloClinico(config: ModulosSeniores.estoque,
        registroDestaque: (aviso['estoque_id'] as num?)?.toInt());
    } else if (tipo == 'consulta_proxima') {
      pagina = Consultas(registroDestaque: aviso['registro_id'].toString());
    } else if (tipo == 'exame_proximo') {
      pagina = Exames(registroDestaque: aviso['registro_id'].toString());
    } else if (tipo == 'incidente_recente') {
      pagina = ModuloClinico(config: ModulosSeniores.incidentes,
        registroDestaque: (aviso['registro_id'] as num?)?.toInt());
    }
    await _marcarLido(aviso);
    if (!mounted || pagina == null) return;
    await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => pagina!));
  }

  @override
  void initState() {
    super.initState();
    final session = SessionService.instance;
    if (session.tipoUsuario == 'paciente' || session.pacienteSelecionado != null) {
      _restaurarLidos();
    }
    carregamento =
        session.tipoUsuario != 'paciente' && session.pacienteSelecionado == null
            ? Future.value([])
            : _carregar();
  }

  Future<List<Map<String, dynamic>>> _carregar() async {
    final pacienteId = SessionService.instance.pacienteId;
    final respostas = await Future.wait([
      ApiService().requisicao('GET', '/pacientes/$pacienteId/alertas-medicamentos'),
      ApiService().requisicao('GET', '/pacientes/$pacienteId/alertas-estoque'),
      ApiService().listarRegistros('consultas'),
      ApiService().listarRegistros('exames'),
      ApiService().listarRegistros('incidentes'),
    ]);
    final alertas = <Map<String, dynamic>>[
      ...(respostas[0] as List).map((item) => Map<String, dynamic>.from(item as Map)),
      ...(respostas[1] as List).map((item) => Map<String, dynamic>.from(item as Map)),
    ];
    final agora = DateTime.now();
    final limite = agora.add(const Duration(days: 7));
    for (final (indice, tipo, titulo) in [
      (2, 'consulta_proxima', 'Consulta próxima'),
      (3, 'exame_proximo', 'Exame próximo'),
    ]) {
      for (final registro in respostas[indice] as List) {
        final r = Map<String, dynamic>.from(registro as Map);
        final dados = r['dados'] is Map ? r['dados'] as Map : r;
        final data = DateTime.tryParse('${dados['dataHora'] ?? dados['data_hora'] ?? ''}');
        if (data == null || data.isBefore(agora) || data.isAfter(limite)) continue;
        alertas.add({
          'tipo': tipo, 'titulo': titulo,
          'mensagem': '${dados['nomeDoutor'] ?? dados['nome'] ?? 'Agendamento'} • ${data.day}/${data.month} às ${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}',
          'registro_id': r['id'], 'data': data.toIso8601String(),
        });
      }
    }
    for (final registro in respostas[4] as List) {
      final r = Map<String, dynamic>.from(registro as Map);
      final data = DateTime.tryParse('${r['data_hora'] ?? ''}');
      if (data != null && data.isAfter(agora.subtract(const Duration(days: 7)))) {
        alertas.add({
          'tipo': 'incidente_recente', 'titulo': 'Incidente registrado',
          'mensagem': '${r['tipo'] ?? 'Ocorrência'}: ${r['descricao'] ?? ''}',
          'registro_id': r['id'], 'data': data.toIso8601String(),
        });
      }
    }
    return alertas;
  }

  void _atualizar() {
    setState(() => carregamento = _carregar());
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionService.instance;
    if (session.tipoUsuario != 'paciente' &&
        session.pacienteSelecionado == null) {
      return const Vinculos();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avisos'),
        actions: [
          IconButton(
            tooltip: 'Atualizar avisos',
            onPressed: _atualizar,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: carregamento,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _EstadoAvisos(
              icone: Icons.cloud_off_rounded,
              titulo: 'Não foi possível carregar os avisos',
              descricao: 'Verifique sua conexão e tente novamente.',
              acao: _atualizar,
            );
          }
          final itens = snapshot.data ?? [];
          if (itens.isEmpty) {
            return const _EstadoAvisos(
              icone: Icons.notifications_none_rounded,
              titulo: 'Tudo em ordem',
              descricao: 'Nenhum aviso precisa da sua atenção no momento.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              _atualizar();
              await carregamento;
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              itemCount: itens.length + 1,
              separatorBuilder: (_, index) => index == 0
                  ? const SizedBox(height: 18)
                  : const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _ResumoAvisos(quantidade: itens.length);
                }
                final aviso = itens[index - 1];
                return _CartaoAviso(aviso: aviso,
                  lida: _lidos.contains(_idAviso(aviso)),
                  abrir: () => _abrirRelacionado(aviso),
                  marcarLida: () => _marcarLido(aviso),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: const Menu(paginaAtual: 4),
    );
  }
}

class _ResumoAvisos extends StatelessWidget {
  const _ResumoAvisos({required this.quantidade});

  final int quantidade;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_active_rounded,
              color: scheme.onErrorContainer, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$quantidade ${quantidade == 1 ? 'aviso requer' : 'avisos requerem'} atenção',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scheme.onErrorContainer,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Revise os itens abaixo para manter o cuidado em dia.',
                  style: TextStyle(color: scheme.onErrorContainer),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartaoAviso extends StatelessWidget {
  const _CartaoAviso({required this.aviso, required this.lida,
      required this.abrir, required this.marcarLida});

  final Map<String, dynamic> aviso;
  final bool lida;
  final VoidCallback abrir;
  final VoidCallback marcarLida;

  @override
  Widget build(BuildContext context) {
    final atraso = aviso['tipo'] == 'medicamento_atrasado';
    final scheme = Theme.of(context).colorScheme;
    final cor = atraso ? scheme.error : const Color(0xFFB7791F);
    final responsavel = SessionService.instance.tipoUsuario == 'responsavel';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                atraso
                    ? Icons.medication_liquid_rounded
                    : Icons.inventory_2_outlined,
                color: cor,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    aviso['titulo']?.toString() ?? 'Aviso',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: cor,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    aviso['mensagem']?.toString() ?? '',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(lida ? 'Lido neste aparelho' : 'Não lido',
                      style: Theme.of(context).textTheme.labelSmall),
                  Wrap(spacing: 6, children: [
                    TextButton(onPressed: abrir, child: const Text('Abrir')), 
                    TextButton(onPressed: marcarLida,
                        child: Text(lida ? 'Marcar como não lido' : 'Marcar como lido')),
                  ]),
                  if (atraso && aviso['responsavel_notificado'] == true) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.family_restroom_rounded,
                            size: 17, color: scheme.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            responsavel
                                ? 'Aviso direcionado a você como responsável.'
                                : 'Este aviso também está disponível para o responsável.',
                            style: TextStyle(
                              color: scheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EstadoAvisos extends StatelessWidget {
  const _EstadoAvisos({
    required this.icone,
    required this.titulo,
    required this.descricao,
    this.acao,
  });

  final IconData icone;
  final String titulo;
  final String descricao;
  final VoidCallback? acao;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icone,
                  size: 54, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                descricao,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (acao != null) ...[
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: acao,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tentar novamente'),
                ),
              ],
            ],
          ),
        ),
      );
}
