import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class CheckinScreen extends StatefulWidget {
  const CheckinScreen({Key? key}) : super(key: key);

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  Map<String, dynamic> _userData = {};
  Map<String, dynamic> _planoData = {'nome_plano': 'Sem plano'};
  Map<String, int> _checkinStats = {
    'diarios': 0,
    'semanais': 0,
    'mensais': 0,
  };
  bool _isLoading = true;
  bool _isMakingCheckin = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    
    // 🔄 CONFIGURAR LISTENER PARA ATUALIZAÇÕES
    _setupUpdateListener();
  }

  // 🔄 LISTENER PARA ATUALIZAÇÕES DO PLANO
  void _setupUpdateListener() {
    // Usar um timer para verificar atualizações periodicamente
    Timer.periodic(Duration(seconds: 30), (timer) {
      if (mounted) {
        _carregarPlanoAtualizado();
      }
    });
  }

  // 🔄 CARREGAR PLANO ATUALIZADO
  Future<void> _carregarPlanoAtualizado() async {
    try {
      print('🔄 Verificando atualização do plano...');
      final planoAtualizado = await ApiService.getUserPlano();
      
      if (planoAtualizado['nome_plano'] != _planoData['nome_plano']) {
        print('✅ Plano atualizado detectado: ${planoAtualizado['nome_plano']}');
        
        setState(() {
          _planoData = planoAtualizado;
        });
        
        // 🔄 ATUALIZAR SHARED PREFERENCES TAMBÉM
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_plano', planoAtualizado['nome_plano'] ?? 'Sem plano');
      }
    } catch (e) {
      print('❌ Erro ao verificar atualização do plano: $e');
    }
  }

  Future<void> _loadInitialData() async {
    await _loadUserData();
    await _loadPlanoData();
    await _loadCheckinStats();
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await ApiService.getUserProfile();
      setState(() {
        _userData = userData;
      });
    } catch (e) {
      print('Erro ao carregar dados do usuário: $e');
    }
  }

  Future<void> _loadPlanoData() async {
    try {
      final planoData = await ApiService.getUserPlano();
      setState(() {
        _planoData = planoData;
      });
      print('📋 Plano carregado: ${planoData['nome_plano']}');
    } catch (e) {
      print('Erro ao carregar dados do plano: $e');
    }
  }

  Future<void> _loadCheckinStats() async {
    try {
      final stats = await ApiService.getCheckinStats();
      setState(() {
        _checkinStats = stats;
      });
    } catch (e) {
      print('Erro ao carregar estatísticas: $e');
    }
  }

  // 🔄 MÉTODO PARA RECARREGAR TODOS OS DADOS
  Future<void> _recarregarTodosDados() async {
    setState(() {
      _isLoading = true;
    });
    
    await _loadUserData();
    await _loadPlanoData();
    await _loadCheckinStats();
    
    setState(() {
      _isLoading = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Dados atualizados!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _realizarCheckin() async {
    setState(() {
      _isMakingCheckin = true;
    });

    try {
      final response = await ApiService.realizarCheckin();
      
      if (response['success'] == true) {
        // Atualiza as estatísticas
        await _loadCheckinStats();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Check-in realizado com sucesso!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Erro ao realizar check-in'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isMakingCheckin = false;
      });
    }
  }

  String _getIniciais(String nome) {
    if (nome.isEmpty) return 'U';
    
    List<String> partes = nome.split(' ');
    if (partes.length >= 2) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }
    return nome.length >= 2 ? nome.substring(0, 2).toUpperCase() : nome.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Check-in'),
        backgroundColor: Colors.green[700],
        actions: [
          // 🔄 BOTÃO PARA ATUALIZAR MANUALMENTE
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoading ? null : _recarregarTodosDados,
            tooltip: 'Atualizar dados',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Carregando...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Header com foto do usuário
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.green[700]!, Colors.green[500]!],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                    child: Row(
                      children: [
                        // Avatar com iniciais
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _getIniciais(_userData['nome'] ?? ''),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        // Nome e plano
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _userData['nome'] ?? 'Usuário',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _planoData['nome_plano'] ?? 'Sem plano',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    // 🔄 INDICADOR DE PLANO ATIVO
                                    if (_planoData['nome_plano'] != 'Sem plano')
                                      Icon(Icons.check_circle, size: 12, color: Colors.white),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Informações sobre checkins
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Check-in',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Faça seu check-in diário e acompanhe suas estatísticas',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Cards de estatísticas
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _buildStatCard('Diários', _checkinStats['diarios']!, Colors.blue),
                      const SizedBox(width: 10),
                      _buildStatCard('Semanas', _checkinStats['semanais']!, Colors.orange),
                      const SizedBox(width: 10),
                      _buildStatCard('Mensais', _checkinStats['mensais']!, Colors.purple),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // 🔄 INDICADOR DE ATUALIZAÇÃO AUTOMÁTICA
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[100]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.sync, size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Dados atualizados automaticamente',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Botão de check-in
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: _isMakingCheckin
                        ? ElevatedButton(
                            onPressed: null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'PROCESSANDO...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ElevatedButton(
                            onPressed: _realizarCheckin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'CHECK-IN',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String title, int value, Color color) {
    return Expanded(
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}