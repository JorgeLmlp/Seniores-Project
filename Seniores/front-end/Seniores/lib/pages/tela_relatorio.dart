import 'package:flutter/material.dart';
import '../models/registroDiario.dart';
import '../widgets/custom_menu.dart';
import '../widgets/custom_bolinhas.dart';
import '../utils/cores.dart';

class Relatorio extends StatelessWidget {
  final Registro registro;

  const Relatorio({super.key, required this.registro});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.branco,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Cores.preto),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          'Relatório',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Cores.preto,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Hoje, ${registro.dataFormatada ?? "15/04"}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Cores.azul,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Cores.azul,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.calendar_today, color: Cores.branco, size: 18),
                        ),
                      ],
                    ),
                    const Divider(thickness: 1, height: 24, color: Cores.cinza),

                    BarraIndicador(label: 'Humor', valor: registro.humor.toDouble()),
                    BarraIndicador(label: 'Dor', valor: registro.dor.toDouble(), inverso: true),
                    BarraIndicador(label: 'Apetite', valor: registro.apetite.toDouble()),
                    BarraIndicador(label: 'Mobilidade', valor: registro.mobilidade.toDouble()),

                    const SizedBox(height: 16),

                    const Text(
                      'Observações',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Cores.azul,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (registro.observacoes != null && registro.observacoes!.isNotEmpty)
                          ? registro.observacoes!
                          : 'Sem observações registradas.',
                      style: const TextStyle(color: Cores.cinza, fontSize: 14),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Incidentes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Cores.azul,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (registro.listaIncidentes != null && registro.listaIncidentes!.isNotEmpty)
                      ...registro.listaIncidentes!.map((incidente) => Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: incidente.gravidade == 'Alta' ? Colors.red : Colors.amber,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${incidente.titulo} às ${incidente.hora} - ${incidente.descricao}',
                                    style: TextStyle(
                                      color: incidente.gravidade == 'Alta' ? Colors.red : Cores.preto,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ))
                    else
                      const Text(
                        'Nenhum incidente registrado hoje.',
                        style: TextStyle(color: Cores.cinza, fontSize: 13),
                      ),

                    const SizedBox(height: 20),

                    Center(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Cores.azul,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.edit_note, color: Cores.branco),
                        label: const Text('Editar', style: TextStyle(color: Cores.branco)),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tendência',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Cores.azul,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.trending_down, color: Colors.red, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  registro.tendencia ?? 'Estável',
                                  style: const TextStyle(color: Cores.preto),
                                ),
                              ],
                            ),
                          ],
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Cores.azul,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {},
                          child: const Text('Ver relatório', style: TextStyle(color: Cores.branco)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const Menu(paginaAtual: 3),
    );
  }
}