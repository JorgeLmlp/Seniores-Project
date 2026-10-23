import 'package:flutter/material.dart';
import '../widgets/custom_textos.dart';
import '../widgets/custom_textField.dart';
import '../widgets/custom_botao.dart';
import '../widgets/custom_barraPersonalizada.dart';
import '../models/registroDiario.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../widgets/custom_menu.dart';

class RegistroDiario extends StatefulWidget {
  const RegistroDiario({super.key});

  @override
  State<RegistroDiario> createState() => _RegistroDiarioState();
}

class _RegistroDiarioState extends State<RegistroDiario> {
  double humor = 0.0;
  double dor = 0.0;
  double apetite = 0.0;
  double mobilidade = 0.0;
  int incidenteTipoSelecionado = 0;

  final TextEditingController observacoesController = TextEditingController();
  final TextEditingController incidenteDescricaoController =
      TextEditingController();
  final TextEditingController horarioController = TextEditingController(
    text: "10:00",
  );
  final TextEditingController duvidasController = TextEditingController();
  final List<Map<String, dynamic>> listaIncidentes = [];
  bool _salvando = false;
  DateTime _dataRegistro = DateTime.now();

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  Future<void> _selecionarData() async {
    final escolhida = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDate: _dataRegistro.isAfter(DateTime.now())
          ? DateTime.now()
          : _dataRegistro,
    );
    if (escolhida != null && mounted) {
      setState(() => _dataRegistro = escolhida);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color azulTema = Color(0xFF275DAD);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AppText(
                    texto: 'Registro diário',
                    tamanho: 24,
                    peso: FontWeight.bold,
                    cor: Colors.black,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.calendar_today_rounded,
                      color: azulTema,
                      size: 28,
                    ),
                    onPressed: _selecionarData,
                  ),
                ],
              ),
              AppText(
                texto: 'Registro de ${_formatarData(_dataRegistro)}',
                tamanho: 18,
                peso: FontWeight.bold,
                cor: azulTema,
              ),
              const SizedBox(height: 12),
              const Divider(thickness: 1.5, color: Color(0xFFDCDCDC)),
              const SizedBox(height: 16),

              ItemNivelSaude(
                titulo: 'Humor',
                valor: humor,
                onChanged: (val) => setState(() => humor = val),
              ),
              ItemNivelSaude(
                titulo: 'Dor',
                valor: dor,
                inverso: true,
                onChanged: (val) => setState(() => dor = val),
              ),
              ItemNivelSaude(
                titulo: 'Apetite',
                valor: apetite,
                onChanged: (val) => setState(() => apetite = val),
              ),
              ItemNivelSaude(
                titulo: 'Mobilidade',
                valor: mobilidade,
                onChanged: (val) => setState(() => mobilidade = val),
              ),

              const SizedBox(height: 20),

              const AppText(
                texto: 'Observações',
                tamanho: 18,
                peso: FontWeight.bold,
                cor: azulTema,
              ),
              const SizedBox(height: 8),
              CampoTexto(
                hintText: 'Digite aqui..',
                controller: observacoesController,
              ),

              const SizedBox(height: 20),

              const AppText(
                texto: 'Incidentes',
                tamanho: 18,
                peso: FontWeight.bold,
                cor: azulTema,
              ),
              const SizedBox(height: 12),

              GrupoBotoes(
                itens: const ['Incidente', 'Queda'],
                selecionado: incidenteTipoSelecionado,
                onSelecionado: (index) {
                  setState(() => incidenteTipoSelecionado = index);
                },
              ),
              const SizedBox(height: 12),

              CampoTexto(
                hintText: 'Descrição..',
                controller: incidenteDescricaoController,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const AppText(
                    texto: 'Às',
                    tamanho: 14,
                    peso: FontWeight.bold,
                    cor: Colors.black87,
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 90,
                    height: 48,
                    child: CampoTexto(
                      hintText: '10:00',
                      controller: horarioController,
                      keyboardType: TextInputType.datetime,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Botao(
                      texto: 'Adicionar',
                      altura: 48,
                      borderRadius: 10,
                      onPressed: () {
                        if (incidenteDescricaoController.text.isNotEmpty) {
                          setState(() {
                            listaIncidentes.add({
                              'tipo': incidenteTipoSelecionado == 0
                                  ? 'Incidente'
                                  : 'Queda',
                              'hora': horarioController.text,
                              'descricao': incidenteDescricaoController.text,
                              'cor': Colors.amber,
                            });
                            incidenteDescricaoController.clear();
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(thickness: 1, color: Color(0xFFE0E0E0)),
              const SizedBox(height: 8),

              Column(
                children: listaIncidentes.map((incidente) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: incidente['cor'],
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                color: incidente['cor'],
                                fontSize: 14,
                                fontFamily: 'Inter',
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      '${incidente['tipo']} às ${incidente['hora']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(text: ' - ${incidente['descricao']}'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              const AppText(
                texto: 'Duvidas para próxima consulta',
                tamanho: 18,
                peso: FontWeight.bold,
                cor: azulTema,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: CampoTexto(
                  hintText: 'Digite aqui..',
                  controller: duvidasController,
                ),
              ),

              const SizedBox(height: 24),

              Center(
                child: Botao(
                  texto: _salvando ? 'Salvando...' : 'Concluir',
                  largura: 160,
                  altura: 45,
                  borderRadius: 12,
                  onPressed: _salvando ? () {} : _concluir,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),

      bottomNavigationBar: const Menu(paginaAtual: 3),
    );
  }

  Future<void> _concluir() async {
    final humorAtual = humor <= 1.0 ? humor * 10 : humor;
    final dorAtual = dor <= 1.0 ? dor * 10 : dor;
    final apetiteAtual = apetite <= 1.0 ? apetite * 10 : apetite;
    final mobilidadeAtual = mobilidade <= 1.0 ? mobilidade * 10 : mobilidade;
    final tendencia = await _calcularTendencia(
      humorAtual,
      dorAtual,
      apetiteAtual,
      mobilidadeAtual,
    );
    final novoRegistro = RegistroModel(
      data: _dataRegistro,
      humor: humorAtual,
      dor: dorAtual,
      apetite: apetiteAtual,
      mobilidade: mobilidadeAtual,
      totalIncidentes: listaIncidentes.length,
      tendencia: tendencia,
      observacoes: observacoesController.text.trim(),
      duvidas: duvidasController.text.trim(),
    );
    setState(() => _salvando = true);
    try {
      final salvo = await ApiService().criarRegistroDiario(
        SessionService.instance.pacienteId,
        novoRegistro,
      );
      if (!mounted) return;
      Navigator.pop(context, salvo);
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(exception.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar o diário.')),
      );
    }
  }

  Future<String> _calcularTendencia(
    double humorAtual,
    double dorAtual,
    double apetiteAtual,
    double mobilidadeAtual,
  ) async {
    try {
      final historico = await ApiService().listarRegistrosDiarios(
        SessionService.instance.pacienteId,
      );
      if (historico.isEmpty) return 'Primeiro registro';
      final anterior = historico.first;
      final atual =
          (humorAtual + (10 - dorAtual) + apetiteAtual + mobilidadeAtual) / 4;
      final passado =
          (anterior.humor +
              (10 - anterior.dor) +
              anterior.apetite +
              anterior.mobilidade) /
          4;
      final diferenca = atual - passado;
      if (diferenca >= 0.5) return 'Melhora';
      if (diferenca <= -0.5) return 'Atenção';
      return 'Estável';
    } catch (_) {
      return 'Sem comparação';
    }
  }
}
