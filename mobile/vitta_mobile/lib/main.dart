import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/reset_password_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vitta App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      initialRoute: '/login',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/register':
            return MaterialPageRoute(builder: (_) => const RegisterScreen());
          case '/forgot-password':
            return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
          case '/reset-password':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (_) => ResetPasswordScreen(email: args?['email'] ?? ''),
            );
          case '/home':
            final args = settings.arguments as Map<String, dynamic>?;
            // ⚡ Aqui usamos usuarioId ao invés de planoUsuario
            return MaterialPageRoute(
              builder: (_) => HomeScreen(
                nomeUsuario: args?['nomeUsuario'] ?? 'Usuário',
                usuarioId: args?['usuarioId'] ?? 0,// necessário para buscar plano

              ),
            );
          default:
            return null;
        }
      },
    );
  }
}
