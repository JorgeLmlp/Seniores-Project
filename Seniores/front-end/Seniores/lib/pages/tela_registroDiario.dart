import 'package:flutter/material.dart';
import '../widgets/custom_textos.dart';
import '../widgets/custom_textField.dart';
import '../widgets/custom_botao.dart';
import '../widgets/custom_barraPersonalizada.dart';
import '../widgets/custom_menu.dart';
import '../models/incidente.dart';
import '../models/registroDiario.dart';
import '../utils/cores.dart';
import 'tela_relatorio.dart';

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
  final TextEditingController incidenteDescricaoController = TextEditingController();
  final TextEditingController horarioController = TextEditingController(text: "10:00");
  final TextEditingController duvidasController = TextEditingController();
  final List<Incidente> listaIncidentes = [];

  @override
  void dispose() {
    observacoesController.dispose();
    incidenteDescricaoController.dispose();
    horarioController.dispose();
    duvidasController.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.branco,
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
                    cor: Cores.preto,
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today_rounded, color: Cores.azul, size: 28),
                    onPressed: () {},
                  ),
                ],
              ),
              const AppText(
                texto: 'Hoje, 15/04',
                tamanho: 18,
                peso: FontWeight.bold,
                cor: Cores.azul,
              ),
              const SizedBox(height: 12),
              const Divider(thickness: 1.5, color: Cores.cinza),
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
                cor: Cores.azul,
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
                cor: Cores.azul,
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
                    cor: Cores.preto,
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
                            listaIncidentes.add(
                              Incidente(
                                titulo: incidenteTipoSelecionado == 0 ? 'Incidente' : 'Queda',
                                hora: horarioController.text,
                                descricao: incidenteDescricaoController.text,
                                gravidade: 'Média',
                              ),
                            );
                            incidenteDescricaoController.clear();
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(thickness: 1, color: Cores.cinza),
              const SizedBox(height: 8),

              Column(
                children: listaIncidentes.map((incidente) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                        const SizedBox(width: 6),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(color: Colors.amber, fontSize: 14, fontFamily: 'Inter'),
                              children: [
                                TextSpan(
                                  text: '${incidente.titulo} às ${incidente.hora}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: ' - ${incidente.descricao}'),
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
                texto: 'Dúvidas para próxima consulta',
                tamanho: 18,
                peso: FontWeight.bold,
                cor: Cores.azul,
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
                  texto: 'Concluir',
                  largura: 160,
                  altura: 45,
                  borderRadius: 12,
                  onPressed: () {
                    final intValHumor = humor <= 1.0 ? (humor * 10).round() : humor.round();
                    final intValDor = dor <= 1.0 ? (dor * 10).round() : dor.round();
                    final intValApetite = apetite <= 1.0 ? (apetite * 10).round() : apetite.round();
                    final intValMobilidade = mobilidade <= 1.0 ? (mobilidade * 10).round() : mobilidade.round();

                    final novoRegistro = Registro(
                      humor: intValHumor,
                      dor: intValDor,
                      apetite: intValApetite,
                      mobilidade: intValMobilidade,
                      listaIncidentes: listaIncidentes,
                      tendencia: "Estável",
                      dataFormatada: "Hoje, 15/04",
                      observacoes: observacoesController.text,
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Relatorio(registro: novoRegistro),
                      ),
                    );
                  },
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
}