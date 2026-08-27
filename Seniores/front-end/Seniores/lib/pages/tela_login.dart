import 'package:flutter/material.dart';
import '../widgets/custom_textos.dart';
import '../widgets/custom_textField.dart';
import '../widgets/custom_botao.dart';
import '../utils/cores.dart';
import 'tela_cadastro.dart';
import 'tela_inicio.dart';

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

  void fazerLogin() {
    String email = emailController.text.trim();
    String senha = senhaController.text;

    if (email.isEmpty) {
      setState(() {
        mensagemErro = 'Digite seu e-mail.';
      });
    }

     else if (!validarEmail(email)) {
      setState(() {
        mensagemErro = 'Digite um e-mail válido.';
      });
    }
    
    else if (senha.isEmpty) {
      setState(() {
        mensagemErro = 'Digite sua senha.';
      });
    }

     else if (senha.length < 6) {
      setState(() {
        mensagemErro = 'A senha deve possuir pelo menos 6 caracteres.';
      });
    }
     
    else {
      setState(() {
        mensagemErro = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login realizado com sucesso!'),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const Home(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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

              const SizedBox(height: 10),

              const AppText(
                texto: 'Bem-vindo de volta!',
                tamanho: 28,
                peso: FontWeight.bold,
                cor: Cores.azul,
                estilo: AppText.subtitulo,
              ),

              const SizedBox(height: 10),

              const AppText(
                texto: 'Faça login para acessar sua conta.',
                tamanho: 16,
                cor: Cores.cinza,
                estilo: AppText.corpo,
              ),

              const SizedBox(height: 40),

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
                controller: senhaController,
                hintText: 'Senha',
                senha: true,
                prefixIcon: const Icon(
                  Icons.lock,
                  color: Cores.azul,
                ),
              ),
              
              const SizedBox(height: 10),

              Row(
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

                  const Text(
                    'Lembrar-me',
                    style: TextStyle(color: Cores.preto),
                  ),

                  const Spacer(),

                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Em breve.'),
                        ),
                      );
                    },
                    child: const Text(
                      'Esqueceu sua senha?',
                      style: TextStyle(
                        color: Cores.azul,
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
                texto: 'Entrar',
                onPressed: fazerLogin,
              ),

              const SizedBox(height: 20),

              const Row(
                children: [
                  Expanded(
                    child: Divider(
                      thickness: 1,
                      color: Cores.branco,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'OU',
                      style: TextStyle(
                        color: Cores.cinza,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      thickness: 1,
                      color: Cores.branco,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Botao(
                texto: 'Criar uma conta',
                backgroundColor: Cores.branco,
                textColor: Cores.azul,
                borderColor: Cores.azul,
                borderWidth: 2,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Cadastro(),
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