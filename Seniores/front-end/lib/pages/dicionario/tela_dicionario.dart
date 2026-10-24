import 'package:flutter/material.dart';

class Dicionario extends StatefulWidget {
  const Dicionario({super.key});

  @override
  State<Dicionario> createState() => _DicionarioState();
}

class _DicionarioState extends State<Dicionario> {
  final _busca = TextEditingController();
  String _filtro = '';

  static const _termos = <({String termo, String definicao})>[
    (
      termo: 'Aferição',
      definicao:
          'Medição de um sinal do organismo, como pressão, temperatura ou glicemia.',
    ),
    (
      termo: 'Glicemia',
      definicao: 'Quantidade de glicose presente no sangue.',
    ),
    (
      termo: 'Hipertensão',
      definicao:
          'Condição em que a pressão arterial permanece acima dos valores recomendados.',
    ),
    (
      termo: 'Intercorrência',
      definicao:
          'Evento inesperado que altera o estado de saúde ou a rotina de cuidados.',
    ),
    (
      termo: 'Posologia',
      definicao:
          'Orientação sobre dose, frequência e duração do uso de um medicamento.',
    ),
    (
      termo: 'Pressão arterial',
      definicao: 'Força exercida pelo sangue nas paredes das artérias.',
    ),
    (
      termo: 'Saturação',
      definicao: 'Percentual de oxigênio transportado pelo sangue.',
    ),
    (
      termo: 'Sinal vital',
      definicao: 'Medida usada para acompanhar funções básicas do organismo.',
    ),
  ];

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final consulta = _filtro.toLowerCase();
    final resultados = _termos
        .where((item) =>
            item.termo.toLowerCase().contains(consulta) ||
            item.definicao.toLowerCase().contains(consulta))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Dicionário')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _busca,
            onChanged: (valor) => setState(() => _filtro = valor.trim()),
            decoration: InputDecoration(
              labelText: 'Buscar termo',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _filtro.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpar busca',
                      onPressed: () {
                        _busca.clear();
                        setState(() => _filtro = '');
                      },
                      icon: const Icon(Icons.close),
                    ),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          if (resultados.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('Nenhum termo encontrado.')),
            )
          else
            ...resultados.map(
              (item) => Card(
                child: ExpansionTile(
                  title: Text(
                    item.termo,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(item.definicao),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
