import 'package:flutter/material.dart';
import '../widgets/custom_textos.dart';
import '../widgets/custom_botao.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_menu.dart';
import '../widgets/custom_bolinhas.dart';
import 'tela_medicamentos.dart';
import 'tela_registroDiario.dart';
import 'tela_cuidados.dart';
import 'tela_notificacoes.dart';
import 'tela_login.dart';
import '../services/session_service.dart';
import '../models/registroDiario.dart';
import '../models/medicamento.dart';
import 'tela_conta.dart';
import 'tela_estoque.dart';
import 'tela_seguranca.dart';
import 'tela_gastos.dart';
import 'tela_cuidadores.dart';
import 'tela_comunicados.dart';
import 'tela_relatorios.dart';
import 'tela_selecionar_paciente.dart';
import '../services/api_service.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  RegistroModel? registroAtual;
  bool _carregandoPacientes = false;
  List<Medicamento> _proximosMedicamentos = [];

  @override
  void initState() {
    super.initState();
    _prepararPacienteSelecionado();
  }

  Future<void> _prepararPacienteSelecionado() async {
    if (SessionService.instance.tipoUsuario == 'paciente') {
      await Future.wait([
        _carregarResumoMedicamentos(),
        _carregarResumoDiario(),
      ]);
      return;
    }
    setState(() => _carregandoPacientes = true);
    try {
      final pacientes = await ApiService().listarPacientesVinculados();
      if (!mounted) return;
      if (SessionService.instance.pacienteSelecionadoId == null &&
          pacientes.length == 1) {
        await SessionService.instance.selecionarPaciente(
          pacientes.first.id,
          pacientes.first.nome,
        );
      }
      if (SessionService.instance.pacienteSelecionadoId != null) {
        await Future.wait([
          _carregarResumoMedicamentos(),
          _carregarResumoDiario(),
        ]);
      }
    } on ApiException catch (_) {
      // A tela de seleção exibirá o erro detalhado quando for aberta.
    } finally {
      if (mounted) setState(() => _carregandoPacientes = false);
    }
  }

  Future<void> _trocarPaciente() async {
    final mudou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SelecionarPaciente()),
    );
    if (mudou == true && mounted) {
      setState(() {});
      await _carregarResumoMedicamentos();
    }
  }

  Future<void> _carregarResumoMedicamentos() async {
    try {
      final medicamentos = await ApiService().listarMedicamentos(
        SessionService.instance.pacienteId,
      );
      if (mounted) setState(() => _proximosMedicamentos = medicamentos);
    } on ApiException {
      if (mounted) setState(() => _proximosMedicamentos = []);
    } on StateError {
      if (mounted) setState(() => _proximosMedicamentos = []);
    }
  }

  Future<void> _carregarResumoDiario() async {
    try {
      final registros = await ApiService().listarRegistrosDiarios(
        SessionService.instance.pacienteId,
      );
      final hoje = DateTime.now();
      final registroHoje = registros.where((registro) {
        final data = registro.data;
        return data != null &&
            data.year == hoje.year &&
            data.month == hoje.month &&
            data.day == hoje.day;
      }).firstOrNull;
      if (mounted) setState(() => registroAtual = registroHoje);
    } on ApiException {
      if (mounted) setState(() => registroAtual = null);
    } on StateError {
      if (mounted) setState(() => registroAtual = null);
    }
  }

  String _dataAtual() {
    final agora = DateTime.now();
    return '${agora.day.toString().padLeft(2, '0')}/${agora.month.toString().padLeft(2, '0')}';
  }

  Future<void> _sair() async {
    await SessionService.instance.encerrar();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Login()),
      (_) => false,
    );
  }

  Future<void> _abrirRegistroDiario() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegistroDiario()),
    );

    if (resultado != null && resultado is RegistroModel) {
      setState(() {
        registroAtual = resultado;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      endDrawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 10),
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  "Cuidados",
                  style: TextStyle(
                    color: Color(0xFF275DAD),
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.medication),
                title: const Text("Medicamentos"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Medicamentos(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.health_and_safety),
                title: const Text("Exames e consultas"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Cuidados()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text("Diário de saúde"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegistroDiario()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text("Cuidadores"),
                trailing: const Icon(Icons.chevron_right),
                onTap: SessionService.instance.tipoUsuario != 'paciente'
                    ? null
                    : () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const Cuidadores()),
                        );
                      },
              ),
              if (SessionService.instance.tipoUsuario != 'paciente')
                ListTile(
                  leading: const Icon(Icons.switch_account),
                  title: const Text('Trocar paciente'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    _trocarPaciente();
                  },
                ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Controle",
                  style: TextStyle(
                    color: Color(0xFF275DAD),
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.campaign),
                title: const Text("Comunicados"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Comunicados()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_money),
                title: const Text("Gastos"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Gastos()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: const Text("Estoque"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Estoque()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text("Relatórios"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Relatorios()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text("Notificações"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Notificacoes()),
                  );
                },
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Configurações",
                  style: TextStyle(
                    color: Color(0xFF275DAD),
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text("Configurações"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MinhaConta()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.emergency_outlined),
                title: const Text("Segurança e emergência"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Seguranca()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_circle),
                title: const Text("Minha conta"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MinhaConta()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text("Sair da conta"),
                trailing: const Icon(Icons.chevron_right),
                onTap: _sair,
              ),
            ],
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        texto:
                            'Olá, ${SessionService.instance.nomeUsuario ?? 'usuário'}!',
                        tamanho: 28,
                        peso: FontWeight.bold,
                        cor: Colors.black,
                        estilo: AppText.titulo,
                      ),
                      SizedBox(height: 4),
                      AppText(
                        texto: "Como você está se sentindo hoje?",
                        tamanho: 14,
                        cor: Color(0xFF636E72),
                        estilo: AppText.corpo,
                      ),
                    ],
                  ),
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () {
                        Scaffold.of(context).openEndDrawer();
                      },
                    ),
                  ),
                ],
              ),

              if (SessionService.instance.tipoUsuario != 'paciente') ...[
                const SizedBox(height: 16),
                Card(
                  color: const Color(0xFFEAF1FF),
                  child: ListTile(
                    leading: const Icon(Icons.switch_account),
                    title: Text(
                      SessionService.instance.pacienteSelecionadoNome == null
                          ? 'Nenhum paciente selecionado'
                          : 'Paciente: ${SessionService.instance.pacienteSelecionadoNome}',
                    ),
                    subtitle: Text(
                      _carregandoPacientes
                          ? 'Carregando vínculos...'
                          : 'Toque para trocar o paciente',
                    ),
                    onTap: _trocarPaciente,
                  ),
                ),
              ],

              const SizedBox(height: 25),

              // Card diário de saúde
              CardPadrao(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CardTitulo(titulo: "Diário de saúde", data: _dataAtual()),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: registroAtual == null
                          ? Column(
                              children: [
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.grey,
                                      size: 18,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      "Ainda não há registro diário hoje",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                const Text(
                                  "Registre humor, dor e eventos\npara acompanhar a evolução",
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                Botao(
                                  texto: 'Registrar dia de hoje',
                                  icone: Icons.edit_square,
                                  largura: 250,
                                  altura: 45,
                                  fontSize: 15,
                                  backgroundColor: const Color(0xFF275DAD),
                                  textColor: Colors.white,
                                  onPressed: _abrirRegistroDiario,
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                IntrinsicHeight(
                                  child: Row(
                                    children: [
                                      const VerticalDivider(
                                        thickness: 2,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          IndicadorPontos(
                                            label: "Humor",
                                            valor: registroAtual!.humor,
                                          ),

                                          IndicadorPontos(
                                            label: "Dor",
                                            valor: registroAtual!.dor,
                                            inverso: true,
                                          ),

                                          IndicadorPontos(
                                            label: "Apetite",
                                            valor: registroAtual!.apetite,
                                          ),

                                          IndicadorPontos(
                                            label: "Mobilidade",
                                            valor: registroAtual!.mobilidade,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.amber,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "${registroAtual!.totalIncidentes} incidente registrado hoje",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Text(
                                      "Tendência: ",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      registroAtual!.tendencia,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.trending_down, size: 18),
                                  ],
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              CardPadrao(
                child: Column(
                  children: [
                    const CardTitulo(titulo: "Próximos medicamentos"),
                    if (_proximosMedicamentos.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(18),
                        child: Text('Nenhum medicamento cadastrado.'),
                      )
                    else
                      ..._proximosMedicamentos
                          .take(3)
                          .map(
                            (medicamento) => ListTile(
                              leading: const Icon(Icons.medication_outlined),
                              title: Text(medicamento.nome),
                              subtitle: Text(
                                medicamento.horarios.isEmpty
                                    ? medicamento.dosagem
                                    : '${medicamento.dosagem} • ${medicamento.horarios.join(', ')}',
                              ),
                            ),
                          ),
                    const Divider(),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),

      bottomNavigationBar: const Menu(paginaAtual: 0),
    );
  }
}
