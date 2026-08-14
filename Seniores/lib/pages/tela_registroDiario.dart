import 'package:flutter/material.dart';
import '../widgets/custom_textos.dart';
import '../widgets/custom_textField.dart';
import '../widgets/custom_botao.dart';
import '../widgets/custom_barraPersonalizada.dart';
import '../models/registroDiario.dart';

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
  final List<Map<String, dynamic>> listaIncidentes = [];

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
                    icon: const Icon(Icons.calendar_today_rounded, color: azulTema, size: 28),
                    onPressed: () {},
                  ),
                ],
              ),
              const AppText(
                texto: 'Hoje, 15/04',
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
                              'tipo': incidenteTipoSelecionado == 0 ? 'Incidente' : 'Queda',
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
                        Icon(Icons.warning_amber_rounded, color: incidente['cor'], size: 20),
                        const SizedBox(width: 6),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(color: incidente['cor'], fontSize: 14, fontFamily: 'Inter'),
                              children: [
                                TextSpan(
                                  text: '${incidente['tipo']} às ${incidente['hora']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
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
                  texto: 'Concluir',
                  largura: 160,
                  altura: 45,
                  borderRadius: 12,
                  onPressed: () {
                  final novoRegistro = RegistroModel(
                    humor: humor <= 1.0 ? humor * 10 : humor,
                    dor: dor <= 1.0 ? dor * 10 : dor,
                    apetite: apetite <= 1.0 ? apetite * 10 : apetite,
                    mobilidade: mobilidade <= 1.0 ? mobilidade * 10 : mobilidade,
                    totalIncidentes: listaIncidentes.length,
                    tendencia: "Leve piora",
                  );
                  Navigator.pop(context, novoRegistro);
                },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: azulTema,
        unselectedItemColor: Colors.grey.shade600,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.medication_outlined), label: 'Medicamentos'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Cuidados'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Diário de saúde'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Mais'),
        ],
      ),
    );
  }
}
