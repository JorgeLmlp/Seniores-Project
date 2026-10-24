import '../models/medicamento.dart';
import 'medicamentos/tela_detalhes_medicamento.dart';
import 'package:flutter/material.dart';
import '../widgets/custom_textos.dart';
import '../widgets/custom_botao.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_menu.dart';
import '../widgets/custom_bolinhas.dart';
import '../widgets/custom_menu_sanduiche.dart';
import '../models/registro_diario.dart';
import '../utils/cores.dart';
import '../pages/registro diario/tela_relatorio.dart';
import '../pages/cuidados/tela_cuidados.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../widgets/app_feedback.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Registro? registroAtual;
  String nomeUsuario = "nome";
  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> proximosMedicamentos = [];
  bool carregandoMedicamentos = true;

  @override
  void initState() {
    super.initState();
    if (SessionService.instance.tipoUsuario != 'paciente' &&
        SessionService.instance.pacienteSelecionado == null) { return;
    }
    _carregarUltimoRegistro();
    _carregarNomeUsuario();
    _carregarMedicamentos();
  }

  Future<void> _carregarNomeUsuario() async {
    try {
      String? nomeBruto = SessionService.instance.nomePaciente ??
          SessionService.instance.nomeUsuario;

      if (nomeBruto == null || nomeBruto.trim().isEmpty) {
        final perfil = await _apiService.obterPerfilUsuario();
        if (perfil != null) {
          nomeBruto =
              perfil['nome_completo'] ?? perfil['nome'] ?? perfil['name'];
        }
      }

      if (nomeBruto != null && nomeBruto.trim().isNotEmpty) {
        String primeiroNome = nomeBruto.trim().split(' ')[0];
        if (primeiroNome.isNotEmpty) {
          primeiroNome = primeiroNome[0].toUpperCase() +
              primeiroNome.substring(1).toLowerCase();
        }

        if (mounted) {
          setState(() {
            nomeUsuario = primeiroNome;
          });
        }
      }
    } catch (e) {
      debugPrint("Erro ao carregar nome do usuário: $e");
    }
  }

  Future<void> _carregarUltimoRegistro() async {
    try {
      final registros = await _apiService.listarDiarios();
      if (mounted && registros.isNotEmpty) {
        setState(() => registroAtual = Registro.fromApiJson(registros.first));
      }
    } on ApiException catch (erro) {
      debugPrint('Falha ao carregar último registro: ${erro.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Não foi possível carregar o último registro.'),
        ));
      }
    }
  }

  Future<void> _carregarMedicamentos() async {
    try {
      final medicamentos = await _apiService.listarMedicamentos();
      final hoje = DateTime.now().toIso8601String().substring(0, 10);
      final dosesDoDia = <Map<String, dynamic>>[];
      for (final medicamento in medicamentos) {
        Map<String, dynamic> status = {};
        try {
          status = Map<String, dynamic>.from(
            await _apiService.requisicao(
              'GET',
              '/medicamentos/${medicamento['id']}/doses/$hoje',
            ) as Map,
          );
        } on ApiException {
          // A lista continua disponível mesmo se o status de uma dose falhar.
        }
        final horarios = (medicamento['horarios'] as List<dynamic>? ?? [])
            .map((horario) => horario.toString())
            .toList();
        if (horarios.isEmpty) {
          dosesDoDia.add({...medicamento, 'concluido': false});
        } else {
          for (final horario in horarios) {
            dosesDoDia.add({
              ...medicamento,
              'horario': horario,
              'concluido': status[horario] == true,
            });
          }
        }
      }
      if (mounted) {
        setState(() {
          proximosMedicamentos = dosesDoDia;
          carregandoMedicamentos = false;
        });
      }
    } on ApiException {
      if (mounted) {
        setState(() {
          carregandoMedicamentos = false;
        });
      }
    }
  }

  Future<void> _abrirDetalhesDiario() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => Relatorio(registro: registroAtual)),
    );

    if (resultado != null && resultado is Registro) {
      setState(() {
        registroAtual = resultado;
      });
    } else {
      _carregarUltimoRegistro();
    }
  }

  String _obterHorarioDoMedicamento(Map<String, dynamic> med) {
    if (med['horario'] != null) return med['horario'].toString();
    if (med['horarios'] != null && (med['horarios'] as List).isNotEmpty) {
      return med['horarios'][0].toString();
    }
    return "12:00";
  }

  int _calcularDiferencaMinutos(String horarioStr) {
    try {
      final partes = horarioStr.split(':');
      if (partes.length != 2) return 999;

      final int horaMed = int.parse(partes[0]);
      final int minMed = int.parse(partes[1]);

      final agora = DateTime.now();
      final minutosAtuais = agora.hour * 60 + agora.minute;
      final minutosMed = horaMed * 60 + minMed;

      return minutosMed - minutosAtuais;
    } catch (_) {
      return 999;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      endDrawer: const MenuSanduiche(paginaAtual: 'inicio'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        texto: "Olá, $nomeUsuario!",
                        tamanho: 28,
                        peso: FontWeight.bold,
                        cor: Theme.of(context).colorScheme.onSurface,
                        estilo: AppText.titulo,
                      ),
                      SizedBox(height: 4),
                      AppText(
                        texto: "Como voce esta se sentindo hoje?",
                        tamanho: 14,
                        cor: Cores.cinza,
                        estilo: AppText.corpo,
                      ),
                    ],
                  )),
                  Builder(
                    builder: (context) => IconButton.filledTonal(
                      tooltip: 'Abrir menu',
                      icon: const Icon(Icons.menu_rounded, size: 25),
                      onPressed: () => Scaffold.of(context).openEndDrawer(),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _abrirDetalhesDiario,
                      borderRadius: BorderRadius.circular(16),
                      child: CardPadrao(
                        altura: 95,
                        padding: EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Cores.azul.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.favorite_border,
                                  color: Cores.azul, size: 22),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Resumo de saúde",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    "Veja seus principais indicadores",
                                    style: TextStyle(
                                      color: Cores.cinza,
                                      fontSize: 9,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Cuidados(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: CardPadrao(
                        altura: 95,
                        padding: EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.calendar_today_outlined,
                                  color: Colors.green, size: 22),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Proximos eventos",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    "Consulte sua agenda",
                                    style: TextStyle(
                                      color: Cores.cinza,
                                      fontSize: 9,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              InkWell(
                onTap: _abrirDetalhesDiario,
                borderRadius: BorderRadius.circular(20),
                child: CardPadrao(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CardTitulo(
                        titulo: "Diário de saúde",
                        data: registroAtual?.dataFormatada,
                      ),
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: registroAtual == null
                            ? Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.warning_amber_rounded,
                                          color: Cores.cinza, size: 18),
                                      SizedBox(width: 5),
                                      Expanded(
                                          child: Text(
                                        "Nenhum diário registrado",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      )),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Botao(
                                    texto: 'Ver detalhes do dia',
                                    icone: Icons.visibility_outlined,
                                    largura: 240,
                                    altura: 45,
                                    fontSize: 14,
                                    backgroundColor: Cores.azul,
                                    textColor: Cores.branco,
                                    onPressed: _abrirDetalhesDiario,
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  IntrinsicHeight(
                                    child: Row(
                                      children: [
                                        VerticalDivider(
                                            thickness: 2, color: Cores.cinza),
                                        SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            IndicadorPontos(
                                              label: "Humor",
                                              valor: registroAtual!.humor
                                                  .toDouble(),
                                            ),
                                            IndicadorPontos(
                                              label: "Dor",
                                              valor:
                                                  registroAtual!.dor.toDouble(),
                                              inverso: true,
                                            ),
                                            IndicadorPontos(
                                              label: "Apetite",
                                              valor: registroAtual!.apetite
                                                  .toDouble(),
                                            ),
                                            IndicadorPontos(
                                              label: "Mobilidade",
                                              valor: registroAtual!.mobilidade
                                                  .toDouble(),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded,
                                          color: Cores.amarelo, size: 20),
                                      SizedBox(width: 6),
                                      Expanded(
                                          child: Text(
                                        "${registroAtual!.totalIncidentes} incidente registrado hoje",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13),
                                      )),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text("Tendência: ",
                                          style: TextStyle(
                                              color: Cores.cinza,
                                              fontSize: 13)),
                                      Text(
                                        registroAtual!.tendencia ??
                                            'Leve piora',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(Icons.trending_down,
                                          size: 18, color: Cores.vermelho),
                                    ],
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              CardPadrao(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                              child: Text(
                            "Medicamentos de hoje",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Cores.azul,
                            ),
                          )),
                          Row(
                            children: [
                              Icon(Icons.fiber_manual_record,
                                  size: 8, color: Cores.azul),
                              SizedBox(width: 4),
                              Container(
                                width: 16,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Cores.cinza,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: Colors.black12),
                    carregandoMedicamentos
                        ? Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : proximosMedicamentos.isEmpty
                            ? Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Center(
                                  child: Text(
                                    "Nenhum medicamento cadastrado para hoje.",
                                    style: TextStyle(color: Cores.cinza),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: proximosMedicamentos.length > 5
                                    ? 5
                                    : proximosMedicamentos.length,
                                separatorBuilder: (context, index) =>
                                    Divider(height: 1, color: Colors.black12),
                                itemBuilder: (context, index) {
                                  final med = proximosMedicamentos[index];
                                  final horarioMedicamento =
                                      _obterHorarioDoMedicamento(med);
                                  final diferencaMinutos =
                                      _calcularDiferencaMinutos(
                                          horarioMedicamento);

                                  final concluido = med['concluido'] == true;
                                  bool isAtrasado =
                                      !concluido && diferencaMinutos < 0;
                                  bool isAtencao = !concluido &&
                                      diferencaMinutos >= 0 &&
                                      diferencaMinutos <= 10;
                                  final corStatus = concluido
                                      ? Cores.verde
                                      : isAtrasado
                                          ? Cores.vermelho
                                          : isAtencao
                                              ? Cores.amarelo
                                              : Cores.azul;

                                  return Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16.0, vertical: 12.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Icon(
                                                isAtrasado
                                                    ? Icons
                                                        .warning_amber_rounded
                                                    : concluido
                                                        ? Icons
                                                            .check_circle_rounded
                                                        : Icons
                                                            .fiber_manual_record,
                                                size: isAtrasado || concluido
                                                    ? 20
                                                    : 12,
                                                color: corStatus,
                                              ),
                                              SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      med['nome'] ??
                                                          'Dipirona 500mg',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                        color: concluido ||
                                                                isAtrasado
                                                            ? corStatus
                                                            : Theme.of(context)
                                                                .colorScheme
                                                                .onSurface,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    SizedBox(height: 2),
                                                    Text(
                                                      "${med['dosagem'] ?? '1 comprimido'} - $horarioMedicamento",
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: concluido
                                                            ? Cores.verde
                                                            : isAtrasado
                                                                ? Cores.vermelho
                                                                : Cores.cinza,
                                                        fontWeight: concluido ||
                                                                isAtrasado
                                                            ? FontWeight.w600
                                                            : FontWeight.normal,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        SizedBox(
                                          height: 32,
                                          child: ElevatedButton(
                                            onPressed: () async {
                                              final conclusao = await Navigator.push<
                                                      Map<String, String>>(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (_) =>
                                                          DetalhesMedicamento(
                                                              medicamento:
                                                                  Medicamento
                                                                      .fromJson(
                                                                          med))));
                                              if (mounted) {
                                                await _carregarMedicamentos();
                                                if (conclusao != null &&
                                                    mounted) {
                                                  mostrarFeedback(
                                                    this.context,
                                                    mensagem:
                                                        'A dose de ${conclusao['nome']} das ${conclusao['horario']} foi marcada como concluída.',
                                                    tipo: TipoFeedback.sucesso,
                                                    titulo:
                                                        'Medicamento concluído',
                                                  );
                                                }
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: corStatus,
                                              foregroundColor: Cores.branco,
                                              elevation: 0,
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 16),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                            ),
                                            child: Text(
                                              "Ver doses",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                  ],
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Menu(paginaAtual: 0),
    );
  }
}
