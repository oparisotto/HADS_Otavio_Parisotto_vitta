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

  const PlanosScreen({
    Key? key,
    required this.headerCard,
    required this.usuarioId,
    required this.token,
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
      final planoData =
          await ApiService.getPlanoUsuario(widget.usuarioId.toString());

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
      setState(() {
        _errorMessage = 'Erro ao carregar planos: $e';
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    await _carregarTudo();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Planos atualizados com sucesso!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
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
            backgroundColor: Theme.of(context).colorScheme.primary,
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
            backgroundColor: Theme.of(context).colorScheme.primary,
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
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _irParaPagamento(Plano plano) {
    if (_statusPlanoAtual == 'cancelado') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Reative seu plano atual antes de assinar um novo'),
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
    final theme = Theme.of(context);
    final bool isPlanoAtual =
        _planoAtualNome.toLowerCase() == plano.nome.toLowerCase() &&
        _statusPlanoAtual != 'inativo' &&
        _planoAtualNome != 'Sem plano';
    final bool planoCancelado = _statusPlanoAtual == 'cancelado';

    return Card(
      color: theme.cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  plano.nome,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (isPlanoAtual)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: planoCancelado
                          ? theme.colorScheme.errorContainer
                          : theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      planoCancelado ? 'CANCELADO' : 'ATIVO',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: planoCancelado
                            ? theme.colorScheme.onErrorContainer
                            : theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              plano.descricao,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'R\$${plano.preco.toStringAsFixed(2)}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
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
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Reativar Plano'),
                        )
                      : ElevatedButton(
                          onPressed: _cancelarPlano,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.errorContainer,
                            foregroundColor: theme.colorScheme.onErrorContainer,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Cancelar Plano'),
                        )
                  : ElevatedButton(
                      onPressed: () => _irParaPagamento(plano),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
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
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 64),
          const SizedBox(height: 16),
          Text(
            'Ops! Algo deu errado',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            msg ?? _errorMessage,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _refreshData,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: theme.colorScheme.primary),
            )
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Header do usuário
                    HeaderCard(
                      nome: widget.headerCard.nome,
                      plano: _planoAtualNome,
                      status: _statusPlanoAtual,
                      planoAtivo: _statusPlanoAtual == 'ativo',
                      onRefresh: _refreshData,
                    ),
                    const SizedBox(height: 24),

                    // Alerta se plano estiver cancelado
                    if (_statusPlanoAtual == 'cancelado')
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.colorScheme.errorContainer),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Seu plano está cancelado. Reative para fazer check-ins.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Lista de planos
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
                              style: theme.textTheme.bodyMedium,
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
