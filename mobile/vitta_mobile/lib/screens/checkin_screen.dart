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
  Map<String, dynamic> _planoData = {'nome_plano': 'Carregando...', 'status_plano': 'carregando'};
  Map<String, int> _checkinStats = {'diarios': 0, 'semanais': 0, 'mensais': 0};
  bool _isLoading = true;
  bool _isMakingCheckin = false;
  bool _planoAtivo = false;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _startPlanoUpdateListener();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startPlanoUpdateListener() {
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _updatePlanoRealTime();
    });
  }

  Future<void> _updatePlanoRealTime() async {
    try {
      final planoAtualizado = await ApiService.getPlanoUsuario(widget.usuarioId.toString());
      if (planoAtualizado['success'] == true) {
        final novoNome = planoAtualizado['nome_plano'] ?? 'Sem plano';
        final novoStatus = planoAtualizado['status_plano'] ?? 'inativo';

        if (novoNome != _planoData['nome_plano'] || novoStatus != _planoData['status_plano']) {
          setState(() {
            _planoData = {'nome_plano': novoNome, 'status_plano': novoStatus};
            _planoAtivo = novoStatus == 'ativo';
          });

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_plano', novoNome);
          await prefs.setString('user_status_plano', novoStatus);
        }
      }
    } catch (e) {
      debugPrint('❌ Erro ao atualizar plano em tempo real: $e');
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
      final plano = await ApiService.getPlanoUsuario(widget.usuarioId.toString());
      if (plano['success'] == true) {
        final nome = plano['nome_plano'] ?? 'Sem plano';
        final status = plano['status_plano'] ?? 'inativo';
        setState(() {
          _planoData = {'nome_plano': nome, 'status_plano': status};
          _planoAtivo = status == 'ativo';
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_plano', nome);
        await prefs.setString('user_status_plano', status);
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
      debugPrint('❌ Erro ao carregar estatísticas de check-in: $e');
    }
  }

  Future<void> _refreshAllData() async {
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
          backgroundColor: Colors.redAccent,
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
            content: Text(response['message'] ?? 'Check-in realizado com sucesso! 🎉'),
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
              onRefresh: _refreshAllData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HeaderCard(
                      nome: _userData['nome'] ?? 'Usuário',
                      plano: _planoData['nome_plano'] ?? 'Sem plano',
                      status: _planoData['status_plano'] ?? 'inativo',
                      planoAtivo: _planoAtivo,
                      onRefresh: _refreshAllData,
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
                        _buildStatCard('Hoje', _checkinStats['diarios']!, Colors.blue),
                        _buildStatCard('Semana', _checkinStats['semanais']!, Colors.orange),
                        _buildStatCard('Mês', _checkinStats['mensais']!, Colors.purple),
                      ],
                    ),
                    const SizedBox(height: 40),
                    if (!_planoAtivo) _planoInativoBanner(),
                    const SizedBox(height: 30),
                    Center(
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isMakingCheckin || !_planoAtivo ? null : _realizarCheckin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _planoAtivo
                                ? (isDark ? Colors.green[700] : Colors.green)
                                : (isDark ? Colors.grey[800] : Colors.grey[400]),
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
                              : Text(
                                  'FAZER CHECK-IN',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: _planoAtivo ? Colors.white : Colors.white70,
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

  Widget _planoInativoBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.redAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Seu plano não está ativo. Reative para realizar check-ins.',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
            Text(
              title,
              style: TextStyle(color: textColor.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }
}
