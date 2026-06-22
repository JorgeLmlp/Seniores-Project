import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  final List<Map<String, dynamic>> listaDeRemedios = [
    {
      "nome": "Dipirona 500mg",
      "detalhes": "1 comprimido - 12:00",
      "status": "Atrasado",
      "corBolinha": Colors.red,
      "corBotao": Colors.red[400],
    },
    {
      "nome": "Paracetamol 750mg",
      "detalhes": "1 comprimido - 14:00",
      "status": "Concluir",
      "corBolinha": Colors.amber,
      "corBotao": Colors.amber[400],
    },
    {
      "nome": "Losartana 50mg",
      "detalhes": "1 comprimido - 18:00",
      "status": "Concluir",
      "corBolinha": Colors.blue,
      "corBotao": Colors.blue[600],
    },
  ];

  Widget _construirLinhaMedicamento({
    required String nome,
    required String detalhes,
    required String status,
    required Color corBolinha,
    required Color corBotao,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.circle,size: 10,color: corBolinha,),
              const SizedBox(width: 12.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    detalhes,
                    style: const TextStyle(color: Colors.grey, fontSize: 13.0),
                  ),
                ],
              ),
            ],
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: corBotao,
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Text(
              status,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              "Olá, nome!",
              style: GoogleFonts.poppins(
                fontSize: 24.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 16.0),
            Image.asset("assets/images/perfil.png", height: 40, width: 39),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            iconSize: 32.0,
            onPressed: () {
              //TODO
            },
          ),
          const SizedBox(width: 20.0),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      "Próximos medicamentos",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),

                  ...listaDeRemedios.map((remedio) {
                    return Column(
                      children: [
                        _construirLinhaMedicamento(
                          nome: remedio["nome"], 
                          detalhes: remedio["detalhes"], 
                          status: remedio["status"], 
                          corBolinha: remedio["corBolinha"], 
                          corBotao: remedio["corBotao"]
                        ),
                        const Divider(height: 1, color: Colors.black12,)
                      ],
                    );
                  }).toList(),

                  const SizedBox(height: 8.0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
