import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/custom_textos.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_botao.dart';
import '../../utils/mascaras.dart';
import '../../utils/cores.dart';
import '../../services/api_service.dart';
import '../../widgets/app_feedback.dart';
import 'tela_login.dart';
import 'tela_documentos_legais.dart';

class Cadastro extends StatefulWidget {
  const Cadastro({super.key});

  @override
  State<Cadastro> createState() => _CadastroState();
}

class _CadastroState extends State<Cadastro> {
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();
  final TextEditingController confirmarSenhaController =
      TextEditingController();
  final TextEditingController cpfController = TextEditingController();
  final TextEditingController telefoneController = TextEditingController();
  final TextEditingController idadeController = TextEditingController();
  final TextEditingController preferenciasController = TextEditingController();
  String? tipoSanguineo;

  String mensagemErro = '';
  String? tipoUsuario;
  bool concordouTermos = false;
  bool enviando = false;
  final ApiService apiService = ApiService();

  final List<String> tiposUsuario = [
    "Paciente",
    "Cuidador",
    "Responsável",
  ];

  bool validarEmail(String email) {
    final regex = RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
    return regex.hasMatch(email);
  }

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    senhaController.dispose();
    confirmarSenhaController.dispose();
    cpfController.dispose();
    telefoneController.dispose();
    idadeController.dispose();
    preferenciasController.dispose();
    super.dispose();
  }

  Future<void> cadastrar() async {
    final nome = nomeController.text.trim();
    final email = emailController.text.trim();
    final senha = senhaController.text;
    final cpf = cpfController.text.trim();
    final telefone = telefoneController.text.trim();

    final cpfNumeros = cpf.replaceAll(RegExp(r'\D'), '');
    final telefoneNumeros = telefone.replaceAll(RegExp(r'\D'), '');
    final idade = idadeController.text.trim().isEmpty
        ? null : int.tryParse(idadeController.text.trim());
    final erroValidacao = nome.isEmpty
        ? 'Informe seu nome completo.'
        : email.isEmpty
            ? 'Informe seu e-mail.'
            : !validarEmail(email)
                ? 'Digite um e-mail válido, como nome@exemplo.com.'
                : cpfNumeros.length != 11
                    ? 'O CPF precisa ter 11 dígitos.'
                    : telefoneNumeros.length < 10 || telefoneNumeros.length > 11
                        ? 'Informe um telefone com DDD válido.'
                        : tipoUsuario == null
                            ? 'Selecione o tipo da sua conta.'
                            : senha.length < 6
                                ? 'A senha precisa ter pelo menos 6 caracteres.'
                                : senha != confirmarSenhaController.text
                                    ? 'As senhas digitadas não são iguais.'
                                    : !concordouTermos
                                        ? 'Aceite os Termos de Uso e a Política de Privacidade.'
                                        : null;
    if (erroValidacao == null && tipoUsuario == 'Paciente' &&
        idadeController.text.trim().isNotEmpty &&
        (idade == null || idade < 0 || idade > 130)) {
      setState(() => mensagemErro = 'A idade deve estar entre 0 e 130 anos.');
      mostrarFeedback(context, mensagem: mensagemErro, tipo: TipoFeedback.erro,
          titulo: 'Confira o cadastro');
      return;
    }
    if (erroValidacao != null) {
      setState(() => mensagemErro = erroValidacao);
      mostrarFeedback(
        context,
        mensagem: erroValidacao,
        tipo: TipoFeedback.erro,
        titulo: 'Confira o cadastro',
      );
      return;
    }

    setState(() {
      mensagemErro = '';
      enviando = true;
    });

    try {
      await apiService.cadastrarUsuario(
        nome: nome,
        email: email,
        senha: senha,
        telefone: telefone,
        cpf: cpf,
        idade: tipoUsuario == 'Paciente' ? idade : null,
        tipoSanguineo: tipoUsuario == 'Paciente' ? tipoSanguineo : null,
        preferencias: tipoUsuario == 'Paciente' && preferenciasController.text.trim().isNotEmpty
            ? {'observacoes': preferenciasController.text.trim()} : null,
        tipo: tipoUsuario == 'Responsável'
            ? 'responsavel'
            : tipoUsuario!.toLowerCase(),
      );

      if (!mounted) return;
      mostrarFeedback(
        context,
        mensagem: 'Entre com seu e-mail e senha para continuar.',
        tipo: TipoFeedback.sucesso,
        titulo: 'Conta criada com sucesso!',
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Login()),
      );
    } on ApiException catch (erro) {
      if (mounted) {
        setState(() => mensagemErro = erro.message);
        mostrarFeedback(
          context,
          mensagem: erro.message,
          tipo: TipoFeedback.erro,
          titulo: 'Não foi possível criar a conta',
        );
      }
    } finally {
      if (mounted) setState(() => enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) {
            final compacto = viewport.maxWidth < 380;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  compacto ? 18 : 30, 24, compacto ? 18 : 30, 36),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      AppText(
                        texto: 'Seniores',
                        tamanho: compacto ? 52 : 64,
                        peso: FontWeight.bold,
                        cor: Cores.azul,
                        estilo: AppText.titulo,
                      ),
                      AppText(
                        texto: 'Crie sua conta!',
                        tamanho: compacto ? 24 : 28,
                        peso: FontWeight.bold,
                        cor: Cores.azul,
                        estilo: AppText.subtitulo,
                      ),
                      const SizedBox(height: 8),
                      AppText(
                        texto: 'Preencha os dados abaixo para se cadastrar.',
                        tamanho: 16,
                        cor: Cores.cinza,
                        estilo: AppText.corpo,
                      ),
                      const SizedBox(height: 30),
                      CampoTexto(
                        controller: nomeController,
                        hintText: 'Nome completo',
                        keyboardType: TextInputType.name,
                        prefixIcon: const Icon(Icons.person, color: Cores.azul),
                      ),
                      const SizedBox(height: 16),
                      CampoTexto(
                        controller: emailController,
                        hintText: 'E-mail',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email, color: Cores.azul),
                      ),
                      const SizedBox(height: 16),
                      CampoTexto(
                        controller: cpfController,
                        hintText: 'CPF',
                        keyboardType: TextInputType.number,
                        prefixIcon: const Icon(
                          Icons.badge_outlined,
                          color: Cores.azul,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          Cpf(),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CampoTexto(
                        controller: telefoneController,
                        hintText: 'Telefone',
                        keyboardType: TextInputType.phone,
                        prefixIcon: const Icon(
                          Icons.phone_outlined,
                          color: Cores.azul,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          TelefoneInputFormatter(),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CampoDropdown(
                        key: const ValueKey('tipo-usuario-dropdown'),
                        hintText: 'Selecione o tipo de usuário',
                        valor: tipoUsuario,
                        prefixIcon: const Icon(
                          Icons.manage_accounts_outlined,
                          color: Cores.azul,
                        ),
                        itens: tiposUsuario,
                        onChanged: (valor) =>
                            setState(() => tipoUsuario = valor),
                      ),
                      if (tipoUsuario == 'Paciente') ...[
                        const SizedBox(height: 16),
                        TextField(controller: idadeController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(labelText: 'Idade (opcional)',
                                border: OutlineInputBorder())),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(initialValue: tipoSanguineo,
                            decoration: const InputDecoration(labelText: 'Tipo sanguíneo (opcional)',
                                border: OutlineInputBorder()),
                            items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                                .map((tipo) => DropdownMenuItem(value: tipo, child: Text(tipo))).toList(),
                            onChanged: (novo) => setState(() => tipoSanguineo = novo)),
                        const SizedBox(height: 16),
                        TextField(controller: preferenciasController, maxLines: 2,
                            decoration: const InputDecoration(
                                labelText: 'Preferências e observações (opcional)',
                                border: OutlineInputBorder())),
                      ],
                      const SizedBox(height: 16),
                      CampoTexto(
                        controller: senhaController,
                        hintText: 'Senha',
                        senha: true,
                        prefixIcon: const Icon(Icons.lock, color: Cores.azul),
                      ),
                      const SizedBox(height: 16),
                      CampoTexto(
                        controller: confirmarSenhaController,
                        hintText: 'Confirmar senha',
                        senha: true,
                        prefixIcon: const Icon(Icons.lock, color: Cores.azul),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: concordouTermos,
                            activeColor: Cores.azul,
                            onChanged: (value) => setState(
                              () => concordouTermos = value ?? false,
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 11),
                              child: Wrap(crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 3,
                                children: [
                                  const Text('Eu concordo com os', style: TextStyle(fontSize: 13)),
                                  TextButton(onPressed: () => Navigator.push(context,
                                      MaterialPageRoute(builder: (_) => const DocumentoLegal(privacidade: false))),
                                      child: const Text('Termos de Uso')),
                                  const Text('e a', style: TextStyle(fontSize: 13)),
                                  TextButton(onPressed: () => Navigator.push(context,
                                      MaterialPageRoute(builder: (_) => const DocumentoLegal(privacidade: true))),
                                      child: const Text('Política de Privacidade')),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: mensagemErro.isEmpty
                            ? const SizedBox.shrink()
                            : Padding(
                                key: ValueKey(mensagemErro),
                                padding: const EdgeInsets.only(bottom: 16),
                                child: AvisoInline(mensagem: mensagemErro),
                              ),
                      ),
                      Botao(
                        texto: enviando ? 'Criando conta...' : 'Cadastrar',
                        onPressed: enviando ? () {} : cadastrar,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              thickness: 1,
                              color:
                                  Theme.of(context).colorScheme.outlineVariant,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text('ou', style: TextStyle(fontSize: 12)),
                          ),
                          Expanded(
                            child: Divider(
                              thickness: 1,
                              color:
                                  Theme.of(context).colorScheme.outlineVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Botao(
                        texto: 'Já tem uma conta? Entrar',
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        textColor: Cores.azul,
                        borderColor: Cores.azul,
                        borderWidth: 1.5,
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const Login()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
