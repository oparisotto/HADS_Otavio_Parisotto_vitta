import 'package:flutter/material.dart';
import '../models/plano.dart';
import '../services/api_service.dart';
import 'checkin_screen.dart';
import 'home_screen.dart';
import 'pagamento_screen.dart';

class PlanosScreen extends StatefulWidget {
  final String nomeUsuario;
  final String planoUsuario;
  final int usuarioId;
  final String? statusPlano; // ✅ ADICIONAR STATUS DO PLANO

  const PlanosScreen({
    super.key,
    required this.nomeUsuario,
    required this.planoUsuario,
    required this.usuarioId,
    this.statusPlano, // ✅ STATUS DO PLANO (pago, pendente, cancelado, etc)
  });

  @override
  State<PlanosScreen> createState() => _PlanosScreenState();
}

class _PlanosScreenState extends State<PlanosScreen> {
  late Future<List<Plano>> _planosFuture;
  bool _loading = true;
  String _errorMessage = '';
  String _statusPlanoAtual = 'ativo'; // ✅ STATUS DO PLANO ATUAL

  @override
  void initState() {
    super.initState();
    _carregarPlanos();
    _carregarStatusPlano(); // ✅ CARREGAR STATUS DO PLANO
  }

  // ✅ ADICIONAR MÉTODO PARA CARREGAR STATUS DO PLANO
  Future<void> _carregarStatusPlano() async {
    try {
      final resultado = await ApiService.verificarStatusPlano(widget.usuarioId);
      if (resultado['success'] == true) {
        setState(() {
          _statusPlanoAtual = resultado['status_plano'];
        });
        print('📊 Status do plano carregado: $_statusPlanoAtual');
      }
    } catch (e) {
      print('❌ Erro ao carregar status do plano: $e');
      // Em caso de erro, assumir ativo
      setState(() {
        _statusPlanoAtual = 'ativo';
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

      // Chamar API para cancelar plano
      final resultado = await ApiService.cancelarPlanoUsuario(widget.usuarioId);

      if (resultado['success'] == true) {
        // Atualizar status localmente
        setState(() {
          _statusPlanoAtual = 'cancelado';
        });

        // Mostrar mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              resultado['message'] ?? 'Plano cancelado com sucesso',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Recarregar dados
        _carregarPlanos();
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

      // Chamar API para reativar plano
      final resultado = await ApiService.reativarPlanoUsuario(widget.usuarioId);

      if (resultado['success'] == true) {
        // Atualizar status localmente
        setState(() {
          _statusPlanoAtual = 'ativo';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              resultado['message'] ?? 'Plano reativado com sucesso',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Recarregar dados
        _carregarPlanos();
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
            child: const Text('Cancelar Plano'),
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
            child: const Text('Reativar Plano'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanoCard(Plano plano) {
    final bool isPlanoAtual =
        plano.nome.toLowerCase() == widget.planoUsuario.toLowerCase();
    final bool planoCancelado = _statusPlanoAtual == 'cancelado';

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
                if (isPlanoAtual)
                  // ✅ BOTÃO PARA CANCELAR/REATIVAR PLANO ATUAL
                  _buildBotaoStatusPlano()
                else if (!planoCancelado)
                  // ✅ BOTÃO PARA ASSINAR OUTRO PLANO (apenas se não estiver cancelado)
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
                      style: TextStyle(fontSize: 12),
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
      // BOTÃO PARA REATIVAR PLANO CANCELADO
      return ElevatedButton(
        onPressed: _mostrarDialogoReativacao,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: const Text('Reativar Plano', style: TextStyle(fontSize: 12)),
      );
    } else {
      // BOTÃO PARA CANCELAR PLANO ATIVO
      return ElevatedButton(
        onPressed: _mostrarDialogoCancelamento,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: const Text('Cancelar Plano', style: TextStyle(fontSize: 12)),
      );
    }
  }

  // ✅ MÉTODO PARA NAVEGAR PARA PAGAMENTO
  void _irParaPagamento(Plano plano) {
    final bool planoCancelado = _statusPlanoAtual == 'cancelado';

    if (planoCancelado) {
      // ❌ IMPEDIR ASSINATURA SE PLANO ESTIVER CANCELADO
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
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
          },
        ),
      ),
    );
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

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Planos Disponíveis'),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarPlanos,
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
                          widget.planoUsuario,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        // ✅ STATUS DO PLANO
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: planoCancelado
                                ? Colors.red[900]
                                : Colors.green[900],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            planoCancelado ? 'PLANO CANCELADO' : 'PLANO ATIVO',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
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
                            onPressed: _carregarPlanos,
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
