import 'package:flutter/material.dart';
import '../../widgets/custom_textos.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_botao.dart';
import '../../utils/cores.dart';
import 'tela_cadastro.dart';
import 'tela_recuperar_senha.dart';
import '../../services/api_service.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();

  String mensagemErro = '';
  bool lembrarDados = true;
  bool enviando = false;
  final ApiService apiService = ApiService();

  bool validarEmail(String email) {
    final regex = RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
    return regex.hasMatch(email);
  }

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  Future<void> fazerLogin() async {
    String email = emailController.text.trim();
    String senha = senhaController.text;

    if (email.isEmpty) {
      setState(() {
        mensagemErro = 'Digite seu e-mail.';
      });
    } else if (!validarEmail(email)) {
      setState(() {
        mensagemErro = 'Digite um e-mail válido.';
      });
    } else if (senha.isEmpty) {
      setState(() {
        mensagemErro = 'Digite sua senha.';
      });
    } else if (senha.length < 6) {
      setState(() {
        mensagemErro = 'A senha deve possuir pelo menos 6 caracteres.';
      });
    } else {
      setState(() {
        mensagemErro = '';
        enviando = true;
      });
      try {
        await apiService.login(
          email: email,
          senha: senha,
          manterConectado: lembrarDados,
        );
      } on ApiException catch (erro) {
        if (mounted) setState(() => mensagemErro = erro.message);
      } finally {
        if (mounted) setState(() => enviando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Seniores',
                        maxLines: 1,
                        softWrap: false,
                        style: AppText.titulo.copyWith(
                          fontSize: 56,
                          color: Cores.azul,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  AppText(
                    texto: 'Bem-vindo de volta!',
                    tamanho: 28,
                    peso: FontWeight.bold,
                    cor: Cores.azul,
                    estilo: AppText.subtitulo,
                  ),
                  SizedBox(height: 10),
                  AppText(
                    texto: 'Faça login para acessar sua conta.',
                    tamanho: 16,
                    cor: Cores.cinza,
                    estilo: AppText.corpo,
                  ),
                  SizedBox(height: 24),
                  CampoTexto(
                    controller: emailController,
                    hintText: 'E-mail',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icon(Icons.email, color: Cores.azul),
                  ),
                  SizedBox(height: 20),
                  CampoTexto(
                    controller: senhaController,
                    hintText: 'Senha',
                    senha: true,
                    prefixIcon: Icon(Icons.lock, color: Cores.azul),
                  ),
                  SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: lembrarDados,
                            activeColor: Cores.azul,
                            onChanged: (value) {
                              setState(() {
                                lembrarDados = value!;
                              });
                            },
                          ),
                          Flexible(
                              child: Text(
                            'Lembrar-me',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          )),
                        ],
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RecuperarSenha()),
                        ),
                        child: Text(
                          'Esqueceu sua senha?',
                          style: TextStyle(color: Cores.azul),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  if (mensagemErro.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(bottom: 15),
                      child: Text(
                        mensagemErro,
                        style: TextStyle(
                          color: Cores.vermelho,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Botao(
                    texto: enviando ? 'Entrando...' : 'Entrar',
                    onPressed: enviando ? () {} : fazerLogin,
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          thickness: 1,
                          color: Cores.cinza.withValues(alpha: 0.3),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'ou', // Em minúsculo igual na imagem
                          style: TextStyle(color: Cores.cinza, fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          thickness: 1,
                          color: Cores.cinza.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Botao(
                    texto: 'Criar uma conta',
                    backgroundColor: Colors.white,
                    textColor: Cores.azul,
                    borderColor: Cores.azul,
                    borderWidth: 1.5,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Cadastro()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
