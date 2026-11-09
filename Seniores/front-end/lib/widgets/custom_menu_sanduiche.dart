import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/registro_diario.dart';
import '../pages/comunicados/tela_comunicados.dart';
import '../pages/cuidados/tela_cuidados.dart';
import '../pages/cuidados/tela_documentos_exames.dart';
import '../pages/gastos/tela_gastos.dart';
import '../pages/medicamentos/tela_medicamentos.dart';
import '../pages/registro diario/tela_relatorio.dart';
import '../pages/tela_conta.dart';
import '../pages/tela_inicio.dart';
import '../pages/tela_pdf.dart';
import '../pages/modulos_clinicos.dart';
import '../pages/tela_vinculos.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';

class MenuSanduiche extends StatelessWidget {
  const MenuSanduiche({super.key, this.paginaAtual});

  final String? paginaAtual;

  @override
  Widget build(BuildContext context) {
    final session = SessionService.instance;
    final temPaciente = session.tipoUsuario == 'paciente' ||
        session.pacienteSelecionado != null;
    final largura = math.min(MediaQuery.sizeOf(context).width * 0.78, 320.0);

    return Drawer(
      width: largura,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        left: false,
        child: Column(
          children: [
            _CabecalhoMenu(session: session),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
                children: [
                  if (temPaciente) ...[
                    _ItemMenu(
                      icon: Icons.dashboard_rounded,
                      title: 'Visão geral',
                      ativo: paginaAtual == 'inicio',
                      onTap: () => _abrir(context, const Home(), 'inicio'),
                    ),
                  ],
                  if (session.tipoUsuario != 'paciente') ...[
                    _ItemMenu(
                      icon: Icons.group_rounded,
                      title: 'Pacientes e vínculos',
                      ativo: paginaAtual == 'vinculos',
                      onTap: () =>
                          _abrir(context, const Vinculos(), 'vinculos'),
                    ),
                  ],
                  if (!temPaciente) ...[
                    const SizedBox(height: 10),
                    const _AvisoPaciente(),
                  ],
                  if (temPaciente) ...[
                    const _TituloGrupo(title: 'Cuidados'),
                    _ItemMenu(
                      icon: Icons.medication_rounded,
                      title: 'Medicamentos',
                      onTap: () =>
                          _abrir(context, const Medicamentos(), 'medicamentos'),
                    ),
                    _ItemMenu(
                      icon: Icons.health_and_safety_rounded,
                      title: 'Exames e consultas',
                      onTap: () =>
                          _abrir(context, const Cuidados(), 'cuidados'),
                    ),
                    _ItemMenu(icon: Icons.attach_file_rounded, title: 'Documentos de exames',
                      onTap: () => _abrir(context, const DocumentosExames(), 'documentos')),
                    _ItemMenu(
                      icon: Icons.monitor_heart_rounded,
                      title: 'Diário de saúde',
                      onTap: () => _abrirDiario(context),
                    ),
                    const _TituloGrupo(title: 'Acompanhamento'),
                    _ItemMenu(icon: Icons.monitor_heart_outlined, title: 'Sinais vitais',
                      onTap: () => _abrir(context, const ModuloClinico(config: ModulosSeniores.sinais), 'sinais')),
                    _ItemMenu(icon: Icons.inventory_2_outlined, title: 'Estoque',
                      onTap: () => _abrir(context, const ModuloClinico(config: ModulosSeniores.estoque), 'estoque')),
                    _ItemMenu(icon: Icons.report_outlined, title: 'Incidentes',
                      onTap: () => _abrir(context, const ModuloClinico(config: ModulosSeniores.incidentes), 'incidentes')),
                    _ItemMenu(icon: Icons.contact_emergency_outlined, title: 'Contatos de emergência',
                      onTap: () => _abrir(context, const ModuloClinico(config: ModulosSeniores.contatos), 'contatos')),
                    _ItemMenu(icon: Icons.restaurant_outlined, title: 'Dietas e restrições',
                      onTap: () => _abrir(context, const ModuloClinico(config: ModulosSeniores.dietas), 'dietas')),
                    _ItemMenu(icon: Icons.clean_hands_outlined, title: 'Checklist de higiene',
                      onTap: () => _abrir(context, const ModuloClinico(config: ModulosSeniores.higiene), 'higiene')),
                    _ItemMenu(icon: Icons.healing_outlined, title: 'Lesões',
                      onTap: () => _abrir(context, const ModuloClinico(config: ModulosSeniores.lesoes), 'lesoes')),
                    _ItemMenu(icon: Icons.notification_important_outlined, title: 'Histórico de alertas',
                      onTap: () => _abrir(context, const ModuloClinico(config: ModulosSeniores.alertas), 'alertas')),
                    const _TituloGrupo(title: 'Organização'),
                    _ItemMenu(
                      icon: Icons.campaign_rounded,
                      title: 'Comunicados',
                      onTap: () => _abrir(
                        context,
                        const Destinatarios(),
                        'comunicados',
                      ),
                    ),
                    _ItemMenu(
                      icon: Icons.account_balance_wallet_rounded,
                      title: 'Gastos',
                      onTap: () => _abrir(context, const Gastos(), 'gastos'),
                    ),
                    _ItemMenu(
                      icon: Icons.description_rounded,
                      title: 'Relatórios',
                      onTap: () =>
                          _abrir(context, const RelatoriosPdf(), 'relatorios'),
                    ),
                  ],
                  const _TituloGrupo(title: 'Conta'),
                  _ItemMenu(
                    icon: Icons.person_rounded,
                    title: 'Minha conta',
                    onTap: () => _abrir(context, const MinhaConta(), 'conta'),
                  ),
                  _ItemMenu(
                    icon: Icons.tune_rounded,
                    title: 'Configurações',
                    onTap: () =>
                        _abrir(context, const Configuracoes(), 'configuracoes'),
                  ),
                  const SizedBox(height: 12),
                  Divider(color: Theme.of(context).colorScheme.outlineVariant),
                  const SizedBox(height: 8),
                  _ItemMenu(
                    icon: Icons.logout_rounded,
                    title: 'Sair da conta',
                    destrutivo: true,
                    mostrarSeta: false,
                    onTap: () => _sair(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _abrir(BuildContext context, Widget pagina, String identificador) {
    Navigator.pop(context);
    if (paginaAtual == identificador) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => pagina));
  }

  Future<void> _abrirDiario(BuildContext context) async {
    final navigator = Navigator.of(context);
    navigator.pop();
    Registro? ultimoRegistro;
    try {
      final registros = await ApiService().listarDiarios();
      if (registros.isNotEmpty) {
        ultimoRegistro = Registro.fromApiJson(registros.first);
      }
    } on ApiException {
      // O relatório também funciona sem um registro carregado previamente.
    }
    navigator.push(
      MaterialPageRoute(builder: (_) => Relatorio(registro: ultimoRegistro)),
    );
  }

  Future<void> _sair(BuildContext context) async {
    Navigator.pop(context);
    await sairDaConta();
  }
}

class _CabecalhoMenu extends StatelessWidget {
  const _CabecalhoMenu({required this.session});

  final SessionService session;

  String get tipo => switch (session.tipoUsuario) {
        'responsavel' => 'Responsável',
        'cuidador' => 'Cuidador',
        _ => 'Paciente',
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final nome = session.nomeUsuario?.trim().isNotEmpty == true
        ? session.nomeUsuario!.trim()
        : 'Minha conta';
    final inicial = nome.isEmpty ? '?' : nome[0].toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 14, 12, 20),
      decoration: BoxDecoration(
        color: scheme.primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: 'Fechar menu',
              onPressed: () => Navigator.pop(context),
              style: IconButton.styleFrom(
                foregroundColor: scheme.onPrimary,
                backgroundColor: scheme.onPrimary.withValues(alpha: 0.12),
              ),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
          Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: scheme.onPrimary,
                foregroundColor: scheme.primary,
                child: Text(
                  inicial,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: scheme.onPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tipo,
                      style: TextStyle(
                        color: scheme.onPrimary.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (session.tipoUsuario != 'paciente' &&
              session.nomePaciente != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: scheme.onPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.favorite_rounded,
                      size: 18, color: scheme.onPrimary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cuidando de ${session.nomePaciente}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TituloGrupo extends StatelessWidget {
  const _TituloGrupo({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 22, 14, 8),
        child: Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
        ),
      );
}

class _ItemMenu extends StatelessWidget {
  const _ItemMenu({
    required this.icon,
    required this.title,
    required this.onTap,
    this.ativo = false,
    this.destrutivo = false,
    this.mostrarSeta = true,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool ativo;
  final bool destrutivo;
  final bool mostrarSeta;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cor = destrutivo
        ? scheme.error
        : ativo
            ? scheme.onPrimaryContainer
            : scheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        minTileHeight: 52,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        selected: ativo,
        selectedTileColor: scheme.primaryContainer,
        textColor: cor,
        iconColor: cor,
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: ativo
                ? scheme.primary.withValues(alpha: 0.12)
                : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 21),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        trailing: mostrarSeta
            ? Icon(Icons.chevron_right_rounded,
                size: 20, color: scheme.onSurfaceVariant)
            : null,
        onTap: onTap,
      ),
    );
  }
}

class _AvisoPaciente extends StatelessWidget {
  const _AvisoPaciente();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: scheme.onSecondaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Selecione um paciente para liberar as opções de cuidado.',
              style: TextStyle(
                color: scheme.onSecondaryContainer,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
