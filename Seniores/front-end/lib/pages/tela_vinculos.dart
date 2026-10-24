import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/session_service.dart';
import '../widgets/app_feedback.dart';
import '../widgets/custom_menu_sanduiche.dart';
import 'tela_inicio.dart';

class Vinculos extends StatefulWidget {
  const Vinculos({super.key});

  @override
  State<Vinculos> createState() => _VinculosState();
}

class _VinculosState extends State<Vinculos> {
  final api = ApiService();
  List<dynamic> pacientes = [];
  List<dynamic> solicitacoes = [];
  bool ocupado = false;
  String? erro;

  bool get responsavel => SessionService.instance.tipoUsuario == 'responsavel';

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> carregar() async {
    setState(() {
      ocupado = true;
      erro = null;
    });
    try {
      final p = await api.requisicao('GET', '/minha-conta/pacientes') as List;
      final s =
          await api.requisicao('GET', '/minha-conta/solicitacoes') as List;
      if (!mounted) return;
      setState(() {
        pacientes = p;
        solicitacoes = s;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => erro =
          e is ApiException ? e.message : 'Falha ao carregar os vínculos.');
    } finally {
      if (mounted) setState(() => ocupado = false);
    }
  }

  Future<bool> enviar(
    String rota,
    Map<String, dynamic> dados, {
    String metodo = 'POST',
    String? mensagem,
  }) async {
    setState(() => ocupado = true);
    try {
      await api.requisicao(metodo, rota, dados: dados);
      await carregar();
      if (mounted && mensagem != null) {
        mostrarFeedback(
          context,
          mensagem: mensagem,
          tipo: TipoFeedback.sucesso,
          titulo: 'Solicitação concluída',
        );
      }
      return true;
    } catch (e) {
      if (mounted) {
        mostrarFeedback(
          context,
          mensagem: e is ApiException ? e.message : 'Não foi possível salvar.',
          tipo: TipoFeedback.erro,
          titulo: 'Não foi possível concluir',
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => ocupado = false);
    }
  }

  Future<String?> _pedirDado({
    required String titulo,
    required String descricao,
    required String rotulo,
    required TextInputType teclado,
    required String? Function(String?) validar,
    int? maxLength,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => _DialogoDado(
        titulo: titulo,
        descricao: descricao,
        rotulo: rotulo,
        teclado: teclado,
        validar: validar,
        maxLength: maxLength,
      ),
    );
  }

  Future<void> _vincularPaciente() async {
    final cpf = await _pedirDado(
      titulo: 'Vincular paciente',
      descricao:
          'Informe o CPF usado pelo paciente no cadastro. O vínculo será criado nesta conta.',
      rotulo: 'CPF do paciente',
      teclado: TextInputType.number,
      maxLength: 14,
      validar: (valor) =>
          (valor ?? '').replaceAll(RegExp(r'\D'), '').length == 11
              ? null
              : 'Informe os 11 dígitos do CPF.',
    );
    if (cpf == null || !mounted) return;
    await enviar('/minha-conta/pacientes', {'cpf': cpf},
        mensagem: 'Paciente vinculado com sucesso.');
  }

  Future<void> _convidarCuidador(int pacienteId, String pacienteNome) async {
    final email = await _pedirDado(
      titulo: 'Convidar cuidador',
      descricao:
          'Envie o convite para o e-mail cadastrado pelo cuidador. O acesso só será liberado depois que ele aceitar.',
      rotulo: 'E-mail do cuidador',
      teclado: TextInputType.emailAddress,
      validar: (valor) {
        final email = (valor ?? '').trim();
        return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)
            ? null
            : 'Informe um e-mail válido.';
      },
    );
    if (email == null || !mounted) return;
    await enviar(
      '/minha-conta/solicitacoes',
      {'email': email.toLowerCase(), 'paciente_id': pacienteId},
      mensagem: 'Convite enviado para cuidar de $pacienteNome.',
    );
  }

  Future<void> _abrirPaciente(Map<String, dynamic> paciente) async {
    await SessionService.instance.selecionarPaciente(
      paciente['id'] as int,
      paciente['name'] as String,
    );
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Home()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final carregamentoInicial =
        ocupado && pacientes.isEmpty && solicitacoes.isEmpty && erro == null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuidado compartilhado'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: ocupado ? null : carregar,
            icon: const Icon(Icons.refresh_rounded),
          ),
          Builder(
            builder: (context) => IconButton.filledTonal(
              tooltip: 'Abrir menu',
              onPressed: () => Scaffold.of(context).openEndDrawer(),
              icon: const Icon(Icons.menu_rounded),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      endDrawer: const MenuSanduiche(paginaAtual: 'vinculos'),
      body: carregamentoInicial
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: carregar,
              child: LayoutBuilder(
                builder: (context, constraints) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    constraints.maxWidth < 600 ? 20 : 32,
                    12,
                    constraints.maxWidth < 600 ? 20 : 32,
                    40,
                  ),
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _CabecalhoPerfil(responsavel: responsavel),
                            if (erro != null) ...[
                              const SizedBox(height: 16),
                              _ErroCarregamento(
                                mensagem: erro!,
                                tentarNovamente: carregar,
                              ),
                            ],
                            const SizedBox(height: 28),
                            _TituloSecao(
                              titulo: responsavel
                                  ? 'Pacientes vinculados'
                                  : 'Pacientes sob seus cuidados',
                              quantidade: pacientes.length,
                            ),
                            const SizedBox(height: 12),
                            if (pacientes.isEmpty)
                              _EstadoVazio(
                                icone: Icons.people_outline_rounded,
                                titulo: responsavel
                                    ? 'Nenhum paciente vinculado'
                                    : 'Você ainda não cuida de um paciente',
                                descricao: responsavel
                                    ? 'Use o CPF do paciente para iniciar a rede de cuidado.'
                                    : 'Quando você aceitar um convite, o paciente aparecerá aqui.',
                                acao: responsavel ? _vincularPaciente : null,
                                textoAcao: 'Vincular paciente',
                              )
                            else
                              ...pacientes.map((item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _CartaoPaciente(
                                      paciente: Map<String, dynamic>.from(
                                          item as Map),
                                      responsavel: responsavel,
                                      selecionado: SessionService
                                              .instance.pacienteSelecionado ==
                                          item['id'],
                                      abrir: () => _abrirPaciente(
                                        Map<String, dynamic>.from(item),
                                      ),
                                      convidar: responsavel
                                          ? () => _convidarCuidador(
                                                item['id'] as int,
                                                item['name'] as String,
                                              )
                                          : null,
                                    ),
                                  )),
                            if (responsavel && pacientes.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              OutlinedButton.icon(
                                onPressed: ocupado ? null : _vincularPaciente,
                                icon:
                                    const Icon(Icons.person_add_alt_1_rounded),
                                label: const Text('Vincular outro paciente'),
                              ),
                            ],
                            const SizedBox(height: 32),
                            _TituloSecao(
                              titulo: 'Convites de cuidado',
                              quantidade: solicitacoes.length,
                            ),
                            const SizedBox(height: 12),
                            if (solicitacoes.isEmpty)
                              _EstadoVazio(
                                icone: Icons.mark_email_unread_outlined,
                                titulo: 'Nenhum convite por aqui',
                                descricao: responsavel
                                    ? 'Os convites enviados aos cuidadores aparecerão nesta área.'
                                    : 'Os convites enviados por responsáveis aparecerão nesta área.',
                              )
                            else
                              ...solicitacoes.map((item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _CartaoSolicitacao(
                                      solicitacao: Map<String, dynamic>.from(
                                          item as Map),
                                      responsavel: responsavel,
                                      ocupado: ocupado,
                                      responder: (status) => enviar(
                                        '/minha-conta/solicitacoes/${item['id']}',
                                        {'status': status},
                                        metodo: 'PATCH',
                                        mensagem: status == 'aceita'
                                            ? 'Convite aceito. O paciente já está disponível.'
                                            : 'Convite recusado.',
                                      ),
                                    ),
                                  )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _DialogoDado extends StatefulWidget {
  const _DialogoDado({
    required this.titulo,
    required this.descricao,
    required this.rotulo,
    required this.teclado,
    required this.validar,
    this.maxLength,
  });

  final String titulo;
  final String descricao;
  final String rotulo;
  final TextInputType teclado;
  final String? Function(String?) validar;
  final int? maxLength;

  @override
  State<_DialogoDado> createState() => _DialogoDadoState();
}

class _DialogoDadoState extends State<_DialogoDado> {
  final controller = TextEditingController();
  final chave = GlobalKey<FormState>();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void continuar() {
    if (chave.currentState?.validate() ?? false) {
      Navigator.pop(context, controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        icon: Icon(
          widget.teclado == TextInputType.emailAddress
              ? Icons.alternate_email_rounded
              : Icons.badge_outlined,
        ),
        title: Text(widget.titulo),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 420,
            child: Form(
              key: chave,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.descricao,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: widget.teclado,
                    maxLength: widget.maxLength,
                    autocorrect: false,
                    textCapitalization: TextCapitalization.none,
                    decoration: InputDecoration(labelText: widget.rotulo),
                    validator: widget.validar,
                    onFieldSubmitted: (_) => continuar(),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: continuar,
            child: const Text('Continuar'),
          ),
        ],
      );
}

class _CabecalhoPerfil extends StatelessWidget {
  const _CabecalhoPerfil({required this.responsavel});

  final bool responsavel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: scheme.onPrimary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              responsavel
                  ? Icons.family_restroom_rounded
                  : Icons.health_and_safety_outlined,
              color: scheme.onPrimary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  responsavel
                      ? 'Organize a rede de cuidado'
                      : 'Acompanhe quem precisa de você',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  responsavel
                      ? 'Vincule pacientes por CPF e convide cuidadores pelo e-mail cadastrado.'
                      : 'Aceite convites e escolha o paciente que deseja acompanhar agora.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onPrimary.withValues(alpha: 0.88),
                        height: 1.45,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TituloSecao extends StatelessWidget {
  const _TituloSecao({required this.titulo, required this.quantidade});

  final String titulo;
  final int quantidade;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '$quantidade',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      );
}

class _CartaoPaciente extends StatelessWidget {
  const _CartaoPaciente({
    required this.paciente,
    required this.responsavel,
    required this.selecionado,
    required this.abrir,
    this.convidar,
  });

  final Map<String, dynamic> paciente;
  final bool responsavel;
  final bool selecionado;
  final VoidCallback abrir;
  final VoidCallback? convidar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final nome = paciente['name']?.toString() ?? 'Paciente';
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: abrir,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: scheme.primaryContainer,
                    foregroundColor: scheme.onPrimaryContainer,
                    child: Text(
                      nome.isEmpty ? '?' : nome[0].toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          selecionado
                              ? 'Paciente selecionado'
                              : 'Toque para acessar os cuidados',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    selecionado
                        ? Icons.check_circle_rounded
                        : Icons.chevron_right_rounded,
                    color:
                        selecionado ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                ],
              ),
              if (responsavel) ...[
                const SizedBox(height: 14),
                Divider(height: 1, color: scheme.outlineVariant),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: convidar,
                    icon: const Icon(Icons.outgoing_mail),
                    label: const Text('Convidar cuidador por e-mail'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CartaoSolicitacao extends StatelessWidget {
  const _CartaoSolicitacao({
    required this.solicitacao,
    required this.responsavel,
    required this.ocupado,
    required this.responder,
  });

  final Map<String, dynamic> solicitacao;
  final bool responsavel;
  final bool ocupado;
  final ValueChanged<String> responder;

  @override
  Widget build(BuildContext context) {
    final paciente = solicitacao['paciente'] as Map?;
    final pessoa =
        solicitacao[responsavel ? 'cuidador' : 'responsavel'] as Map?;
    final status = solicitacao['status']?.toString() ?? 'pendente';
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.mark_email_unread_outlined,
                      color: scheme.onSecondaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        paciente?['nome']?.toString() ??
                            'Paciente indisponível',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        responsavel
                            ? 'Convite para ${pessoa?['nome'] ?? 'cuidador'}'
                            : 'Enviado por ${pessoa?['nome'] ?? 'responsável'}',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusConvite(status: status),
              ],
            ),
            if (!responsavel && status == 'pendente') ...[
              const SizedBox(height: 14),
              Divider(height: 1, color: scheme.outlineVariant),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: ocupado ? null : () => responder('recusada'),
                      child: const Text('Recusar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: ocupado ? null : () => responder('aceita'),
                      child: const Text('Aceitar'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusConvite extends StatelessWidget {
  const _StatusConvite({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (texto, fundo, frente) = switch (status) {
      'aceita' => ('Aceito', const Color(0xFFE4F5EB), const Color(0xFF176B3A)),
      'recusada' => (
          'Recusado',
          scheme.errorContainer,
          scheme.onErrorContainer
        ),
      _ => ('Pendente', const Color(0xFFFFF3CD), const Color(0xFF725800)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        texto,
        style:
            TextStyle(color: frente, fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _EstadoVazio extends StatelessWidget {
  const _EstadoVazio({
    required this.icone,
    required this.titulo,
    required this.descricao,
    this.acao,
    this.textoAcao,
  });

  final IconData icone;
  final String titulo;
  final String descricao;
  final VoidCallback? acao;
  final String? textoAcao;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icone, color: scheme.onPrimaryContainer, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              descricao,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.45,
                  ),
            ),
            if (acao != null && textoAcao != null) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: acao,
                icon: const Icon(Icons.add_rounded),
                label: Text(textoAcao!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErroCarregamento extends StatelessWidget {
  const _ErroCarregamento({
    required this.mensagem,
    required this.tentarNovamente,
  });

  final String mensagem;
  final VoidCallback tentarNovamente;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: scheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(mensagem,
                style: TextStyle(color: scheme.onErrorContainer)),
          ),
          TextButton(
            onPressed: tentarNovamente,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}
