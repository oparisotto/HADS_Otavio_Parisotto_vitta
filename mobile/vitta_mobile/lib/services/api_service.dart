import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/plano.dart'; // certifique-se de criar o model Plano

class ApiService {
  static const String baseUrl = 'http://192.168.1.103:3000';

  // ---------- LOGIN ----------
  static Future<Map<String, dynamic>> login(String email, String senha) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth-usuarios/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'senha': senha}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'message': jsonDecode(response.body)['message'] ?? 'Erro no login'};
      }
    } catch (e) {
      return {'message': 'Erro de conexão com o servidor: $e'};
    }
  }

  // ---------- REGISTER ----------
  static Future<Map<String, dynamic>> register(String nome, String email, String senha) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth-usuarios/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nome': nome, 'email': email, 'senha': senha}),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Erro de conexão: $e'};
    }
  }

  // ---------- ESQUECI MINHA SENHA ----------
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth-usuarios/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Erro: $e'};
    }
  }

  static Future<Map<String, dynamic>> resetPassword(String email, String codigo, String novaSenha) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth-usuarios/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'codigo': codigo,
          'novaSenha': novaSenha,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Erro: $e'};
    }
  }

  // ---------- BUSCAR PLANOS ----------
  static Future<List<Plano>> getPlanos() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/planos')); // seu endpoint de planos

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Plano.fromJson(json)).toList();
      } else {
        throw Exception('Erro ao carregar planos');
      }
    } catch (e) {
      throw Exception('Erro de conexão ao buscar planos: $e');
    }
  }

  // ---------- BUSCAR ÚLTIMO PAGAMENTO PAGO ----------
  static Future<Map<String, dynamic>?> getUltimoPagamentoPago(int usuarioId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/ultimo-pago/$usuarioId'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Garantindo que sempre retorne um Map válido
        return data ;
      } else {
        return null;
      }
    } catch (e) {
      print("Erro ao buscar último pagamento: $e");
      return null;
    }
  }
}
