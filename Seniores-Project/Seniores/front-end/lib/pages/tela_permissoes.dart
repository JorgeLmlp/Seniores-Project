import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PermissoesPaciente extends StatefulWidget {
  const PermissoesPaciente(
      {super.key,
      required this.pacienteId,
      required this.pacienteNome,
      this.cuidadorId});

  final int pacienteId;
  final String pacienteNome;
  final int? cuidadorId;

  @override
  State<PermissoesPaciente> createState() => _PermissoesPacienteState();
}

class _PermissoesPacienteState extends State<PermissoesPaciente> {
  final api = ApiService();
  Map<String, dynamic>? permissaoPaciente, permissaoCuidador;
  bool carregando = true, salvando = false;
  String? erro;

  bool get pacientePodeEscrever =>
      permissaoPaciente == null || permissaoPaciente!['nivel'] == 'escrita';
  bool get cuidadorPodeEscrever => permissaoCuidador?['nivel'] == 'escrita';

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> carregar() async {
    setState(() {
      carregando = true;
      erro = null;
    });
    try {
      final lista = await api.requisicao(
          'GET', '/pacientes/${widget.pacienteId}/permissoes') as List;
      Map<String, dynamic>? encontrar(String tipo, int? id) {
        if (id == null) return null;
        for (final item in lista.reversed) {
          final p = Map<String, dynamic>.from(item as Map);
          if (p['membro_tipo'] == tipo && p['membro_id'] == id) return p;
        }
        return null;
      }

      if (mounted) {
        setState(() {
          permissaoPaciente = encontrar('paciente', widget.pacienteId);
          permissaoCuidador = encontrar('cuidador', widget.cuidadorId);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => erro = e is ApiException
            ? e.message
            : 'Não foi possível carregar as permissões.');
      }
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  Future<void> alterar(String tipo, int membroId, bool permitir) async {
    setState(() => salvando = true);
    try {
      final atual = tipo == 'paciente' ? permissaoPaciente : permissaoCuidador;
      final novo = await api.requisicao(
        atual == null ? 'POST' : 'PATCH',
        atual == null
            ? '/pacientes/${widget.pacienteId}/permissoes'
            : '/permissoes/${atual['id']}',
        dados: atual == null
            ? {
                'membro_tipo': tipo,
                'membro_id': membroId,
                'nivel': permitir ? 'escrita' : 'leitura'
              }
            : {'nivel': permitir ? 'escrita' : 'leitura'},
      ) as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          if (tipo == 'paciente') {
            permissaoPaciente = novo;
          } else {
            permissaoCuidador = novo;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permissão atualizada.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e is ApiException
                ? e.message
                : 'Não foi possível alterar a permissão.')));
      }
    } finally {
      if (mounted) setState(() => salvando = false);
    }
  }

  Widget cartao(
      {required IconData icone,
      required String titulo,
      required String descricao,
      required bool valor,
      required ValueChanged<bool> alterarValor}) {
    final tema = Theme.of(context);
    return Card(
      elevation: 0,
      color: tema.colorScheme.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: tema.colorScheme.outlineVariant)),
      child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(children: [
            SwitchListTile(
              secondary: CircleAvatar(
                  backgroundColor: tema.colorScheme.primaryContainer,
                  child:
                      Icon(icone, color: tema.colorScheme.onPrimaryContainer)),
              title: Text(titulo,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle:
                  Text(valor ? 'Pode registrar e editar' : 'Somente leitura'),
              value: valor,
              onChanged: salvando ? null : alterarValor,
            ),
            Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(descricao,
                        style: TextStyle(
                            color: tema.colorScheme.onSurfaceVariant)))),
          ])),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Permissões de escrita')),
      body: RefreshIndicator(
          onRefresh: carregar,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                  child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                Color(0xFF245A9F),
                                Color(0xFF397BC8)
                              ]),
                              borderRadius: BorderRadius.circular(24)),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.admin_panel_settings_outlined,
                                    color: Colors.white, size: 38),
                                const SizedBox(height: 12),
                                Text(widget.pacienteNome,
                                    style: tema.textTheme.headlineSmall
                                        ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                const Text(
                                    'Defina quem pode adicionar ou alterar informações de cuidado.',
                                    style: TextStyle(
                                        color: Colors.white, height: 1.4)),
                              ])),
                      const SizedBox(height: 22),
                      if (carregando || salvando)
                        const LinearProgressIndicator(),
                      if (erro != null)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(erro!,
                                style:
                                    TextStyle(color: tema.colorScheme.error))),
                      if (!carregando && erro == null) ...[
                        cartao(
                          icone: Icons.person_outline,
                          titulo: 'Paciente',
                          descricao:
                              'Quando desativado, o paciente pode consultar os dados, mas não criar ou alterar registros.',
                          valor: pacientePodeEscrever,
                          alterarValor: (valor) =>
                              alterar('paciente', widget.pacienteId, valor),
                        ),
                        if (widget.cuidadorId != null)
                          cartao(
                            icone: Icons.volunteer_activism_outlined,
                            titulo: 'Cuidador vinculado',
                            descricao:
                                'A escrita do cuidador fica bloqueada até você autorizá-la.',
                            valor: cuidadorPodeEscrever,
                            alterarValor: (valor) =>
                                alterar('cuidador', widget.cuidadorId!, valor),
                          )
                        else
                          const Card(
                              child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text(
                                      'Quando um cuidador aceitar seu convite, a permissão dele aparecerá aqui.'))),
                      ],
                    ]),
              ))
            ],
          )),
    );
  }
}
