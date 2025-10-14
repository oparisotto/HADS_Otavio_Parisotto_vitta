import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class CheckinScreen extends StatefulWidget {
  final int usuarioId;

  const CheckinScreen({Key? key, required this.usuarioId}) : super(key: key);

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  Map<String, dynamic> _userData = {};
  Map<String, dynamic> _planoData = {'nome_plano': 'Carregando...', 'status_plano': 'carregando'};
  Map<String, int> _checkinStats = {
    'diarios': 0,
    'semanais': 0,
    'mensais': 0,
  };
  bool _isLoading = true;
  bool _isMakingCheckin = false;
  Timer? _updateTimer;
  bool _planoAtivo = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _setupUpdateListener();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _setupUpdateListener() {
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _carregarPlanoAtualizado();
      }
    });
  }

  Future<void> _carregarPlanoAtualizado() async {
    try {
      final planoAtualizado = await ApiService.getPlanoUsuario(widget.usuarioId.toString());
      
      if (planoAtualizado['success'] == true) {
        final novoNomePlano = planoAtualizado['nome_plano'] ?? 'Sem plano';
        final novoStatusPlano = planoAtualizado['status_plano'] ?? 'inativo';
        
        if (novoNomePlano != _planoData['nome_plano'] || novoStatusPlano != _planoData['status_plano']) {
          setState(() {
            _planoData = {
              'nome_plano': novoNomePlano,
              'status_plano': novoStatusPlano
            };
            _planoAtivo = novoStatusPlano == 'ativo';
          });
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_plano', novoNomePlano);
          await prefs.setString('user_status_plano', novoStatusPlano);
        }
      }
    } catch (e) {
      print('❌ Erro ao verificar atualização do plano: $e');
    }
  }

  Future<void> _loadInitialData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _loadUserData();
      await _loadPlanoData();
      await _loadCheckinStats();
      
    } catch (e) {
      print('❌ Erro ao carregar dados iniciais: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('current_user_name') ?? 'Usuário';
      final userEmail = prefs.getString('current_user_email') ?? '';
      
      setState(() {
        _userData = {
          'nome': userName,
          'email': userEmail,
        };
      });
    } catch (e) {
      print('❌ Erro ao carregar dados do usuário: $e');
      setState(() {
        _userData = {'nome': 'Usuário', 'email': ''};
      });
    }
  }

  Future<void> _loadPlanoData() async {
    try {
      final planoData = await ApiService.getPlanoUsuario(widget.usuarioId.toString());
      
      if (planoData['success'] == true) {
        final nomePlano = planoData['nome_plano'] ?? 'Sem plano';
        final statusPlano = planoData['status_plano'] ?? 'inativo';
        
        setState(() {
          _planoData = {
            'nome_plano': nomePlano,
            'status_plano': statusPlano
          };
          _planoAtivo = statusPlano == 'ativo';
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_plano', nomePlano);
        await prefs.setString('user_status_plano', statusPlano);
        
        print('✅ Plano carregado: $nomePlano - Status: $statusPlano');
      } else {
        throw Exception('Erro ao carregar dados do plano');
      }
    } catch (e) {
      print('❌ Erro ao carregar dados do plano: $e');
      
      final prefs = await SharedPreferences.getInstance();
      final cachedPlano = prefs.getString('user_plano') ?? 'Sem plano';
      final cachedStatus = prefs.getString('user_status_plano') ?? 'inativo';
      
      setState(() {
        _planoData = {
          'nome_plano': cachedPlano,
          'status_plano': cachedStatus
        };
        _planoAtivo = cachedStatus == 'ativo';
      });
    }
  }

  Future<void> _loadCheckinStats() async {
    try {
      final stats = await ApiService.getCheckinStats(widget.usuarioId);
      setState(() {
        _checkinStats = stats;
      });
    } catch (e) {
      print('❌ Erro ao carregar estatísticas: $e');
      setState(() {
        _checkinStats = {'diarios': 0, 'semanais': 0, 'mensais': 0};
      });
    }
  }

  Future<void> _recarregarTodosDados() async {
    setState(() {
      _isLoading = true;
    });
    
    await _loadUserData();
    await _loadPlanoData();
    await _loadCheckinStats();
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dados atualizados!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _realizarCheckin() async {
    if (!_planoAtivo) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _planoData['status_plano'] == 'cancelado' 
                ? 'Seu plano está cancelado. Reative para fazer check-ins.'
                : 'Seu plano não está ativo. Entre em contato com o suporte.',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isMakingCheckin = true;
    });

    try {
      final response = await ApiService.realizarCheckin(widget.usuarioId);
      
      if (response['success'] == true) {
        await _loadCheckinStats();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Check-in realizado com sucesso! 🎉'),
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
          content: Text('Erro de conexão: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isMakingCheckin = false;
        });
      }
    }
  }

  String _getIniciais(String nome) {
    if (nome.isEmpty) return 'U';
    
    final partes = nome.trim().split(' ');
    if (partes.length >= 2) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }
    return nome.length >= 2 ? nome.substring(0, 2).toUpperCase() : nome.toUpperCase();
  }

  Widget _buildStatusPlano() {
    final status = _planoData['status_plano'] ?? 'inativo';
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (status) {
      case 'ativo':
        statusColor = Colors.green;
        statusText = 'PLANO ATIVO';
        statusIcon = Icons.check_circle;
        break;
      case 'cancelado':
        statusColor = Colors.red;
        statusText = 'PLANO CANCELADO';
        statusIcon = Icons.warning;
        break;
      case 'inativo':
      default:
        statusColor = Colors.orange;
        statusText = 'PLANO INATIVO';
        statusIcon = Icons.warning;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 12,
            color: statusColor,
          ),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Check-in'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _recarregarTodosDados,
            tooltip: 'Atualizar dados',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Carregando...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : SafeArea(
              child: Column(
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
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _getIniciais(_userData['nome'] ?? ''),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700]!,
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
                                Text(
                                  _planoData['nome_plano'] ?? 'Sem plano',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                _buildStatusPlano(),
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
                        _buildStatCard('Hoje', _checkinStats['diarios']!, Colors.blue),
                        const SizedBox(width: 10),
                        _buildStatCard('Esta Semana', _checkinStats['semanais']!, Colors.orange),
                        const SizedBox(width: 10),
                        _buildStatCard('Este Mês', _checkinStats['mensais']!, Colors.purple),
                      ],
                    ),
                  ),
                  
                  // AVISO SE PLANO NÃO ESTIVER ATIVO
                  if (!_planoAtivo)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange[800]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _planoData['status_plano'] == 'cancelado'
                                    ? 'Seu plano está cancelado. Reative para fazer check-ins.'
                                    : 'Seu plano não está ativo. Entre em contato com o suporte.',
                                style: TextStyle(
                                  color: Colors.orange[800],
                                  fontWeight: FontWeight.w500,
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
                              child: const Row(
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
                                  SizedBox(width: 10),
                                  Text(
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
                              onPressed: _planoAtivo ? _realizarCheckin : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _planoAtivo ? Colors.green[700] : Colors.grey[400],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: Text(
                                _planoAtivo ? 'FAZER CHECK-IN' : 'PLANO NÃO ATIVO',
                                style: const TextStyle(
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
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
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
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}