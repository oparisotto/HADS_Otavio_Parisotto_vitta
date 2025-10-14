import 'package:flutter/material.dart';
import '../models/plano.dart';
import '../services/api_service.dart';
import 'pagamento_screen.dart';

class PlanosScreen extends StatefulWidget {
  final String nomeUsuario;
  final int usuarioId;
  final String token;
  final VoidCallback? onPlanoAtualizado;

  const PlanosScreen({
    super.key,
    required this.nomeUsuario,
    required this.usuarioId,
    required this.token,
    this.onPlanoAtualizado,
  });

  @override
  State<PlanosScreen> createState() => _PlanosScreenState();
}

class _PlanosScreenState extends State<PlanosScreen> {
  late Future<List<Plano>> _planosFuture;
  bool _loading = true;
  String _errorMessage = '';
  String _statusPlanoAtual = 'carregando...';
  String _planoAtualNome = 'Carregando...';
  int? _planoAtualId;

  @override
  void initState() {
    super.initState();
    _carregarDadosUsuario();
    _carregarPlanos();
  }

  // ✅ CORREÇÃO: Carregar dados atualizados do usuário
  Future<void> _carregarDadosUsuario() async {
    try {
      final planoData = await ApiService.getPlanoUsuario(widget.usuarioId.toString());
      
      if (planoData['success'] == true) {
        setState(() {
          _planoAtualNome = planoData['nome_plano'] ?? 'Sem plano';
          _statusPlanoAtual = planoData['status_plano'] ?? 'inativo';
          _planoAtualId = planoData['plano_atual_id']; // ✅ Capturar o ID do plano atual
        });
        print('✅ Dados do plano carregados: $_planoAtualNome - $_statusPlanoAtual - ID: $_planoAtualId');
      } else {
        throw Exception('Erro ao carregar dados do plano');
      }
    } catch (e) {
      print('❌ Erro ao carregar dados do usuário: $e');
      setState(() {
        _planoAtualNome = 'Sem plano';
        _statusPlanoAtual = 'inativo';
        _planoAtualId = null;
      });
    }
  }

  Future<void> _carregarPlanos() async {
    try {
      setState(() {
        _loading = true;
        _errorMessage = '';
      });

      final planos = await ApiService.getPlanosList();
      setState(() {
        _planosFuture = Future.value(planos);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar planos: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  // ✅ MÉTODO PARA CANCELAR PLANO
  Future<void> _cancelarPlano() async {
    try {
      setState(() {
        _loading = true;
      });

      final resultado = await ApiService.cancelarPlanoUsuario(widget.usuarioId);

      if (resultado['success'] == true) {
        setState(() {
          _statusPlanoAtual = 'cancelado';
        });

        widget.onPlanoAtualizado?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              resultado['message'] ?? 'Plano cancelado com sucesso',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        await _carregarDadosUsuario();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado['message'] ?? 'Erro ao cancelar plano'),
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
        _loading = false;
      });
    }
  }

  // ✅ MÉTODO PARA REATIVAR PLANO
  Future<void> _reativarPlano() async {
    try {
      setState(() {
        _loading = true;
      });

      final resultado = await ApiService.reativarPlanoUsuario(widget.usuarioId);

      if (resultado['success'] == true) {
        setState(() {
          _statusPlanoAtual = 'ativo';
        });

        widget.onPlanoAtualizado?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              resultado['message'] ?? 'Plano reativado com sucesso',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        await _carregarDadosUsuario();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado['message'] ?? 'Erro ao reativar plano'),
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
        _loading = false;
      });
    }
  }

  // ✅ DIALOGO DE CONFIRMAÇÃO PARA CANCELAR PLANO
  void _mostrarDialogoCancelamento() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Plano'),
        content: const Text(
          'Tem certeza que deseja cancelar seu plano atual? '
          'Você não poderá fazer check-ins enquanto o plano estiver cancelado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Manter Plano'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelarPlano();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancelar Plano', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ✅ DIALOGO DE CONFIRMAÇÃO PARA REATIVAR PLANO
  void _mostrarDialogoReativacao() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reativar Plano'),
        content: const Text(
          'Deseja reativar seu plano? '
          'Você poderá voltar a fazer check-ins normalmente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Manter Cancelado'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _reativarPlano();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Reativar Plano', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanoCard(Plano plano) {
    // ✅ CORREÇÃO: Lógica simplificada para identificar plano atual
    // Se o usuário tem um plano ativo E o nome do plano atual é igual ao plano do card
    final bool isPlanoAtual = _planoAtualNome.toLowerCase() == plano.nome.toLowerCase() && 
                              _statusPlanoAtual != 'inativo' && 
                              _planoAtualNome != 'Sem plano';
    
    final bool planoCancelado = _statusPlanoAtual == 'cancelado';
    final bool planoAtivo = _statusPlanoAtual == 'ativo';
    final bool semPlano = _planoAtualNome == 'Sem plano';

    print('🔍 Verificando plano: ${plano.nome}');
    print('   Plano atual: $_planoAtualNome');
    print('   Status: $_statusPlanoAtual');
    print('   É plano atual: $isPlanoAtual');

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  plano.nome,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                if (isPlanoAtual)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: planoCancelado ? Colors.red[50] : Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: planoCancelado ? Colors.red : Colors.green,
                      ),
                    ),
                    child: Text(
                      planoCancelado ? 'Plano Cancelado' : 'Plano Atual',
                      style: TextStyle(
                        color: planoCancelado ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              plano.descricao,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'R\$${plano.preco.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                
                // ✅ CORREÇÃO: Lógica simplificada para mostrar botões
                if (isPlanoAtual)
                  // Se é o plano atual, mostra botão de cancelar/reativar
                  _buildBotaoStatusPlano()
                else if (!planoCancelado && (planoAtivo || semPlano || _statusPlanoAtual == 'inativo'))
                  // Se NÃO é plano atual E NÃO está cancelado, mostra botão assinar
                  ElevatedButton(
                    onPressed: () {
                      _irParaPagamento(plano);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text(
                      'Assinar',
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ WIDGET PARA BOTÃO DE CANCELAR/REATIVAR PLANO
  Widget _buildBotaoStatusPlano() {
    final bool planoCancelado = _statusPlanoAtual == 'cancelado';

    if (planoCancelado) {
      return ElevatedButton(
        onPressed: _mostrarDialogoReativacao,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: const Text('Reativar Plano', style: TextStyle(fontSize: 12, color: Colors.white)),
      );
    } else {
      return ElevatedButton(
        onPressed: _mostrarDialogoCancelamento,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: const Text('Cancelar Plano', style: TextStyle(fontSize: 12, color: Colors.white)),
      );
    }
  }

  // ✅ MÉTODO PARA NAVEGAR PARA PAGAMENTO
  void _irParaPagamento(Plano plano) {
    final bool planoCancelado = _statusPlanoAtual == 'cancelado';

    if (planoCancelado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Reative seu plano atual antes de assinar um novo',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    print('🎯 Navegando para tela de pagamento:');
    print('   👤 Usuário: ${widget.nomeUsuario} (ID: ${widget.usuarioId})');
    print('   📋 Plano: ${plano.nome} (ID: ${plano.id})');
    print('   💰 Valor: R\$${plano.preco}');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PagamentoScreen(),
        settings: RouteSettings(
          arguments: {
            'plano': {
              'id': plano.id,
              'nome': plano.nome,
              'descricao': plano.descricao,
              'preco': plano.preco,
            },
            'usuarioId': widget.usuarioId,
            'nomeUsuario': widget.nomeUsuario,
            'token': widget.token,
          },
        ),
      ),
    ).then((_) {
      _carregarDadosUsuario();
      widget.onPlanoAtualizado?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final iniciais = widget.nomeUsuario.isNotEmpty
        ? widget.nomeUsuario
            .trim()
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0] : '')
            .where((element) => element.isNotEmpty)
            .take(2)
            .join()
            .toUpperCase()
        : 'U';

    final bool planoCancelado = _statusPlanoAtual == 'cancelado';
    final bool carregandoDados = _statusPlanoAtual == 'carregando...';

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Planos Disponíveis'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _carregarDadosUsuario();
              _carregarPlanos();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ---------- CABEÇALHO ----------
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: planoCancelado ? Colors.red[700] : Colors.green[700],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Text(
                      iniciais,
                      style: TextStyle(
                        color: planoCancelado ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.nomeUsuario,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _planoAtualNome,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        // ✅ STATUS DO PLANO
                        if (!carregandoDados)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: planoCancelado
                                  ? Colors.red[900]!
                                  : Colors.green[900]!,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _statusPlanoAtual.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white70,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ✅ AVISO SE PLANO ESTIVER CANCELADO
            if (planoCancelado)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[800]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Seu plano está cancelado. Reative para fazer check-ins.',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 10),

            // ---------- LISTA DE PLANOS ----------
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _errorMessage,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  _carregarDadosUsuario();
                                  _carregarPlanos();
                                },
                                child: const Text('Tentar Novamente'),
                              ),
                            ],
                          ),
                        )
                      : FutureBuilder<List<Plano>>(
                          future: _planosFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            } else if (snapshot.hasError) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.error,
                                      color: Colors.red,
                                      size: 50,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Erro: ${snapshot.error}',
                                      style: const TextStyle(color: Colors.red),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _carregarPlanos,
                                      child: const Text('Tentar Novamente'),
                                    ),
                                  ],
                                ),
                              );
                            } else if (!snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              return const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.info, color: Colors.blue, size: 50),
                                    SizedBox(height: 16),
                                    Text('Nenhum plano disponível no momento'),
                                  ],
                                ),
                              );
                            }

                            final planos = snapshot.data!;
                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: planos.length,
                              itemBuilder: (context, index) {
                                final plano = planos[index];
                                return _buildPlanoCard(plano);
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}