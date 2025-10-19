import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/header_card.dart';

class CheckinScreen extends StatefulWidget {
  final int usuarioId;
  final bool isDarkTheme;

  const CheckinScreen({
    Key? key,
    required this.usuarioId,
    required this.isDarkTheme,
  }) : super(key: key);

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  Map<String, dynamic> _userData = {};
  Map<String, dynamic> _planoData = {
    'nome_plano': 'Carregando...',
    'status_plano': 'carregando',
  };
  Map<String, int> _checkinStats = {'diarios': 0, 'semanais': 0, 'mensais': 0};
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
      if (mounted) _carregarPlanoAtualizado();
    });
  }

  Future<void> _carregarPlanoAtualizado() async {
    try {
      final planoAtualizado = await ApiService.getPlanoUsuario(
        widget.usuarioId.toString(),
      );
      if (planoAtualizado['success'] == true) {
        final novoNomePlano = planoAtualizado['nome_plano'] ?? 'Sem plano';
        final novoStatusPlano = planoAtualizado['status_plano'] ?? 'inativo';

        if (novoNomePlano != _planoData['nome_plano'] ||
            novoStatusPlano != _planoData['status_plano']) {
          setState(() {
            _planoData = {
              'nome_plano': novoNomePlano,
              'status_plano': novoStatusPlano,
            };
            _planoAtivo = novoStatusPlano == 'ativo';
          });

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_plano', novoNomePlano);
          await prefs.setString('user_status_plano', novoStatusPlano);
        }
      }
    } catch (e) {
      debugPrint('❌ Erro ao verificar atualização do plano: $e');
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    await _loadUserData();
    await _loadPlanoData();
    await _loadCheckinStats();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('current_user_name') ?? 'Usuário';
      final userEmail = prefs.getString('current_user_email') ?? '';
      setState(() => _userData = {'nome': userName, 'email': userEmail});
    } catch (e) {
      debugPrint('❌ Erro ao carregar dados do usuário: $e');
    }
  }

  Future<void> _loadPlanoData() async {
    try {
      final planoData = await ApiService.getPlanoUsuario(
        widget.usuarioId.toString(),
      );
      if (planoData['success'] == true) {
        final nomePlano = planoData['nome_plano'] ?? 'Sem plano';
        final statusPlano = planoData['status_plano'] ?? 'inativo';
        setState(() {
          _planoData = {'nome_plano': nomePlano, 'status_plano': statusPlano};
          _planoAtivo = statusPlano == 'ativo';
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_plano', nomePlano);
        await prefs.setString('user_status_plano', statusPlano);
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar plano: $e');
    }
  }

  Future<void> _loadCheckinStats() async {
    try {
      final stats = await ApiService.getCheckinStats(widget.usuarioId);
      setState(() => _checkinStats = stats);
    } catch (e) {
      debugPrint('❌ Erro ao carregar estatísticas: $e');
    }
  }

  Future<void> _recarregarTodosDados() async {
    await _loadInitialData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dados atualizados com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _realizarCheckin() async {
    if (!_planoAtivo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plano inativo. Reative para fazer check-ins.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isMakingCheckin = true);
    try {
      final response = await ApiService.realizarCheckin(widget.usuarioId);
      if (response['success'] == true) {
        await _loadCheckinStats();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'Check-in realizado com sucesso! 🎉',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Erro ao realizar check-in.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro de conexão: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isMakingCheckin = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkTheme;
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.grey[100];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _recarregarTodosDados,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Usa o HeaderCard da pasta models
                    HeaderCard(
                      nome: _userData['nome'] ?? 'Usuário',
                      plano: _planoData['nome_plano'] ?? 'Sem plano',
                      status: _planoData['status_plano'] ?? 'inativo',
                      planoAtivo: _planoAtivo,
                      onRefresh: _recarregarTodosDados,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Estatísticas de Check-in',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatCard(
                          'Hoje',
                          _checkinStats['diarios']!,
                          Colors.blue,
                        ),
                        _buildStatCard(
                          'Semana',
                          _checkinStats['semanais']!,
                          Colors.orange,
                        ),
                        _buildStatCard(
                          'Mês',
                          _checkinStats['mensais']!,
                          Colors.purple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    if (!_planoAtivo)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Seu plano não está ativo. Reative para realizar check-ins.',
                                style: TextStyle(
                                  color: Colors.orange[900],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 30),
                    Center(
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isMakingCheckin || !_planoAtivo
                              ? null
                              : _realizarCheckin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isDark ? Colors.green[700] : Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isMakingCheckin
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'FAZER CHECK-IN',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, int value, Color color) {
    final isDark = widget.isDarkTheme;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Expanded(
      child: Container(
        height: 100,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 5),
            Text(title, style: TextStyle(color: textColor.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }
}
