import 'dart:async';
import 'package:flutter/material.dart';
import '../models/plano.dart';
import '../services/api_service.dart';
import 'pagamento_screen.dart';
import '../models/header_card.dart';

class PlanosScreen extends StatefulWidget {
  final HeaderCard headerCard;
  final int usuarioId;
  final String token;
  final bool isDarkTheme;

  const PlanosScreen({
    Key? key,
    required this.headerCard,
    required this.usuarioId,
    required this.token,
    required this.isDarkTheme,
  }) : super(key: key);

  @override
  State<PlanosScreen> createState() => _PlanosScreenState();
}

class _PlanosScreenState extends State<PlanosScreen> {
  late Future<List<Plano>> _planosFuture;
  bool _isLoading = true;
  String _errorMessage = '';
  String _planoAtualNome = 'Carregando...';
  String _statusPlanoAtual = 'carregando...';
  int? _planoAtualId;
  bool _isRefreshing = false;

  bool get isDark => widget.isDarkTheme;
  Color get backgroundColor => isDark ? const Color(0xFF121212) : Colors.grey[100]!;
  Color get cardColor => isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get textColor => isDark ? Colors.white70 : Colors.black87;

  @override
  void initState() {
    super.initState();
    _carregarTudo();
  }

  Future<void> _carregarTudo() async {
    setState(() => _isLoading = true);
    await _carregarDadosUsuario();
    await _carregarPlanos();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _carregarDadosUsuario() async {
    try {
      final planoData = await ApiService.getPlanoUsuario(widget.usuarioId.toString());
      if (planoData['success'] == true) {
        setState(() {
          _planoAtualNome = planoData['nome_plano'] ?? 'Sem plano';
          _statusPlanoAtual = planoData['status_plano'] ?? 'inativo';
          _planoAtualId = planoData['plano_atual_id'];
        });
      } else {
        throw Exception('Erro ao carregar dados do plano');
      }
    } catch (e) {
      setState(() {
        _planoAtualNome = 'Sem plano';
        _statusPlanoAtual = 'inativo';
        _planoAtualId = null;
      });
    }
  }

  Future<void> _carregarPlanos() async {
    try {
      final planos = await ApiService.getPlanosList();
      _planosFuture = Future.value(planos);
    } catch (e) {
      setState(() => _errorMessage = 'Erro ao carregar planos: $e');
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    await _carregarTudo();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Planos atualizados com sucesso!'),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    setState(() => _isRefreshing = false);
  }

  Future<void> _cancelarPlano() async {
    setState(() => _isLoading = true);
    try {
      final resultado = await ApiService.cancelarPlanoUsuario(widget.usuarioId);
      if (resultado['success'] == true) {
        setState(() => _statusPlanoAtual = 'cancelado');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado['message'] ?? 'Plano cancelado com sucesso'),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _carregarDadosUsuario();
      } else {
        _mostrarErro(resultado['message'] ?? 'Erro ao cancelar plano');
      }
    } catch (e) {
      _mostrarErro('Erro: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _reativarPlano() async {
    setState(() => _isLoading = true);
    try {
      final resultado = await ApiService.reativarPlanoUsuario(widget.usuarioId);
      if (resultado['success'] == true) {
        setState(() => _statusPlanoAtual = 'ativo');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado['message'] ?? 'Plano reativado com sucesso'),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _carregarDadosUsuario();
      } else {
        _mostrarErro(resultado['message'] ?? 'Erro ao reativar plano');
      }
    } catch (e) {
      _mostrarErro('Erro: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _irParaPagamento(Plano plano) {
    if (_statusPlanoAtual == 'cancelado') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reative seu plano atual antes de assinar um novo'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PagamentoScreen(),
        settings: RouteSettings(arguments: {
          'plano': {
            'id': plano.id,
            'nome': plano.nome,
            'descricao': plano.descricao,
            'preco': plano.preco,
          },
          'usuarioId': widget.usuarioId,
          'nomeUsuario': widget.headerCard.nome,
          'token': widget.token,
        }),
      ),
    ).then((_) => _carregarTudo());
  }

  Widget _buildPlanoCard(Plano plano) {
    final bool isPlanoAtual =
        _planoAtualNome.toLowerCase() == plano.nome.toLowerCase() &&
        _statusPlanoAtual != 'inativo' &&
        _planoAtualNome != 'Sem plano';
    final bool planoCancelado = _statusPlanoAtual == 'cancelado';

    return Card(
      color: cardColor,
      elevation: isDark ? 0 : 3,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nome e status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  plano.nome,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.green[300] : Colors.green[700],
                    fontSize: 18,
                  ),
                ),
                if (isPlanoAtual)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: planoCancelado
                          ? Colors.red[200]
                          : Colors.green[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      planoCancelado ? 'CANCELADO' : 'ATIVO',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: planoCancelado ? Colors.red[800] : Colors.green[800],
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              plano.descricao,
              style: TextStyle(color: textColor),
            ),
            const SizedBox(height: 16),
            Text(
              'R\$${plano.preco.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isDark ? Colors.green[300] : Colors.green[700],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: isPlanoAtual
                  ? _statusPlanoAtual == 'cancelado'
                      ? ElevatedButton(
                          onPressed: _reativarPlano,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.green[300] : Colors.green[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Reativar Plano'),
                        )
                      : ElevatedButton(
                          onPressed: _cancelarPlano,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[200],
                            foregroundColor: Colors.red[800],
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Cancelar Plano'),
                        )
                  : ElevatedButton(
                      onPressed: () => _irParaPagamento(plano),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.green[300] : Colors.green[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Assinar'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _erroWidget([String? msg]) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
          const SizedBox(height: 16),
          Text(
            'Ops! Algo deu errado',
            style: TextStyle(color: textColor, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            msg ?? _errorMessage,
            style: TextStyle(color: textColor.withOpacity(0.7)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _refreshData,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.green[300] : Colors.green[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: isDark ? Colors.green[300] : Colors.green[700]))
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    HeaderCard(
                      nome: widget.headerCard.nome,
                      plano: _planoAtualNome,
                      status: _statusPlanoAtual,
                      planoAtivo: _statusPlanoAtual == 'ativo',
                      onRefresh: _refreshData,
                    ),
                    const SizedBox(height: 24),
                    if (_statusPlanoAtual == 'cancelado')
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red[100]?.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Seu plano está cancelado. Reative para fazer check-ins.',
                                style: TextStyle(color: textColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    FutureBuilder<List<Plano>>(
                      future: _planosFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return _erroWidget(snapshot.error.toString());
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Text(
                              'Nenhum plano disponível',
                              style: TextStyle(color: textColor),
                            ),
                          );
                        }
                        final planos = snapshot.data!;
                        return Column(
                          children: planos.map((p) => _buildPlanoCard(p)).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
