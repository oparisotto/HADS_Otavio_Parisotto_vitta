import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plano.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.111:3000';

  // Método para obter headers com token
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ---------- BUSCAR ESTATÍSTICAS DE CHECKIN ----------
  static Future<Map<String, int>> getCheckinStats([int? usuarioId]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = usuarioId?.toString() ?? prefs.getString('user_id');

      if (userId == null) {
        print('❌ User ID não encontrado');
        return {'diarios': 0, 'semanais': 0, 'mensais': 0};
      }

      print('📊 Buscando estatísticas reais para usuário: $userId');

      final response = await http
          .get(
            Uri.parse('$baseUrl/checkins/stats/$userId'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

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
        return {'diarios': 0, 'semanais': 0, 'mensais': 0};
      }
    } catch (e) {
      print('❌ Exception ao buscar estatísticas: $e');
      return {'diarios': 0, 'semanais': 0, 'mensais': 0};
    }
  }

  // ✅ NOVO MÉTODO: REALIZAR CHECKIN COM USER ID ESPECÍFICO
  static Future<Map<String, dynamic>> realizarCheckin([int? usuarioId]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = usuarioId?.toString() ?? prefs.getString('user_id');

      if (userId == null) {
        return {'success': false, 'message': 'Usuário não identificado'};
      }

      print('📍 Realizando check-in para usuário: $userId');

      final response = await http.post(
        Uri.parse('$baseUrl/checkins'),
        headers: await _getHeaders(),
        body: jsonEncode({'usuario_id': userId}),
      );

      print('📡 Status Code: ${response.statusCode}');
      print('📡 Response: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Check-in realizado com sucesso! 🎉'
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Erro ao realizar check-in',
        };
      }
    } catch (e) {
      print('❌ Erro ao realizar check-in: $e');
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // ✅ NOVO MÉTODO: BUSCAR PLANO DO USUÁRIO ESPECÍFICO
  static Future<Map<String, dynamic>> getPlanoUsuario(String usuarioId) async {
    try {
      print('🔍 Buscando plano do usuário específico: $usuarioId');

      final response = await http.get(
        Uri.parse('$baseUrl/auth-usuarios/$usuarioId/plano'),
        headers: await _getHeaders(),
      );

      print('📡 Status Code: ${response.statusCode}');
      print('📡 Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          print('✅ Plano encontrado: ${data['nome_plano']} - Status: ${data['status_plano']}');
          return {
            'success': true,
            'nome_plano': data['nome_plano'] ?? 'Sem plano',
            'status_plano': data['status_plano'] ?? 'inativo',
            'descricao_plano': data['descricao_plano'] ?? '',
            'preco_plano': data['preco_plano'] ?? 0,
            'status_pagamento': data['status_pagamento'] ?? 'pendente',
          };
        } else {
          return {
            'success': false,
            'nome_plano': 'Sem plano',
            'status_plano': 'inativo',
          };
        }
      } else {
        print('❌ Erro ao buscar plano específico: ${response.statusCode}');
        // Fallback para método antigo
        return await getUserPlano();
      }
    } catch (e) {
      print('❌ Exception ao buscar plano específico: $e');
      // Fallback para método antigo
      return await getUserPlano();
    }
  }

  // ---------- LOGIN ----------
  static Future<Map<String, dynamic>> login(String email, String senha) async {
    try {
      print('🔐 Tentando login para: $email');

      final response = await http
          .post(
            Uri.parse('$baseUrl/auth-usuarios/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'senha': senha}),
          )
          .timeout(const Duration(seconds: 15));

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
          await prefs.setString('current_user_name', data['usuario']['nome']);
          await prefs.setString('current_user_email', data['usuario']['email']);

          print('✅ Login realizado com sucesso!');
          return {
            'success': true,
            'message': data['message'] ?? 'Login realizado com sucesso',
            'token': data['token'],
            'usuario': data['usuario'],
          };
        } else if (data['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token']);

          return {
            'success': true,
            'message': 'Login realizado',
            'token': data['token'],
            'usuario': {'id': 0, 'nome': 'Usuário', 'email': email},
          };
        } else {
          return {
            'success': false,
            'message': 'Estrutura de resposta inválida',
          };
        }
      } else {
        return {
          'success': false,
          'message':
              data['message'] ??
              'Erro no login - Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Erro no login: $e');
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // ---------- REGISTER (SALVA APENAS LOCALMENTE) ----------
  static Future<Map<String, dynamic>> register(
    String nome,
    String email,
    String senha,
  ) async {
    try {
      print('📝 Registrando usuário: $nome');

      final response = await http
          .post(
            Uri.parse('$baseUrl/auth-usuarios/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'nome': nome, 'email': email, 'senha': senha}),
          )
          .timeout(const Duration(seconds: 15));

      print('📡 Status Code: ${response.statusCode}');
      print('📡 Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // ✅ APENAS SALVA LOCALMENTE - NÃO CRIA NO ASAAS AINDA
        final prefs = await SharedPreferences.getInstance();

        // Limpa dados antigos
        await prefs.remove('token');
        await prefs.remove('user_id');
        await prefs.remove('user_name');
        await prefs.remove('user_email');
        await prefs.remove('user_status');

        // Salva novos dados
        if (data['token'] != null && data['usuario'] != null) {
          await prefs.setString('token', data['token']);
          await prefs.setString('user_id', data['usuario']['id'].toString());
          await prefs.setString('user_name', data['usuario']['nome']);
          await prefs.setString('user_email', data['usuario']['email']);
          await prefs.setString('current_user_name', data['usuario']['nome']);
          await prefs.setString('current_user_email', data['usuario']['email']);
          await prefs.setString(
            'user_status',
            data['usuario']['status'] ?? 'pending',
          );

          print('✅ USUÁRIO REGISTRADO LOCALMENTE: ${data['usuario']['nome']}');
          print('🆔 ID: ${data['usuario']['id']}');
          print('📧 Email: ${data['usuario']['email']}');
          print('📊 Status: ${data['usuario']['status']}');
          print('⚠️ Cliente ainda NÃO criado no Asaas - Aguardando pagamento');
        }

        return {
          'success': true,
          'message':
              data['message'] ??
              'Usuário registrado com sucesso. Faça o pagamento para ativar sua conta.',
          'usuario': data['usuario'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erro no registro',
        };
      }
    } catch (e) {
      print('❌ Erro no registro: $e');
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // ---------- VERIFICAR STATUS DO USUÁRIO ----------
  static Future<Map<String, dynamic>> verificarStatusUsuario(
    String usuarioId,
  ) async {
    try {
      print('🔍 Verificando status do usuário: $usuarioId');

      final response = await http
          .get(
            Uri.parse('$baseUrl/auth-usuarios/status/$usuarioId'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📊 Status do usuário: ${data['status']}');

        // Atualiza status no SharedPreferences
        if (data['success']) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_status', data['status']);
        }

        return {
          'success': true,
          'status': data['status'],
          'usuario': data['usuario'],
        };
      } else {
        return {
          'success': false,
          'message': 'Erro ao verificar status do usuário',
        };
      }
    } catch (e) {
      print('❌ Erro ao verificar status: $e');
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // ---------- ATIVAR USUÁRIO (APÓS PAGAMENTO) ----------
  static Future<Map<String, dynamic>> ativarUsuario(String usuarioId) async {
    try {
      print('🎯 Ativando usuário: $usuarioId');

      final response = await http
          .put(
            Uri.parse('$baseUrl/auth-usuarios/ativar/$usuarioId'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      print('📡 Status Code: ${response.statusCode}');
      print('📡 Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Atualiza status no SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_status', 'active');

        print('✅ USUÁRIO ATIVADO NO SISTEMA: $usuarioId');

        return {
          'success': true,
          'message': data['message'] ?? 'Usuário ativado com sucesso',
          'usuario': data['usuario'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erro ao ativar usuário',
        };
      }
    } catch (e) {
      print('❌ Erro ao ativar usuário: $e');
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
        'message': data['message'] ?? 'Erro ao enviar email',
      };
    } catch (e) {
      return {'success': false, 'message': 'Erro: $e'};
    }
  }

  static Future<Map<String, dynamic>> resetPassword(
    String email,
    String codigo,
    String novaSenha,
  ) async {
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
        'message': data['message'] ?? 'Erro ao redefinir senha',
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

  // ---------- BUSCAR PLANO DO USUÁRIO (MÉTODO ANTIGO) ----------
  static Future<Map<String, dynamic>> getUserPlano() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        return {'nome_plano': 'Sem plano'};
      }

      print('🔍 Buscando plano do usuário: $userId');

      final response = await http.get(
        Uri.parse('$baseUrl/pagamentos/ultimo-pago/$userId'),
        headers: await _getHeaders(),
      );

      print('📡 Status Code: ${response.statusCode}');
      print('📡 Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Plano encontrado: ${data['nome_plano']}');
        return data ?? {'nome_plano': 'Sem plano'};
      } else {
        print('❌ Erro ao buscar plano: ${response.statusCode}');
        return {'nome_plano': 'Sem plano'};
      }
    } catch (e) {
      print('❌ Exception ao buscar plano: $e');
      return {'nome_plano': 'Sem plano'};
    }
  }

  // ---------- BUSCAR PLANOS (PARA SELEÇÃO DE PLANOS) ----------
  static Future<Map<String, dynamic>> getPlanos() async {
    try {
      print('📡 Buscando planos...');

      final response = await http
          .get(Uri.parse('$baseUrl/planos'), headers: await _getHeaders())
          .timeout(const Duration(seconds: 10));

      print('📡 Status Code: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Resposta completa da API: $data');

        // ✅ CORREÇÃO: Verifica diferentes estruturas possíveis
        List<dynamic> planosData = [];

        if (data is List) {
          // Se a resposta é diretamente uma lista
          planosData = data;
          print('✅ Estrutura: Lista direta');
        } else if (data['planos'] is List) {
          // Se a resposta tem campo "planos"
          planosData = data['planos'];
          print('✅ Estrutura: Campo "planos"');
        } else if (data['data'] is List) {
          // Se a resposta tem campo "data"
          planosData = data['data'];
          print('✅ Estrutura: Campo "data"');
        } else {
          print('❌ Estrutura não reconhecida: $data');
          return {
            'success': false,
            'data': [],
            'message': 'Estrutura de resposta não reconhecida',
          };
        }

        print('✅ Número de planos encontrados: ${planosData.length}');

        // ✅ CORREÇÃO: Garante que todos os planos tenham a estrutura correta
        final planosProcessados = planosData.map((plano) {
          // Converte para Map se for necessário
          if (plano is! Map<String, dynamic>) {
            if (plano is Map) {
              return Map<String, dynamic>.from(plano);
            } else {
              return {'nome': 'Plano $plano', 'preco': 0.0};
            }
          }
          return plano;
        }).toList();

        return {
          'success': true,
          'data': planosProcessados,
          'message': 'Planos carregados com sucesso',
        };
      } else {
        print('❌ Erro HTTP: ${response.statusCode}');
        return {
          'success': false,
          'data': [],
          'message': 'Erro ao carregar planos: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Exception ao buscar planos: $e');
      return {'success': false, 'data': [], 'message': 'Erro de conexão: $e'};
    }
  }

  // ---------- BUSCAR PLANOS COMO LISTA (PARA TELA DE PLANOS EXISTENTE) ----------
  static Future<List<Plano>> getPlanosList() async {
    try {
      print('📡 Buscando lista de planos...');

      final response = await http
          .get(Uri.parse('$baseUrl/planos'), headers: await _getHeaders())
          .timeout(const Duration(seconds: 10));

      print('📡 Status Code: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Resposta completa da API: $data');

        // ✅ CORREÇÃO: Verifica diferentes estruturas possíveis da resposta
        List<dynamic> planosData = [];

        if (data is List) {
          // Se a resposta é diretamente uma lista
          planosData = data;
        } else if (data['planos'] is List) {
          // Se a resposta tem campo "planos"
          planosData = data['planos'];
        } else if (data['data'] is List) {
          // Se a resposta tem campo "data"
          planosData = data['data'];
        } else {
          print('❌ Estrutura de resposta não reconhecida');
          throw Exception('Estrutura de resposta não reconhecida');
        }

        print('✅ Número de planos encontrados: ${planosData.length}');

        // Converte para List<Plano>
        final List<Plano> planos = planosData.map((json) {
          print('📋 Processando plano: $json');
          return Plano.fromJson(json);
        }).toList();

        print('✅ Planos convertidos com sucesso: ${planos.length}');
        return planos;
      } else {
        print('❌ Erro HTTP: ${response.statusCode}');
        throw Exception('Erro ao carregar planos: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception ao buscar lista de planos: $e');
      throw Exception('Erro de conexão: $e');
    }
  }

  // ---------- BUSCAR ÚLTIMO PAGAMENTO PAGO ----------
  static Future<Map<String, dynamic>?> getUltimoPagamentoPago(
    int usuarioId,
  ) async {
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

  // ---------- PAGAMENTOS ASAAS ----------
  static Future<Map<String, dynamic>> criarClienteAsaas(
    String nome,
    String email,
    String cpfCnpj,
  ) async {
    try {
      print('👤 Criando cliente via rota compatível...');

      final response = await http.post(
        Uri.parse('$baseUrl/pagamentos/asaas/criar-cliente'),
        headers: await _getHeaders(),
        body: jsonEncode({'nome': nome, 'email': email, 'cpfCnpj': cpfCnpj}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'cliente': data['cliente']};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Erro ao criar cliente',
        };
      }
    } catch (e) {
      print('❌ Erro criarClienteAsaas: $e');
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  static Future<Map<String, dynamic>> criarCobrancaCartao({
    required String customerId,
    required double value,
    required String billingType,
    required Map<String, dynamic> creditCard,
    required Map<String, dynamic> creditCardHolderInfo,
    required String remoteIp,
  }) async {
    try {
      print('💳 Criando cobrança cartão via rota compatível...');

      final response = await http.post(
        Uri.parse('$baseUrl/pagamentos/asaas/criar-cobranca-cartao'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'customer': customerId,
          'value': value,
          'billingType': billingType,
          'dueDate': DateTime.now()
              .add(const Duration(days: 3))
              .toIso8601String()
              .split('T')[0],
          'creditCard': creditCard,
          'creditCardHolderInfo': creditCardHolderInfo,
          'remoteIp': remoteIp,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'cobranca': data['cobranca']};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Erro ao criar cobrança',
        };
      }
    } catch (e) {
      print('❌ Erro criarCobrancaCartao: $e');
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  static Future<Map<String, dynamic>> criarCobrancaPix({
    required String customerId,
    required double value,
  }) async {
    try {
      print('🔗 Criando cobrança PIX via rota compatível...');

      final response = await http.post(
        Uri.parse('$baseUrl/pagamentos/asaas/criar-cobranca-pix'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'customer': customerId,
          'value': value,
          'billingType': 'PIX',
          'dueDate': DateTime.now()
              .add(const Duration(days: 3))
              .toIso8601String()
              .split('T')[0],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'cobranca': data['cobranca']};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Erro ao criar cobrança PIX',
        };
      }
    } catch (e) {
      print('❌ Erro criarCobrancaPix: $e');
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // ---------- CRIAR PAGAMENTO PIX ----------
  static Future<Map<String, dynamic>> criarPagamentoPix({
    required int usuarioId,
    required int planoId,
    required double valor,
  }) async {
    try {
      print('💰 Criando pagamento PIX...');
      print('👤 Usuario ID: $usuarioId');
      print('📋 Plano ID: $planoId');
      print('💵 Valor: $valor');

      final response = await http
          .post(
            Uri.parse('$baseUrl/pagamentos/pix'),
            headers: await _getHeaders(),
            body: jsonEncode({
              'usuario_id': usuarioId,
              'plano_id': planoId,
              'valor': valor,
            }),
          )
          .timeout(const Duration(seconds: 15));

      print('📡 Status Code: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');

      // ✅ VERIFICA SE A RESPOSTA É HTML (ERRO)
      if (response.body.contains('<!DOCTYPE html>') ||
          response.body.contains('<html>')) {
        print('❌ Servidor retornou HTML em vez de JSON');
        return {
          'success': false,
          'message': 'Erro no servidor: rota /pagamentos/pix não encontrada',
        };
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
          'message': 'Pagamento PIX criado com sucesso',
        };
      } else {
        // Tenta decodificar o erro, se não conseguir retorna mensagem genérica
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? 'Erro ao criar pagamento PIX',
          };
        } catch (_) {
          return {
            'success': false,
            'message':
                'Erro HTTP ${response.statusCode} ao criar pagamento PIX',
          };
        }
      }
    } catch (e) {
      print('❌ Erro ao criar pagamento PIX: $e');
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // ---------- SALVAR ASSINATURA ----------
  static Future<Map<String, dynamic>> salvarAssinatura({
    required int usuarioId,
    required int planoId,
    required String customerId,
    required String subscriptionId,
    required String status,
  }) async {
    try {
      print('💾 SALVANDO ASSINATURA - Chamando backend...');
      print('👤 Usuario ID: $usuarioId');
      print('📋 Plano ID: $planoId');
      print('👥 Customer ID: $customerId');
      print('📄 Subscription ID: $subscriptionId');
      print('📊 Status Original: $status');

      // ✅ CORREÇÃO: Mapear status do Asaas para status do banco
      String statusParaBanco;
      switch (status.toUpperCase()) {
        case 'ACTIVE':
        case 'CONFIRMED':
        case 'RECEIVED':
        case 'APPROVED':
          statusParaBanco = 'pago';
          break;
        case 'PENDING':
        case 'AWAITING_PAYMENT':
        case 'IN_ANALYSIS':
          statusParaBanco = 'pendente';
          break;
        case 'OVERDUE':
        case 'EXPIRED':
          statusParaBanco = 'vencido';
          break;
        case 'CANCELLED':
        case 'CANCELED':
          statusParaBanco = 'cancelado';
          break;
        case 'REFUNDED':
          statusParaBanco = 'reembolsado';
          break;
        case 'INACTIVE':
          statusParaBanco = 'inativo';
          break;
        default:
          print(
            '⚠️ Status não reconhecido: $status, usando "pendente" como fallback',
          );
          statusParaBanco = 'pendente';
      }

      print('📊 Status Mapeado para Banco: $statusParaBanco');

      final response = await http
          .post(
            Uri.parse('$baseUrl/pagamentos'),
            headers: await _getHeaders(),
            body: jsonEncode({
              'usuario_id': usuarioId,
              'plano_id': planoId,
              'customer_id': customerId,
              'subscription_id': subscriptionId,
              'status': statusParaBanco, // ✅ ENVIAR STATUS JÁ MAPEADO
            }),
          )
          .timeout(const Duration(seconds: 15));

      print('📡 Status Code: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('✅✅✅ ASSINATURA SALVA E PLANO ATUALIZADO COM SUCESSO! ✅✅✅');

        // ✅ ATUALIZAR SHARED_PREFERENCES COM NOVO PLANO
        if (data['data']?['plano'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'user_plano',
            data['data']?['plano']?['nome'] ?? 'Plano Ativo',
          );
          print(
            '💾 Plano atualizado no SharedPreferences: ${data['data']?['plano']?['nome']}',
          );
        }

        return {
          'success': true,
          'data': data,
          'message': 'Assinatura salva e plano atualizado com sucesso',
        };
      } else {
        print('❌ Erro ao salvar assinatura: ${response.statusCode}');

        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? 'Erro ao salvar assinatura',
            'error_type': 'validation_error',
          };
        } catch (_) {
          return {
            'success': false,
            'message': 'Erro HTTP ${response.statusCode} ao salvar assinatura',
            'error_type': 'http_error',
          };
        }
      }
    } catch (e) {
      print('❌ Exception ao salvar assinatura: $e');
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
        'error_type': 'connection_error',
      };
    }
  }

  // ---------- CRIAR PAGAMENTO CARTAO ----------
  static Future<Map<String, dynamic>> criarPagamentoCartao({
    required int usuarioId,
    required int planoId,
    required double valor,
    required Map<String, dynamic> dadosCartao,
  }) async {
    try {
      print('💳 Criando pagamento cartão...');
      print('👤 Usuario ID: $usuarioId');
      print('📋 Plano ID: $planoId');
      print('💵 Valor: $valor');

      final response = await http
          .post(
            Uri.parse('$baseUrl/pagamentos/cartao'),
            headers: await _getHeaders(),
            body: jsonEncode({
              'usuario_id': usuarioId,
              'plano_id': planoId,
              'valor': valor,
              'dados_cartao': dadosCartao,
            }),
          )
          .timeout(const Duration(seconds: 15));

      print('📡 Status Code: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');

      // ✅ VERIFICA SE A RESPOSTA É HTML (ERRO)
      if (response.body.contains('<!DOCTYPE html>') ||
          response.body.contains('<html>')) {
        print('❌ Servidor retornou HTML em vez de JSON');
        return {
          'success': false,
          'message': 'Erro no servidor: rota /pagamentos/cartao não encontrada',
        };
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
          'message': 'Pagamento cartão criado com sucesso',
        };
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? 'Erro ao criar pagamento cartão',
          };
        } catch (_) {
          return {
            'success': false,
            'message':
                'Erro HTTP ${response.statusCode} ao criar pagamento cartão',
          };
        }
      }
    } catch (e) {
      print('❌ Erro ao criar pagamento cartão: $e');
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // ---------- CANCELAR PLANO DO USUÁRIO ----------
  static Future<Map<String, dynamic>> cancelarPlanoUsuario(
    int usuarioId,
  ) async {
    try {
      print('❌ Cancelando plano do usuário: $usuarioId');

      final response = await http
          .put(
            Uri.parse('$baseUrl/auth-usuarios/$usuarioId/cancelar-plano'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      print('📡 Status Code: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');

      // ✅ VERIFICAR SE A RESPOSTA É HTML (ERRO 404)
      if (response.body.contains('<!DOCTYPE html>') ||
          response.body.contains('<html>')) {
        print('❌ Servidor retornou HTML em vez de JSON - Rota não encontrada');
        return {
          'success': false,
          'message': 'Erro: Rota de cancelamento não encontrada no servidor',
          'error_type': 'route_not_found',
        };
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Plano cancelado com sucesso',
          'usuario': data['usuario'],
        };
      } else {
        // Tentar decodificar o erro
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? 'Erro ao cancelar plano',
            'error_type': 'api_error',
          };
        } catch (_) {
          return {
            'success': false,
            'message': 'Erro HTTP ${response.statusCode} ao cancelar plano',
            'error_type': 'http_error',
          };
        }
      }
    } catch (e) {
      print('❌ Erro ao cancelar plano: $e');
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
        'error_type': 'connection_error',
      };
    }
  }

  // ---------- REATIVAR PLANO DO USUÁRIO ----------
  static Future<Map<String, dynamic>> reativarPlanoUsuario(
    int usuarioId,
  ) async {
    try {
      print('✅ Reativando plano do usuário: $usuarioId');

      final response = await http
          .put(
            Uri.parse('$baseUrl/auth-usuarios/$usuarioId/reativar-plano'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      print('📡 Status Code: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');

      // ✅ VERIFICAR SE A RESPOSTA É HTML (ERRO 404)
      if (response.body.contains('<!DOCTYPE html>') ||
          response.body.contains('<html>')) {
        print('❌ Servidor retornou HTML em vez de JSON - Rota não encontrada');
        return {
          'success': false,
          'message': 'Erro: Rota de reativação não encontrada no servidor',
          'error_type': 'route_not_found',
        };
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Plano reativado com sucesso',
          'usuario': data['usuario'],
        };
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? 'Erro ao reativar plano',
            'error_type': 'api_error',
          };
        } catch (_) {
          return {
            'success': false,
            'message': 'Erro HTTP ${response.statusCode} ao reativar plano',
            'error_type': 'http_error',
          };
        }
      }
    } catch (e) {
      print('❌ Erro ao reativar plano: $e');
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
        'error_type': 'connection_error',
      };
    }
  }

  // ---------- VERIFICAR STATUS DO PLANO ----------
  static Future<Map<String, dynamic>> verificarStatusPlano(
    int usuarioId,
  ) async {
    try {
      print('🔍 Verificando status do plano do usuário: $usuarioId');

      final response = await http
          .get(
            Uri.parse('$baseUrl/auth-usuarios/$usuarioId/status-plano'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      print('📡 Status Code: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'status_plano': data['data']['status_plano'] ?? 'ativo',
          'data': data['data'],
        };
      } else {
        // Se a rota não existir, assumir que o plano está ativo
        return {'success': true, 'status_plano': 'ativo', 'fallback': true};
      }
    } catch (e) {
      print('❌ Erro ao verificar status do plano: $e');
      // Em caso de erro, assumir que o plano está ativo
      return {'success': true, 'status_plano': 'ativo', 'fallback': true};
    }
  }
}