import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/planos_screen.dart';
import 'screens/selecao_plano_screen.dart';
import 'screens/pagamento_screen.dart';

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
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/selecao-plano': (context) => const SelecaoPlanoScreen(),
        '/pagamento': (context) => const PagamentoScreen(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/reset-password':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (_) => ResetPasswordScreen(email: args?['email'] ?? ''),
            );
          case '/home':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (_) => HomeScreen(
                nomeUsuario: args?['nomeUsuario'] ?? 'Usuário',
                usuarioId: args?['usuarioId'] ?? 0,
              ),
            );
          case '/planos':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (_) => PlanosScreen(
                nomeUsuario: args?['nomeUsuario'] ?? 'Usuário',
                planoUsuario: args?['planoUsuario'] ?? 'Sem plano',
                usuarioId: args?['usuarioId'] ?? 0, // ✅ ADICIONAR usuarioId
              ),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => const LoginScreen(),
            );
        }
      },
    );
  }
}