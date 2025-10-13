import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SelecaoPlanoScreen extends StatefulWidget {
  const SelecaoPlanoScreen({super.key});

  @override
  State<SelecaoPlanoScreen> createState() => _SelecaoPlanoScreenState();
}

class _SelecaoPlanoScreenState extends State<SelecaoPlanoScreen> {
  int? planoSelecionado;
  List<dynamic> planos = [];
  bool loading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _carregarPlanos();
  }

  Future<void> _carregarPlanos() async {
    try {
      setState(() {
        loading = true;
        errorMessage = '';
      });

      print('🔄 Carregando planos...');
      
      // Chama sua API para buscar os planos
      final response = await ApiService.getPlanos();
      
      print('📡 Resposta da API: ${response['success']}');
      print('📡 Dados recebidos: ${response['data']}');
      
      if (response['success'] == true) {
        final data = response['data'];
        if (data is List && data.isNotEmpty) {
          setState(() {
            planos = List<dynamic>.from(data);
          });
          print('✅ ${planos.length} planos carregados com sucesso');
        } else {
          setState(() {
            errorMessage = 'Nenhum plano disponível no momento';
          });
          print('⚠️ Nenhum plano encontrado na resposta');
        }
      } else {
        setState(() {
          errorMessage = response['message'] ?? 'Erro ao carregar planos';
        });
        print('❌ Erro na resposta: ${response['message']}');
      }
    } catch (e) {
      print('💥 Erro ao carregar planos: $e');
      setState(() {
        errorMessage = 'Erro de conexão: $e';
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  void _selecionarPlano(int index) {
    setState(() {
      planoSelecionado = index;
    });
    print('🎯 Plano selecionado: ${planos[index]['nome']}');
  }

  void _continuarParaPagamento() {
    if (planoSelecionado != null) {
      final planoSelecionadoData = planos[planoSelecionado!];
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      
      print('🚀 Continuando para pagamento com plano: ${planoSelecionadoData['nome']}');
      
      Navigator.pushReplacementNamed(
        context,
        '/pagamento',
        arguments: {
          'plano': planoSelecionadoData,
          'plano_id': planoSelecionadoData['id'],
          'nomeUsuario': args?['nomeUsuario'] ?? 'Usuário',
          'usuarioId': args?['usuarioId'] ?? 0,
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione um plano para continuar'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // Método para mapear cores baseado no nome do plano
  Color _getCorPlano(String nomePlano) {
    final nome = nomePlano.toLowerCase();
    if (nome.contains('básico') || nome.contains('basico')) {
      return const Color(0xFF4CAF50);
    } else if (nome.contains('premium')) {
      return const Color(0xFF2196F3);
    } else if (nome.contains('vip')) {
      return const Color(0xFF9C27B0);
    } else if (nome.contains('avançado') || nome.contains('avancado')) {
      return const Color(0xFFFF9800);
    } else {
      return const Color(0xFF2E7D32);
    }
  }

  // Método para obter o preço formatado
  String _getPrecoFormatado(dynamic preco) {
    if (preco == null) return '0.00';
    
    if (preco is int) {
      return preco.toDouble().toStringAsFixed(2);
    } else if (preco is double) {
      return preco.toStringAsFixed(2);
    } else if (preco is String) {
      return double.tryParse(preco)?.toStringAsFixed(2) ?? '0.00';
    } else {
      return '0.00';
    }
  }

  // Método para obter a descrição do plano
  String _getDescricaoPlano(dynamic plano) {
    return plano['descricao'] ?? 
           plano['descricao_plano'] ?? 
           'Plano ${plano['nome'] ?? ''}';
  }

  // Método para obter o período
  String _getPeriodo(dynamic plano) {
    return plano['periodo'] ?? 
           plano['duracao'] ?? 
           plano['duracao_dias']?.toString() ?? 
           'mensal';
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final nomeUsuario = args?['nomeUsuario'] ?? 'Usuário';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Escolha seu Plano'),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarPlanos,
            tooltip: 'Recarregar planos',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: const Color(0xFF2E7D32),
            child: Column(
              children: [
                Text(
                  'Bem-vindo, $nomeUsuario!',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Selecione o plano ideal para você',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Comece sua jornada fitness',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Conteúdo Principal
          Expanded(
            child: loading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Carregando planos...',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  )
                : errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 50),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                errorMessage,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _carregarPlanos,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                              ),
                              child: const Text('Tentar Novamente'),
                            ),
                          ],
                        ),
                      )
                    : planos.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue, size: 50),
                                SizedBox(height: 16),
                                Text(
                                  'Nenhum plano disponível no momento',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _buildListaPlanos(),
          ),

          // Botão Continuar
          if (!loading && planos.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _continuarParaPagamento,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Continuar para Pagamento',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildListaPlanos() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        itemCount: planos.length,
        itemBuilder: (context, index) {
          final plano = planos[index];
          final bool isSelected = planoSelecionado == index;
          final corPlano = _getCorPlano(plano['nome'] ?? 'Plano');
          final precoFormatado = _getPrecoFormatado(plano['preco']);
          final descricao = _getDescricaoPlano(plano);
          final periodo = _getPeriodo(plano);

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isSelected ? corPlano.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? corPlano : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _selecionarPlano(index),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header do plano
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  plano['nome']?.toString().toUpperCase() ?? 'PLANO',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: corPlano,
                                  ),
                                ),
                                if (descricao.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      descricao,
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: corPlano,
                              size: 24,
                            ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Preço
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'R\$$precoFormatado',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: corPlano,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              '/$periodo',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Vantagens
                      ..._getVantagensDoPlano(plano).map<Widget>((vantagem) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: corPlano,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  vantagem,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Método para obter vantagens do plano
  List<String> _getVantagensDoPlano(dynamic plano) {
    // Tenta obter vantagens do banco
    if (plano['vantagens'] != null && plano['vantagens'] is List) {
      return List<String>.from(plano['vantagens']);
    }
    
    if (plano['beneficios'] != null) {
      if (plano['beneficios'] is List) {
        return List<String>.from(plano['beneficios']);
      } else if (plano['beneficios'] is String) {
        return [plano['beneficios']];
      }
    }

    // Vantagens padrão baseadas no nome do plano
    final nomePlano = (plano['nome'] ?? '').toString().toLowerCase();
    
    if (nomePlano.contains('básico') || nomePlano.contains('basico')) {
      return [
        'Acesso à plataforma Vitta',
        'Suporte por email',
        '3 check-ins por semana',
        'Acompanhamento básico'
      ];
    } else if (nomePlano.contains('premium')) {
      return [
        'Todos os recursos do Básico',
        'Suporte prioritário',
        'Check-ins ilimitados',
        'Planos de treino personalizados',
        'Acesso à comunidade'
      ];
    } else if (nomePlano.contains('vip')) {
      return [
        'Todos os recursos do Premium',
        'Mentoria individual',
        'Planos de dieta personalizados',
        'Acesso à comunidade VIP',
        'Suporte 24/7'
      ];
    } else {
      return [
        'Acesso completo à plataforma',
        'Suporte dedicado',
        'Recursos exclusivos',
        'Comunidade de usuários'
      ];
    }
  }
}