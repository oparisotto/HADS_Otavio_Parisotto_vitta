import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  final codigoController = TextEditingController();
  final senhaController = TextEditingController();

  bool codigoEnviado = false;
  bool loading = false;
  String? message;

  Future<void> enviarCodigo() async {
    setState(() => loading = true);
    final res = await ApiService.forgotPassword(emailController.text.trim());
    setState(() {
      loading = false;
      message = res['message'];
      if (res['message'].toString().contains("enviado")) {
        codigoEnviado = true;
      }
    });
  }

  Future<void> resetarSenha() async {
    setState(() => loading = true);
    final res = await ApiService.resetPassword(
      emailController.text.trim(),
      codigoController.text.trim(),
      senhaController.text.trim(),
    );
    setState(() {
      loading = false;
      message = res['message'];
    });

    if (message != null && message!.contains("sucesso")) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Recuperar Senha",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Digite seu email cadastrado para receber o código de recuperação",
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: "Email cadastrado",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                if (codigoEnviado) ...[
                  TextField(
                    controller: codigoController,
                    decoration: const InputDecoration(
                      labelText: "Código recebido",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: senhaController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Nova senha",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                if (message != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      message!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: message!.contains("sucesso")
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: loading
                      ? null
                      : codigoEnviado
                          ? resetarSenha
                          : enviarCodigo,
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          codigoEnviado ? "Redefinir Senha" : "Enviar Código",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold,),
                        ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  child: const Text(
                    "Voltar ao login",
                    style: TextStyle(color: Color(0xFF2E7D32)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
