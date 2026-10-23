import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../widgets/custom_botao.dart';
import '../widgets/custom_textField.dart';

class Cuidadores extends StatefulWidget {
  const Cuidadores({super.key});

  @override
  State<Cuidadores> createState() => _CuidadoresState();
}

class _CuidadoresState extends State<Cuidadores> {
  UsuarioVinculado? _cuidador;
  List<UsuarioVinculado> _responsaveis = [];
  String? _cpfPaciente;
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final pacienteId = SessionService.instance.pacienteId;
      final usuario = await ApiService().obterUsuario(
        tipo: SessionService.instance.tipoUsuario!,
        usuarioId: pacienteId,
      );
      final dados = await Future.wait([
        ApiService().obterCuidadorVinculado(pacienteId),
        ApiService().listarResponsaveisVinculados(pacienteId),
      ]);
      if (!mounted) return;
      setState(() {
        _cpfPaciente = usuario['cpf']?.toString();
        _cuidador = dados[0] as UsuarioVinculado?;
        _responsaveis = dados[1] as List<UsuarioVinculado>;
        _carregando = false;
      });
    } on ApiException catch (exception) {
      _mostrarErro(exception.message);
    } on StateError catch (exception) {
      _mostrarErro(exception.message);
    } catch (_) {
      _mostrarErro('Não foi possível carregar os vínculos.');
    }
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    setState(() {
      _carregando = false;
      _erro = mensagem;
    });
  }

  Future<void> _vincular(bool cuidador) async {
    if (_cpfPaciente == null) return;
    final cpf = await showDialog<String>(
      context: context,
      builder: (_) => const _DialogoCpf(),
    );
    if (cpf == null || cpf.trim().isEmpty || !mounted) return;
    try {
      if (cuidador) {
        await ApiService().vincularCuidador(_cpfPaciente!, cpf.trim());
      } else {
        await ApiService().vincularResponsavel(_cpfPaciente!, cpf.trim());
      }
      await _carregar();
      _mostrarMensagem('Vínculo atualizado.');
    } on ApiException catch (exception) {
      _mostrarMensagem(exception.message);
    }
  }

  Future<void> _editar(UsuarioVinculado usuario) async {
    final dados = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _DialogoUsuario(usuario: usuario),
    );
    if (dados == null || !mounted) return;
    try {
      final atualizado = await ApiService().atualizarUsuario(
        tipo: usuario.tipo,
        usuarioId: usuario.id,
        dados: dados,
      );
      final novo = UsuarioVinculado.fromMap(atualizado);
      setState(() {
        if (_cuidador?.id == usuario.id) _cuidador = novo;
        _responsaveis = _responsaveis
            .map((item) => item.id == usuario.id ? novo : item)
            .toList();
      });
    } on ApiException catch (exception) {
      _mostrarMensagem(exception.message);
    }
  }

  Future<void> _desvincular(UsuarioVinculado usuario) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desvincular usuário?'),
        content: Text('${usuario.nome} não ficará mais vinculado ao paciente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Desvincular'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    try {
      if (usuario.tipo == 'cuidador') {
        await ApiService().desvincularCuidador(
          SessionService.instance.pacienteId,
        );
        _cuidador = null;
      } else {
        await ApiService().desvincularResponsavel(
          SessionService.instance.pacienteId,
          usuario.id,
        );
        _responsaveis.removeWhere((item) => item.id == usuario.id);
      }
      if (mounted) setState(() {});
    } on ApiException catch (exception) {
      _mostrarMensagem(exception.message);
    }
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Widget _cardUsuario(UsuarioVinculado usuario) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.person_outline),
        title: Text(usuario.nome),
        subtitle: Text('${usuario.email}\n${usuario.telefone}'),
        isThreeLine: true,
        onTap: () => _editar(usuario),
        trailing: IconButton(
          tooltip: 'Desvincular',
          icon: const Icon(Icons.link_off),
          onPressed: () => _desvincular(usuario),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cuidadores e responsáveis')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
          ? Center(child: Text(_erro!, textAlign: TextAlign.center))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Cuidador',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Vincular cuidador',
                      onPressed: () => _vincular(true),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                if (_cuidador == null)
                  const Text('Nenhum cuidador vinculado.')
                else
                  _cardUsuario(_cuidador!),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Responsáveis',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Vincular responsável',
                      onPressed: () => _vincular(false),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                if (_responsaveis.isEmpty)
                  const Text('Nenhum responsável vinculado.')
                else
                  ..._responsaveis.map(_cardUsuario),
              ],
            ),
    );
  }
}

class _DialogoCpf extends StatefulWidget {
  const _DialogoCpf();

  @override
  State<_DialogoCpf> createState() => _DialogoCpfState();
}

class _DialogoCpfState extends State<_DialogoCpf> {
  final _cpf = TextEditingController();

  @override
  void dispose() {
    _cpf.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Vincular por CPF'),
      content: CampoTexto(hintText: 'CPF', controller: _cpf),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        Botao(
          texto: 'Vincular',
          largura: 100,
          altura: 42,
          fontSize: 14,
          onPressed: () => Navigator.pop(context, _cpf.text),
        ),
      ],
    );
  }
}

class _DialogoUsuario extends StatefulWidget {
  final UsuarioVinculado usuario;

  const _DialogoUsuario({required this.usuario});

  @override
  State<_DialogoUsuario> createState() => _DialogoUsuarioState();
}

class _DialogoUsuarioState extends State<_DialogoUsuario> {
  late final TextEditingController _nome;
  late final TextEditingController _email;
  late final TextEditingController _telefone;

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController(text: widget.usuario.nome);
    _email = TextEditingController(text: widget.usuario.email);
    _telefone = TextEditingController(text: widget.usuario.telefone);
  }

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _telefone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar vínculo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CampoTexto(hintText: 'Nome', controller: _nome),
          const SizedBox(height: 10),
          CampoTexto(hintText: 'E-mail', controller: _email),
          const SizedBox(height: 10),
          CampoTexto(hintText: 'Telefone', controller: _telefone),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, {
            'nome': _nome.text.trim(),
            'email': _email.text.trim(),
            'telefone': _telefone.text.trim(),
          }),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
