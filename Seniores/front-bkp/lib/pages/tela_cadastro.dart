import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/custom_textos.dart';
import '../widgets/custom_textField.dart';
import '../widgets/custom_botao.dart';
import '../utils/mascaras.dart';
import '../services/api_service.dart';
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
final TextEditingController confirmarSenhaController = TextEditingController();
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
    final regex = RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',);

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
    
     else if (senha != confirmarSenhaController.text) {
      setState(() {
        mensagemErro = 'As senhas não coincidem.';
      });
    }

    else if (!concordouTermos) {
  setState(() {
    mensagemErro = 'Você deve aceitar os Termos de Uso.';
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

      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(
      //     builder: (_) => const Home(),
      //   ),
      // ); // tela home
    }
  }

  Future<void> cadastrar() async {
    final nome = nomeController.text.trim();
    final email = emailController.text.trim();
    final senha = senhaController.text;
    final cpf = cpfController.text.trim();
    final telefone = telefoneController.text.trim();

    if (nome.isEmpty || !validarEmail(email) || senha.length < 6 || cpf.isEmpty || telefone.isEmpty || tipoUsuario == null || senha != confirmarSenhaController.text || !concordouTermos) {
      setState(() => mensagemErro = 'Revise todos os campos e aceite os Termos de Uso.');
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
        // A API usa o identificador sem acento.
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
                cor: Color(0xFF275DAD),
                estilo: AppText.titulo,
              ),

              const AppText(
                texto: 'Crie sua conta!',
                tamanho: 28,
                peso: FontWeight.bold,
                cor: Color(0xFF275DAD),
                estilo: AppText.subtitulo,
              ),

              const SizedBox(height: 10),

              const AppText(
                texto: 'Preencha os dados abaixo para se cadastrar.',
                tamanho: 16,
                cor: Color(0xFF636E72),
                estilo: AppText.corpo,
              ),

              const SizedBox(height: 40),
              
              CampoTexto(
                controller: nomeController,
                hintText: 'Nome completo',
                keyboardType: TextInputType.text,
                prefixIcon: const Icon(
                  Icons.person,
                  color: Color(0xFF275DAD),
                ),
              ),

              const SizedBox(height: 20),

              CampoTexto(
                controller: emailController,
                hintText: 'E-mail',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(
                  Icons.email,
                  color: Color(0xFF275DAD),
                ),
              ),

              const SizedBox(height: 20),

             CampoTexto(
              controller: cpfController,
              hintText: 'CPF',
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(
                Icons.badge_outlined,
                color: Color(0xFF275DAD),
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
          color: Color(0xFF275DAD),
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
        prefixIcon: const Icon(Icons.person_outline,color:Color(0XFF275DAD)),
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
                  color: Color(0xFF275DAD),
                ),
              ),
               
               const SizedBox(height: 20),

                 CampoTexto(
                controller: confirmarSenhaController,
                hintText: 'Confirmar senha',
                senha: true,
                prefixIcon: const Icon(
                  Icons.lock,
                  color: Color(0xFF275DAD),
                ),
              ),
               
               const SizedBox(height: 20),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: concordouTermos,
                      activeColor: const Color(0xFF275DAD),
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
                            color: Color(0xFF636E72),
                          ),
                          children: [
                            TextSpan(text: 'Eu concordo com os '),
                            TextSpan(
                              text: 'Termos de Uso',
                              style: TextStyle(
                                color: Color(0xFF275DAD),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(text: ' e '),
                            TextSpan(
                              text: 'Política de Privacidade.',
                              style: TextStyle(
                                color: Color(0xFF275DAD),
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
                      color: Color(0xFFEB5757),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              Botao(
                texto: enviando ? 'Cadastrando...' : 'Cadastrar',
                onPressed: enviando ? () {} : cadastrar,
              ),
           
           const SizedBox(height: 20),

              const Row(
                children: [
                  Expanded(
                    child: Divider(
                      thickness: 1,
                      color: Color(0xFFD9D9D9),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'OU',
                      style: TextStyle(
                        color: Color(0xFF636E72),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      thickness: 1,
                      color: Color(0xFFD9D9D9),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

            Botao(
            texto: 'Fazer login',
            backgroundColor: Colors.white,
            textColor: const Color(0xFF275DAD),
            borderColor: const Color(0xFF275DAD),
            borderWidth: 2,
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
