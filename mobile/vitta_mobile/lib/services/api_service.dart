import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plano.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.101:3000';

  // Método para obter headers com token
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ---------- BUSCAR ESTATÍSTICAS DE CHECKIN (CORRIGIDO) ----------
  static Future<Map<String, int>> getCheckinStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      
      if (userId == null) {
        print('❌ User ID não encontrado');
        return {'diarios': 0, 'semanais': 0, 'mensais': 0};
      }

      print('📊 Buscando estatísticas reais para usuário: $userId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/checkins/stats/$userId'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Estatísticas recebidas do banco: $data');
        
        return {
          'diarios': data['diarios'] ?? 0,
          'semanais': data['semanais'] ?? 0,
          'mensais': data['mensais'] ?? 0,
        };
      } else {
        print('❌ Erro ao buscar estatísticas: ${response.statusCode}');
        print('❌ Response: ${response.body}');
        // Retorna valores reais zero em caso de erro
        return {'diarios': 0, 'semanais': 0, 'mensais': 0};
      }
    } catch (e) {
      print('❌ Exception ao buscar estatísticas: $e');
      return {'diarios': 0, 'semanais': 0, 'mensais': 0};
    }
  }

  // ---------- LOGIN ----------
  static Future<Map<String, dynamic>> login(String email, String senha) async {
    try {
      print('🔐 Tentando login para: $email');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth-usuarios/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'senha': senha}),
      ).timeout(const Duration(seconds: 15));

      print('📡 Status Code: ${response.statusCode}');
      print('📡 Response: ${response.body}');

      final responseBody = response.body;
      if (responseBody.isEmpty) {
        return {'success': false, 'message': 'Resposta vazia do servidor'};
      }

      final data = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        if (data['token'] != null && data['usuario'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token']);
          await prefs.setString('user_id', data['usuario']['id'].toString());
          await prefs.setString('user_name', data['usuario']['nome']);
          await prefs.setString('user_email', data['usuario']['email']);
          
          print('✅ Login realizado com sucesso!');
          return {
            'success': true,
            'message': data['message'] ?? 'Login realizado com sucesso',
            'token': data['token'],
            'usuario': data['usuario']
          };
        } else if (data['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token']);
          
          return {
            'success': true,
            'message': 'Login realizado',
            'token': data['token'],
            'usuario': {'id': 0, 'nome': 'Usuário', 'email': email}
          };
        } else {
          return {'success': false, 'message': 'Estrutura de resposta inválida'};
        }
      } else {
        return {
          'success': false, 
          'message': data['message'] ?? 'Erro no login - Status: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('❌ Erro no login: $e');
      return {
        'success': false, 
        'message': 'Erro de conexão: $e'
      };
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

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Usuário registrado com sucesso'};
      } else {
        final errorData = jsonDecode(response.body);
        return {'success': false, 'message': errorData['message'] ?? 'Erro no registro'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
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

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Erro ao enviar email'
      };
    } catch (e) {
      return {'success': false, 'message': 'Erro: $e'};
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

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Erro ao redefinir senha'
      };
    } catch (e) {
      return {'success': false, 'message': 'Erro: $e'};
    }
  }

  // ---------- BUSCAR DADOS DO USUÁRIO ----------
  static Future<Map<String, dynamic>> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getString('user_id'),
      'nome': prefs.getString('user_name') ?? 'Usuário',
      'email': prefs.getString('user_email') ?? '',
    };
  }

  // ---------- BUSCAR PLANO DO USUÁRIO ----------
  static Future<Map<String, dynamic>> getUserPlano() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      
      if (userId == null) {
        return {'nome_plano': 'Sem plano'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/pagamentos/ultimo-pago/$userId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data ?? {'nome_plano': 'Sem plano'};
      }
      return {'nome_plano': 'Sem plano'};
    } catch (e) {
      print('Erro ao buscar plano: $e');
      return {'nome_plano': 'Sem plano'};
    }
  }

  // ---------- REALIZAR CHECKIN ----------
  static Future<Map<String, dynamic>> realizarCheckin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      
      if (userId == null) {
        return {'success': false, 'message': 'Usuário não identificado'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/checkins'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'usuario_id': userId,
        }),
      );

      if (response.statusCode == 201) {
        return {'success': true, 'message': 'Check-in realizado com sucesso!'};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Erro ao realizar check-in'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // ---------- BUSCAR PLANOS ----------
  static Future<List<Plano>> getPlanos() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/planos'),
        headers: await _getHeaders(),
      );

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
      final response = await http.get(
        Uri.parse('$baseUrl/pagamentos/ultimo-pago/$usuarioId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return null;
      }
    } catch (e) {
      print("Erro ao buscar último pagamento: $e");
      return null;
    }
  }
}