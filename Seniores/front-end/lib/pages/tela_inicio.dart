import 'package:flutter/material.dart';
import '../../widgets/custom_textos.dart';
import '../../widgets/custom_botao.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_menu.dart';
import '../../widgets/custom_bolinhas.dart';
import '../../widgets/custom_menuSanduiche.dart';
import '../../models/registroDiario.dart';
import '../../utils/cores.dart';
import '../../pages/registro diario/tela_relatorio.dart';
import '../../pages/cuidados/tela_cuidados.dart';
import '../../services/api_service.dart';

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
    _carregarUltimoRegistro();
    _carregarNomeUsuario();
    _carregarMedicamentos();
  }

  Future<void> _carregarNomeUsuario() async {
    try {
      final perfil = await _apiService.obterPerfilUsuario();
      if (mounted && perfil != null) {
        String? nomeCompleto = perfil['nome_completo'] ?? perfil['nome'];
        if (nomeCompleto != null && nomeCompleto.isNotEmpty) {
          setState(() {
            nomeUsuario = nomeCompleto.trim().split(' ')[0];
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _carregarUltimoRegistro() async {
    try {
      final registros = await _apiService.listarDiarios();
      if (mounted && registros.isNotEmpty) {
        setState(() => registroAtual = Registro.fromApiJson(registros.first));
      }
    } on ApiException {}
  }

  Future<void> _carregarMedicamentos() async {
    try {
      final medicamentos = await _apiService.listarMedicamentos();
      if (mounted) {
        setState(() {
          proximosMedicamentos = medicamentos;
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
      backgroundColor: Cores.fundoTela,
      endDrawer: const MenuSanduiche(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        texto: "Olá, $nomeUsuario!",
                        tamanho: 28,
                        peso: FontWeight.bold,
                        cor: Cores.preto,
                        estilo: AppText.titulo,
                      ),
                      const SizedBox(height: 4),
                      const AppText(
                        texto: "Como voce esta se sentindo hoje?",
                        tamanho: 14,
                        cor: Cores.cinza,
                        estilo: AppText.corpo,
                      ),
                    ],
                  ),
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu, size: 28, color: Cores.preto),
                      onPressed: () => Scaffold.of(context).openEndDrawer(),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _abrirDetalhesDiario,
                      borderRadius: BorderRadius.circular(16),
                      child: CardPadrao(
                        altura: 95,
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Cores.azul.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.favorite_border, color: Cores.azul, size: 22),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Resumo de saúde",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Cores.preto,
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
                  const SizedBox(width: 12),
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
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.calendar_today_outlined, color: Colors.green, size: 22),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Proximos eventos",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Cores.preto,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    "1 consulta hoje as 14:00",
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
              const SizedBox(height: 20),

              InkWell(
                onTap: _abrirDetalhesDiario,
                borderRadius: BorderRadius.circular(20),
                child: CardPadrao(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CardTitulo(
                        titulo: "Diário de saúde",
                        data: registroAtual?.dataFormatada ?? "13/04",
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: registroAtual == null
                            ? Column(
                                children: [
                                  const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.warning_amber_rounded,
                                          color: Cores.cinza, size: 18),
                                      SizedBox(width: 5),
                                      Text(
                                        "1 incidente registrado hoje",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
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
                                        const VerticalDivider(
                                            thickness: 2, color: Cores.cinza),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            IndicadorPontos(
                                              label: "Humor",
                                              valor: registroAtual!.humor.toDouble(),
                                            ),
                                            IndicadorPontos(
                                              label: "Dor",
                                              valor: registroAtual!.dor.toDouble(),
                                              inverso: true,
                                            ),
                                            IndicadorPontos(
                                              label: "Apetite",
                                              valor: registroAtual!.apetite.toDouble(),
                                            ),
                                            IndicadorPontos(
                                              label: "Mobilidade",
                                              valor: registroAtual!.mobilidade.toDouble(),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      const Icon(Icons.warning_amber_rounded,
                                          color: Cores.amarelo, size: 20),
                                      const SizedBox(width: 6),
                                      Text(
                                        "${registroAtual!.totalIncidentes} incidente registrado hoje",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Text("Tendência: ",
                                          style: TextStyle(
                                              color: Cores.cinza, fontSize: 13)),
                                      Text(
                                        registroAtual!.tendencia ?? 'Leve piora',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.trending_down,
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
              const SizedBox(height: 20),

              CardPadrao(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Próximos medicamentos",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Cores.azul,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.fiber_manual_record, size: 8, color: Cores.azul),
                              const SizedBox(width: 4),
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
                    const Divider(height: 1, color: Colors.black12),
                    carregandoMedicamentos
                        ? const Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : proximosMedicamentos.isEmpty
                            ? const Padding(
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
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: proximosMedicamentos.length > 5
                                    ? 5
                                    : proximosMedicamentos.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 1, color: Colors.black12),
                                itemBuilder: (context, index) {
                                  final med = proximosMedicamentos[index];
                                  final horarioMedicamento = _obterHorarioDoMedicamento(med);
                                  final diferencaMinutos = _calcularDiferencaMinutos(horarioMedicamento);

                                  bool isAtrasado = diferencaMinutos < 0;
                                  bool isAtencao = diferencaMinutos >= 0 && diferencaMinutos <= 10;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0, vertical: 12.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              isAtrasado
                                                  ? Icons.warning_amber_rounded
                                                  : Icons.fiber_manual_record,
                                              size: isAtrasado ? 20 : 12,
                                              color: isAtrasado
                                                  ? Cores.vermelho
                                                  : (isAtencao
                                                      ? Cores.amarelo
                                                      : Cores.azul),
                                            ),
                                            const SizedBox(width: 12),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  med['nome'] ?? 'Dipirona 500mg',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: isAtrasado
                                                        ? Cores.vermelho
                                                        : Cores.preto,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  "${med['dosagem'] ?? '1 comprimido'} - $horarioMedicamento",
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Cores.cinza,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          height: 32,
                                          child: ElevatedButton(
                                            onPressed: () {},
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: isAtrasado
                                                  ? Cores.vermelho
                                                  : (isAtencao
                                                      ? Cores.amarelo
                                                      : Cores.azul),
                                              foregroundColor: Cores.branco,
                                              elevation: 0,
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 16),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                            ),
                                            child: Text(
                                              isAtrasado ? "Atrasado" : "Concluir",
                                              style: const TextStyle(
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const Menu(paginaAtual: 0),
    );
  }
}