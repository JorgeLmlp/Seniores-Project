import 'package:flutter/material.dart';
import '../../widgets/custom_menu.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_textos.dart';
import '../../widgets/custom_textField.dart';
import '../../utils/cores.dart';
import '../../services/api_service.dart';

class Dicionario extends StatefulWidget {
  const Dicionario({super.key});

  @override
  State<Dicionario> createState() => _DicionarioScreenState();
}

class _DicionarioScreenState extends State<Dicionario> {
  final TextEditingController _buscaController = TextEditingController();
  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> _termosDestaque = [];
  List<Map<String, dynamic>> _categorias = [];
  List<Map<String, dynamic>> _recentes = [];
  bool _carregando = true;

  final List<Map<String, dynamic>> _termosDestaquePadrao = [
    //representacao dos termos em destaque
    {
      'titulo': 'Hipertensao',
      'descricao': 'Pressao alta nas arterias',
      'icone': Icons.favorite,
      'cor': Cores.azul,
    },
    {
      'titulo': 'Diabetes',
      'descricao': 'Doenca que afeta a taxa de acucar no sangue',
      'icone': Icons.water_drop,
      'cor': Cores.verde,
    },
    {
      'titulo': 'Asma',
      'descricao': 'Inflamacao das vias aereas que causam falta de ar',
      'icone': Icons.air,
      'cor': Cores.amarelo,
    },
    {
      'titulo': 'Hipertensao',
      'descricao': 'Pressao alta nas arterias',
      'icone': Icons.favorite,
      'cor': Cores.azul,
    },
    {
      'titulo': 'Hipertensao',
      'descricao': 'Doenca que afeta a taxa de acucar no sangue',
      'icone': Icons.water_drop,
      'cor': Cores.verde,
    },
    {
      'titulo': 'Asma',
      'descricao': 'Inflamacao das vias aereas que causam falta de ar',
      'icone': Icons.air,
      'cor': Cores.amarelo,
    },
  ];

  final List<Map<String, dynamic>> _categoriasPadrao = [
    {
      'titulo': 'Doencas e condicoes',
      'subtitulo': 'Entenda doencas e condicoes medicas',
      'icone': Icons.favorite,
      'cor': Cores.azul,
    },
    {
      'titulo': 'Exames e procedimentos',
      'subtitulo': 'Conheca exames, testes e procedimentos',
      'icone': Icons.science,
      'cor': Cores.verde,
    },
    {
      'titulo': 'Medicamentos',
      'subtitulo': 'Saiba mais sobre medicamentos',
      'icone': Icons.medication,
      'cor': Cores.amarelo,
    },
    {
      'titulo': 'Anatomia do corpo',
      'subtitulo': 'Entenda doencas e condicoes medicas',
      'icone': Icons.favorite,
      'cor': Cores.vermelho,
    },
    {
      'titulo': 'Especialidades medicas',
      'subtitulo': 'Areas de atuacao na medicina',
      'icone': Icons.medical_services,
      'cor': Cores.cinza,
    },
    {
      'titulo': 'Sintomas e sinais',
      'subtitulo': 'Sintomas e sinais comuns',
      'icone': Icons.chat_bubble_outline,
      'cor': Cores.cinza,
    },
  ];

  final List<Map<String, dynamic>> _historico = [
    //representacao do historico
    {
      'titulo': 'Glicemia',
      'descricao': 'Nivel de glicose presente no sangue',
    },
    {
      'titulo': 'Inflamacao',
      'descricao': 'Resposta de defesa do corpo a infecoes',
    },
    {
      'titulo': 'Antibiotico',
      'descricao': 'Medicamento usado para tratar infecoes bacterianas',
    },
  ];

  @override
  void initState() {
    super.initState();
    _carregarDadosDicionario();
  }

  Future<void> _carregarDadosDicionario() async {
    try {
      final destaquesRes = await _apiService.listarRegistros('dicionario/destaques');
      final categoriasRes = await _apiService.listarRegistros('dicionario/categorias');
      final recentesRes = await _apiService.listarRegistros('dicionario/recentes');

      if (mounted) {
        setState(() {
          _termosDestaque = destaquesRes.isNotEmpty ? destaquesRes : _termosDestaquePadrao;
          _categorias = categoriasRes.isNotEmpty ? categoriasRes : _categoriasPadrao;
          _recentes = recentesRes.isNotEmpty ? recentesRes : _historico;
          _carregando = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _termosDestaque = _termosDestaquePadrao;
          _categorias = _categoriasPadrao;
          _recentes = _historico;
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new, size: 24, color: Cores.preto),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const AppText(
                              texto: 'Dicionario',
                              estilo: AppText.titulo,
                              tamanho: 24,
                              peso: FontWeight.bold,
                            ),
                          ],
                        ),
                        const Icon(Icons.menu_book, color: Cores.azul, size: 28),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Encontre o significado de termos medicos de forma simples e confiavel',
                      style: TextStyle(color: Cores.cinza, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    CampoTexto(
                      hintText: 'Buscar no dicionario...',
                      controller: _buscaController,
                      prefixIcon: const Icon(Icons.search, color: Cores.cinza),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Termos em destaque',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Cores.azul,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 145,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _termosDestaque.length,
                        itemBuilder: (context, index) {
                          final item = _termosDestaque[index];
                          final IconData icone = item['icone'] is IconData ? item['icone'] : Icons.favorite;
                          final Color cor = item['cor'] is Color ? item['cor'] : Cores.azul;

                          return Container(
                            width: 155,
                            margin: const EdgeInsets.only(right: 12),
                            child: CardPadrao(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(icone, color: cor, size: 22),
                                    const SizedBox(height: 4),
                                    Text(
                                      item['titulo'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Cores.preto,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item['descricao'] ?? '',
                                      style: const TextStyle(
                                        color: Cores.cinza,
                                        fontSize: 10,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Navegar por categoria',
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
                          final IconData icone = cat['icone'] is IconData ? cat['icone'] : Icons.favorite;
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
                    const Text(
                      'Recentes',
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
                        itemCount: _recentes.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.black12),
                        itemBuilder: (context, index) {
                          final rec = _recentes[index];
                          return ListTile(
                            leading: const Icon(Icons.access_time, color: Cores.azul),
                            title: Text(
                              rec['titulo'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Cores.preto,
                              ),
                            ),
                            subtitle: Text(
                              rec['descricao'] ?? '',
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