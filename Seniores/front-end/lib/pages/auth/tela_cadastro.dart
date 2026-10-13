import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/custom_textos.dart';
import '../../widgets/custom_textField.dart';
import '../../widgets/custom_botao.dart';
import '../../utils/mascaras.dart';
import '../../utils/cores.dart';
import '../../services/api_service.dart';
import 'tela_login.dart';

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
    super.dispose();
  }

  Future<void> cadastrar() async {
    final nome = nomeController.text.trim();
    final email = emailController.text.trim();
    final senha = senhaController.text;
    final cpf = cpfController.text.trim();
    final telefone = telefoneController.text.trim();

    if (nome.isEmpty ||
        !validarEmail(email) ||
        senha.length < 6 ||
        cpf.isEmpty ||
        telefone.isEmpty ||
        tipoUsuario == null ||
        senha != confirmarSenhaController.text ||
        !concordouTermos) {
      setState(() =>
          mensagemErro = 'Revise todos os campos e aceite os Termos de Uso.');
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
        tipo: tipoUsuario == 'Responsável'
            ? 'responsavel'
            : tipoUsuario!.toLowerCase(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastro realizado com sucesso!')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Login()),
      );
    } on ApiException catch (erro) {
      if (mounted) setState(() => mensagemErro = erro.message);
    } finally {
      if (mounted) setState(() => enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.fundoTela,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              const AppText(
                texto: 'Seniores',
                tamanho: 70,
                peso: FontWeight.bold,
                cor: Cores.azul,
                estilo: AppText.titulo,
              ),
              const AppText(
                texto: 'Crie sua conta!',
                tamanho: 28,
                peso: FontWeight.bold,
                cor: Cores.azul,
                estilo: AppText.subtitulo,
              ),
              const SizedBox(height: 10),
              const AppText(
                texto: 'Preencha os dados abaixo para se cadastrar.',
                tamanho: 16,
                cor: Cores.cinza,
                estilo: AppText.corpo,
              ),
              const SizedBox(height: 40),
              CampoTexto(
                controller: nomeController,
                hintText: 'Nome completo',
                keyboardType: TextInputType.text,
                prefixIcon: const Icon(
                  Icons.person,
                  color: Cores.azul,
                ),
              ),
              const SizedBox(height: 20),
              CampoTexto(
                controller: emailController,
                hintText: 'E-mail',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(
                  Icons.email,
                  color: Cores.azul,
                ),
              ),
              const SizedBox(height: 20),
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
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: CampoTexto(
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
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 7,
                    child: CampoDropdown(
                      hintText: "Tipo",
                      valor: tipoUsuario,
                      prefixIcon:
                          const Icon(Icons.person_outline, color: Cores.azul),
                      itens: tiposUsuario,
                      onChanged: (valor) {
                        setState(() {
                          tipoUsuario = valor;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              CampoTexto(
                controller: senhaController,
                hintText: 'Senha',
                senha: true,
                prefixIcon: const Icon(
                  Icons.lock,
                  color: Cores.azul,
                ),
              ),
              const SizedBox(height: 20),
              CampoTexto(
                controller: confirmarSenhaController,
                hintText: 'Confirmar senha',
                senha: true,
                prefixIcon: const Icon(
                  Icons.lock,
                  color: Cores.azul,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: concordouTermos,
                    activeColor: Cores.azul,
                    onChanged: (value) {
                      setState(() {
                        concordouTermos = value!;
                      });
                    },
                  ),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: Cores.cinza,
                        ),
                        children: [
                          TextSpan(text: 'Eu concordo com os '),
                          TextSpan(
                            text: 'Termos de Uso',
                            style: TextStyle(
                              color: Cores.azul,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(text: ' e '),
                          TextSpan(
                            text: 'Política de Privacidade.',
                            style: TextStyle(
                              color: Cores.azul,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (mensagemErro.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Text(
                    mensagemErro,
                    style: const TextStyle(
                      color: Cores.vermelho,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Botao(
                texto: 'Cadastrar',
                onPressed: enviando ? () {} : cadastrar,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      thickness: 1,
                      color: Cores.cinza.withOpacity(0.3),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'ou',
                      style: TextStyle(
                        color: Cores.cinza,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      thickness: 1,
                      color: Cores.cinza.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Botao(
                texto: 'Já tem uma conta? Entrar',
                backgroundColor: Colors.white,
                textColor: Cores.azul,
                borderColor: Cores.azul,
                borderWidth: 1.5,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Login(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
