import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email; // vem da tela anterior

  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final codigoController = TextEditingController();
  final senhaController = TextEditingController();
  bool loading = false;
  String? message;

  Future<void> resetPassword() async {
    setState(() => loading = true);
    final res = await ApiService.resetPassword(
      widget.email,
      codigoController.text,
      senhaController.text,
    );
    setState(() {
      loading = false;
      message = res['message'];
    });

    if (res['message']?.contains('sucesso') ?? false) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Redefinir senha",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                Text(
                  "Enviamos um código para ${widget.email}. Insira abaixo junto com sua nova senha:",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: codigoController,
                  decoration: const InputDecoration(labelText: "Código recebido"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: senhaController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Nova senha"),
                ),
                const SizedBox(height: 20),
                if (message != null)
                  Text(
                    message!,
                    style: TextStyle(color: message!.contains("sucesso") ? Colors.green : Colors.red),
                  ),
                ElevatedButton(
                  onPressed: loading ? null : resetPassword,
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Confirmar"),
                ),
                TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text("Voltar ao login"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
