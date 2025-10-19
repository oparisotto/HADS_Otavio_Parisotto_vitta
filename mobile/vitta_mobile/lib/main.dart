import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/planos_screen.dart';
import 'screens/selecao_plano_screen.dart';
import 'screens/pagamento_screen.dart';
import 'screens/checkin_screen.dart';
import 'models/header_card.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Mude para false para tema claro, ou true para tema escuro
  bool _isDarkTheme = false; // ✅ AGORA COM TEMA CLARO PADRÃO

  void toggleTheme() {
    setState(() {
      _isDarkTheme = !_isDarkTheme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vitta App',
      debugShowCheckedModeBanner: false,
      themeMode: _isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/selecao-plano': (context) => const SelecaoPlanoScreen(),
        '/pagamento': (context) => const PagamentoScreen(),
      },
      onGenerateRoute: (settings) {
        final args = settings.arguments as Map<String, dynamic>?;

        switch (settings.name) {
          case '/reset-password':
            return MaterialPageRoute(
              builder: (_) => ResetPasswordScreen(email: args?['email'] ?? ''),
            );

          case '/home':
            return MaterialPageRoute(
              builder: (_) => HomeScreen(
                nomeUsuario: args?['nomeUsuario'] ?? 'Usuário',
                usuarioId: args?['usuarioId'] ?? 0,
                token: args?['token'] ?? '',
                isDarkTheme: _isDarkTheme,
                onToggleTheme: toggleTheme,
              ),
            );

          case '/planos':
            final nomeUsuario = args?['nomeUsuario'] ?? 'Usuário';
            final usuarioId = args?['usuarioId'] ?? 0;
            final token = args?['token'] ?? '';

            return MaterialPageRoute(
              builder: (context) => PlanosScreen(
                headerCard: HeaderCard(
                  nome: nomeUsuario,
                  plano: '', // vai ser atualizado pela tela
                  status: '', // vai ser atualizado pela tela
                  planoAtivo: true,
                  onRefresh: () {}, // a tela vai lidar com refresh
                ),
                usuarioId: usuarioId,
                token: token,
              ),
            );

          case '/checkin':
            return MaterialPageRoute(
              builder: (_) => CheckinScreen(
                usuarioId: args?['usuarioId'] ?? 0,
                isDarkTheme: _isDarkTheme,
              ),
            );

          default:
            return MaterialPageRoute(builder: (_) => const LoginScreen());
        }
      },
    );
  }

  // ✅ Tema Claro
  ThemeData _buildLightTheme() {
    return ThemeData(
      colorScheme: ColorScheme.light(
        primary: Colors.green, // ✅ VERDE
        secondary: Colors.greenAccent,
        background: Colors.grey[50]!,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSurface: Colors.black87,
      ),
      scaffoldBackgroundColor: Colors.grey[50],
      cardColor: Colors.white,
      useMaterial3: true,
    );
  }

  // ✅ Tema Escuro
  ThemeData _buildDarkTheme() {
    return ThemeData(
      colorScheme: ColorScheme.dark(
        primary: Colors.green, // ✅ VERDE MESMO NO TEMA ESCURO
        secondary: Colors.greenAccent,
        background: Colors.grey[900]!,
        surface: Colors.grey[800]!,
        onPrimary: Colors.white,
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.grey[900],
      cardColor: Colors.grey[800],
      useMaterial3: true,
    );
  }
}
