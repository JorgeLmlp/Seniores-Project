import 'package:flutter/material.dart';
import '../../widgets/custom_menu.dart';
import '../../widgets/custom_textos.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_botao.dart';
import '../../utils/cores.dart';
import '../../models/cuidador.dart';
import 'tela_listaCuidadores.dart';
import '../cuidadores/tela_detalhesCuidador.dart';
import '../../services/api_service.dart';
import '../../models/recurso_cuidado.dart';
import '../cuidados/tela_registros_cuidado.dart';
import 'package:intl/intl.dart';

class Cuidadores extends StatefulWidget {
  const Cuidadores({super.key});

  @override
  State<Cuidadores> createState() => _TelaCuidadosState();
}

class _TelaCuidadosState extends State<Cuidadores> {
  int diaSelecionado = 0;
  final datas = List.generate(7, (i) => DateTime.now().add(Duration(days: i)));
  List<Cuidador> cuidadores = [];
  bool carregando = true;
  String? erro;

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> carregar() async {
    setState(() {
      carregando = true;
      erro = null;
    });
    try {
      final registros = await ApiService().listarRegistros('cuidadores');
      if (mounted) {
        setState(() => cuidadores = registros
            .map((r) => Cuidador.fromJson(r['dados'] as Map<String, dynamic>))
            .toList());
      }
    } catch (e) {
      if (mounted) {
        setState(() => erro = e is ApiException
            ? e.message
            : 'Não foi possível carregar a agenda.');
      }
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dias = datas
        .map((d) =>
            {'dia': '${d.day}', 'mes': DateFormat('MMM', 'pt_BR').format(d)})
        .toList();
    final dia = datas[diaSelecionado].weekday % 7;
    final doDia = cuidadores
        .where((c) => c.frequencia.length > dia && c.frequencia[dia])
        .toList();
    doDia.sort((a, b) => a.horaInicio.compareTo(b.horaInicio));
    final agora = DateFormat('HH:mm').format(DateTime.now());
    final ativos = doDia.where((c) =>
        diaSelecionado == 0 &&
        c.horaInicio.compareTo(agora) <= 0 &&
        c.horaFim.compareTo(agora) > 0);
    final cuidadorAgora = ativos.isEmpty ? null : ativos.first;
    final proximosCuidadores = doDia.where((c) => c != cuidadorAgora).toList();
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 20),
                    onPressed: () => Navigator.canPop(context)
                        ? Navigator.pop(context)
                        : null,
                  ),
                  Expanded(
                      child: AppText(
                          texto: 'Cuidadores',
                          estilo: AppText.titulo,
                          tamanho: 24)),
                ],
              ),
            ),
            Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(dias.length, (index) {
                    final selecionado = index == diaSelecionado;
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                      child: GestureDetector(
                        onTap: () => setState(() => diaSelecionado = index),
                        child: Container(
                          width: 55,
                          height: 75,
                          decoration: BoxDecoration(
                            color: selecionado ? Cores.azul : Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                                color: selecionado
                                    ? Cores.azul
                                    : Cores.cinza.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dias[index]['dia']!,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      selecionado ? Colors.white : Cores.preto,
                                ),
                              ),
                              Text(
                                dias[index]['mes']!,
                                style: TextStyle(
                                  fontSize: 10,
                                  color:
                                      selecionado ? Colors.white : Cores.cinza,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                children: [
                  if (carregando) const LinearProgressIndicator(),
                  if (erro != null)
                    TextButton(
                        onPressed: carregar,
                        child: Text('$erro Tentar novamente')),
                  if (!carregando && erro == null && doDia.isEmpty)
                    const CardPadrao(
                        child:
                            Text('Nenhum cuidador cadastrado para este dia.')),
                  if (cuidadorAgora != null)
                    GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  DetalheCuidador(cuidador: cuidadorAgora))),
                      child: CardPadrao(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: Cores.cinza.withValues(alpha: 0.2),
                                  child: Icon(Icons.person,
                                      color: Cores.cinza, size: 26),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AppText(
                                          texto: cuidadorAgora.nome,
                                          estilo: AppText.corpo,
                                          peso: FontWeight.bold,
                                          tamanho: 16),
                                      AppText(
                                          texto: cuidadorAgora.funcao,
                                          estilo: AppText.corpo,
                                          tamanho: 12,
                                          cor: Cores.cinza),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Cores.azul,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text('Agora',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.0),
                              child: Divider(height: 1),
                            ),
                            AppText(
                              texto: cuidadorAgora.observacoes.isNotEmpty
                                  ? cuidadorAgora.observacoes
                                  : 'Sem observações',
                              estilo: AppText.corpo,
                              tamanho: 11,
                              cor: Cores.cinza,
                            ),
                            SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                    child: AppText(
                                        texto:
                                            '${cuidadorAgora.horaInicio} ás ${cuidadorAgora.horaFim}',
                                        estilo: AppText.corpo,
                                        tamanho: 13,
                                        peso: FontWeight.w600)),
                                SizedBox(
                                  height: 32,
                                  width: 100,
                                  child: Botao(
                                    texto: 'Informações',
                                    fontSize: 11,
                                    borderRadius: 16,
                                    backgroundColor: Colors.white,
                                    textColor: Cores.azul,
                                    borderColor: Cores.azul,
                                    borderWidth: 1,
                                    onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => DetalheCuidador(
                                                cuidador: cuidadorAgora))),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(height: 16),
                  AppText(
                      texto: 'Cuidadores do dia',
                      estilo: AppText.subtitulo,
                      tamanho: 16,
                      cor: Cores.azul),
                  SizedBox(height: 8),
                  ...proximosCuidadores.map((c) => Container(
                        margin: EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      DetalheCuidador(cuidador: c))),
                          child: CardPadrao(
                            padding: EdgeInsets.all(12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Cores.cinza.withValues(alpha: 0.2),
                                  child: Icon(Icons.person,
                                      color: Cores.cinza, size: 24),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AppText(
                                          texto: c.nome,
                                          estilo: AppText.corpo,
                                          peso: FontWeight.bold,
                                          tamanho: 15),
                                      AppText(
                                          texto: c.funcao,
                                          estilo: AppText.corpo,
                                          tamanho: 12,
                                          cor: Cores.cinza),
                                      SizedBox(height: 4),
                                      AppText(
                                        texto: c.observacoes.isNotEmpty
                                            ? c.observacoes
                                            : 'Sem observações',
                                        estilo: AppText.corpo,
                                        tamanho: 11,
                                        cor: Cores.cinza,
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    AppText(
                                        texto:
                                            '${c.horaInicio} ás ${c.horaFim}',
                                        estilo: AppText.corpo,
                                        tamanho: 12,
                                        peso: FontWeight.bold),
                                    SizedBox(height: 4),
                                    SizedBox(
                                      height: 28,
                                      width: 90,
                                      child: Botao(
                                        texto: 'Informações',
                                        fontSize: 10,
                                        borderRadius: 14,
                                        backgroundColor: Colors.white,
                                        textColor: Cores.azul,
                                        borderColor: Cores.azul,
                                        borderWidth: 1,
                                        onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) => DetalheCuidador(
                                                    cuidador: c))),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      )),
                  SizedBox(height: 8),
                  SizedBox(height: 12),
                  Botao(
                    texto: 'Ver todos cuidadores',
                    fontSize: 14,
                    borderRadius: 10,
                    onPressed: () async {
                      await Navigator.push(context,
                          MaterialPageRoute(builder: (_) => ListaCuidadores()));
                      if (mounted) await carregar();
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => RegistrosCuidado(
                                  recurso: recursosCuidado.firstWhere(
                                      (r) => r.rota == 'turnos-cuidadores')))),
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: const Text('Gerenciar turnos')),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Menu(paginaAtual: 2),
    );
  }
}
