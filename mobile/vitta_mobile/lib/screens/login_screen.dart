import 'package:flutter/material.dart';
import 'package:vitta_mobile/services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();

  bool loading = false;
  String message = '';

  Future<void> login() async {
    final email = emailController.text.trim();
    final senha = senhaController.text.trim();

    if (email.isEmpty || senha.isEmpty) {
      setState(() => message = "Preencha todos os campos");
      return;
    }

    setState(() {
      loading = true;
      message = '';
    });

    try {
      // Faz login
      final res = await ApiService.login(email, senha);

      // ✅ CORREÇÃO: Verificação de acordo com o backend
      if (res['token'] != null && res['usuario'] != null) {
        final usuario = res['usuario'];
        final usuarioId = usuario['id']?.toString() ?? '';
        final nomeUsuario = usuario['nome'] ?? 'Usuário';
        final statusUsuario = usuario['status'] ?? 'pending';

        // ✅ VERIFICAÇÃO DE STATUS DO USUÁRIO
        if (statusUsuario == 'pending') {
          setState(() {
            message = "Sua conta está pendente de ativação. Faça o pagamento para ativar.";
            loading = false;
          });
          return;
        }

        if (statusUsuario == 'inactive') {
          setState(() {
            message = "Sua conta está inativa. Entre em contato com o suporte.";
            loading = false;
          });
          return;
        }

        // ✅ NAVEGAÇÃO PARA HOME APÓS LOGIN BEM-SUCEDIDO
        Navigator.pushReplacementNamed(
          context,
          '/home',
          arguments: {
            'nomeUsuario': nomeUsuario,
            'usuarioId': int.tryParse(usuarioId) ?? 0,
            'token': res['token'],
          },
        );
      } else {
        // Mostra mensagem de erro do backend
        setState(() => message = res['message'] ?? 'Erro ao fazer login');
      }
    } catch (e) {
      setState(() => message = 'Erro ao conectar com o servidor: $e');
      print('❌ Erro no login: $e');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo e título
              Center(
                child: Column(
                  children: [
                    Icon(Icons.fitness_center, color: Colors.green[700], size: 60),
                    const SizedBox(height: 12),
                    Text(
                      "Bem-vindo de volta!",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Faça login para continuar no Vitta",
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Campo Email
              const Text("Email", style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Digite seu email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),

              // Campo Senha
              const Text("Senha", style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              TextField(
                controller: senhaController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Digite sua senha',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),

              const SizedBox(height: 10),

              // Esqueci a senha
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/forgot-password');
                  },
                  child: const Text(
                    "Esqueci minha senha",
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Botão Login
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          "Entrar", 
                          style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)
                        ),
                ),
              ),

              const SizedBox(height: 10),

              // Mensagem de erro/sucesso
              if (message.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: message.contains("pendente") ? Colors.orange[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: message.contains("pendente") 
                          ? Colors.orange[200]! 
                          : Colors.red[200]!
                    ),
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: message.contains("pendente") 
                          ? Colors.orange[700] 
                          : Colors.red[700], 
                      fontSize: 14
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 20),

              // Cadastro
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Não tem conta? "),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: const Text(
                      "Cadastre-se",
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}