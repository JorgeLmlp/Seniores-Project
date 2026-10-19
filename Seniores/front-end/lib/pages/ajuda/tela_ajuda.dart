import 'package:flutter/material.dart';
import '../../widgets/custom_menu.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_textos.dart';
import '../../widgets/custom_textField.dart';
import '../../widgets/custom_botao.dart';
import '../../utils/cores.dart';
import '../../services/api_service.dart';

class Ajuda extends StatefulWidget {
  const Ajuda({super.key});

  @override
  State<Ajuda> createState() => _AjudaScreenState();
}

class _AjudaScreenState extends State<Ajuda> {
  final TextEditingController _buscaController = TextEditingController();
  final ApiService _apiService = ApiService();

  bool _carregando = true;

  final List<String> _perguntasFrequentes = [
    'Como adicionar um medicamento?',
    'Como agendar uma consulta?',
    'Como acompanhar meus exames?',
    'Como funcionam os lembretes?',
    'Como convidar um cuidador?',
  ];

  final List<Map<String, dynamic>> _categorias = [
    {
      'titulo': 'Medicamentos',
      'subtitulo': 'Duvidas sobre cadastros, lembretes e uso',
      'icone': Icons.medication,
      'cor': Cores.azul,
    },
    {
      'titulo': 'Gastos',
      'subtitulo': 'Controles de despesas e relatorios',
      'icone': Icons.account_balance_wallet,
      'cor': Cores.azul,
    },
    {
      'titulo': 'Consultas e exames',
      'subtitulo': 'Agendamentos, resultados e preparo',
      'icone': Icons.calendar_today,
      'cor': Cores.azul,
    },
    {
      'titulo': 'Cuidadores',
      'subtitulo': 'Convites, permissoes e acesso',
      'icone': Icons.people,
      'cor': Cores.azul,
    },
  ];

  final List<Map<String, dynamic>> _outrosCanais = [
    {
      'titulo': 'E-mail',
      'subtitulo': 'suporte@seniores.com.br',
      'icone': Icons.email,
      'cor': Cores.azul,
    },
  ];

  @override
  void initState() {
    super.initState();
    _carregarDadosAjuda();
  }

  Future<void> _carregarDadosAjuda() async {
    try {
      final perguntasRes = await _apiService.listarRegistros('ajuda/perguntas');
      final categoriasRes = await _apiService.listarRegistros('ajuda/categorias');
      final canaisRes = await _apiService.listarRegistros('ajuda/canais');

      if (mounted) {
        setState(() {
          if (perguntasRes.isNotEmpty) {
            _perguntasFrequentes.clear();
            _perguntasFrequentes.addAll(perguntasRes.map((e) => e['titulo'].toString()).toList());
          }
          if (categoriasRes.isNotEmpty) {
            _categorias.clear();
            _categorias.addAll(categoriasRes);
          }
          if (canaisRes.isNotEmpty) {
            _outrosCanais.clear();
            _outrosCanais.addAll(canaisRes);
          }
          _carregando = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.fundoTela,
      body: SafeArea(
        child: _carregando
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, size: 24, color: Cores.preto),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const AppText(
                          texto: 'Ajuda',
                          estilo: AppText.titulo,
                          tamanho: 24,
                          peso: FontWeight.bold,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Como podemos te ajudar?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Cores.preto,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Encontre respostas rapidas para suas duvidas ou entre em contato com a nossa equipe.',
                      style: TextStyle(color: Cores.cinza, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    CampoTexto(
                      hintText: 'Buscar ajuda...',
                      controller: _buscaController,
                      prefixIcon: const Icon(Icons.search, color: Cores.cinza),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Perguntas frequentes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Cores.azul,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: const Text(
                            'Ver todas >',
                            style: TextStyle(
                              color: Cores.azul,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _perguntasFrequentes.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: CardPadrao(
                            child: ListTile(
                              title: Text(
                                _perguntasFrequentes[index],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Cores.azul,
                                ),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Cores.azul),
                              onTap: () {},
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Categorias',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Cores.azul,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CardPadrao(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _categorias.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.black12),
                        itemBuilder: (context, index) {
                          final cat = _categorias[index];
                          final IconData icone = cat['icone'] is IconData ? cat['icone'] : Icons.medication;
                          final Color cor = cat['cor'] is Color ? cat['cor'] : Cores.azul;

                          return ListTile(
                            leading: Icon(icone, color: cor),
                            title: Text(
                              cat['titulo'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Cores.preto,
                              ),
                            ),
                            subtitle: Text(
                              cat['subtitulo'] ?? '',
                              style: const TextStyle(color: Cores.cinza, fontSize: 11),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Cores.azul),
                            onTap: () {},
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    CardPadrao(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Cores.azul.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.headset_mic, color: Cores.azul, size: 32),
                            ),
                            const SizedBox(height: 12, width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Ainda precisa de ajuda?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Cores.azul,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Fale com nossa equipe',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Cores.preto,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Nossa equipe esta pronta para te ajudar sempre que precisar.',
                                    style: TextStyle(color: Cores.cinza, fontSize: 11),
                                  ),
                                  const SizedBox(height: 16),
                                  Botao(
                                    texto: 'Falar com o suporte',
                                    largura: double.infinity,
                                    altura: 40,
                                    backgroundColor: Cores.azul,
                                    textColor: Cores.branco,
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Outros canais',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Cores.azul,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CardPadrao(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _outrosCanais.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.black12),
                        itemBuilder: (context, index) {
                          final canal = _outrosCanais[index];
                          final IconData icone = canal['icone'] is IconData ? canal['icone'] : Icons.email;
                          final Color cor = canal['cor'] is Color ? canal['cor'] : Cores.azul;

                          return ListTile(
                            leading: Icon(icone, color: cor),
                            title: Text(
                              canal['titulo'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Cores.preto,
                              ),
                            ),
                            subtitle: Text(
                              canal['subtitulo'] ?? '',
                              style: const TextStyle(color: Cores.cinza, fontSize: 11),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Cores.azul),
                            onTap: () {},
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: const Menu(paginaAtual: 0),
    );
  }
}