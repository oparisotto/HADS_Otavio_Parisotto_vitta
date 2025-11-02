import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class PagamentoScreen extends StatefulWidget {
  const PagamentoScreen({super.key});

  @override
  State<PagamentoScreen> createState() => _PagamentoScreenState();
}

class _PagamentoScreenState extends State<PagamentoScreen> {
  int? _metodoPagamento;
  bool _loading = false;
  String _message = '';

  // Controllers para cartão de crédito
  final _nomeTitularController = TextEditingController();
  final _numeroCartaoController = TextEditingController();
  final _validadeController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cpfController = TextEditingController();
  final _cepController = TextEditingController();

  // ✅ CORREÇÃO: Variável para armazenar ID do usuário corretamente
  int _usuarioId = 0;
  String _userEmail = '';
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _carregarDadosUsuario();
  }

  // ✅ CORREÇÃO: Carregar dados do usuário corretamente
  Future<void> _carregarDadosUsuario() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioIdStr = prefs.getString('user_id');
      final userEmail = prefs.getString('user_email') ?? '';
      final userName = prefs.getString('user_name') ?? '';

      setState(() {
        _usuarioId = int.tryParse(usuarioIdStr ?? '') ?? 0;
        _userEmail = userEmail;
        _userName = userName;
      });

      print('👤 Dados do usuário carregados:');
      print('   ID: $_usuarioId');
      print('   Nome: $_userName');
      print('   Email: $_userEmail');
      
      if (_usuarioId == 0) {
        print('❌ ERRO CRÍTICO: ID do usuário é 0!');
      }
    } catch (e) {
      print('❌ Erro ao carregar dados do usuário: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    if (args == null) {
      return _buildErrorScreen('Dados da compra não encontrados');
    }

    final plano = args['plano'];
    final nomeUsuario = args['nomeUsuario'] ?? 'Usuário';

    if (plano == null) {
      return _buildErrorScreen('Plano não encontrado');
    }

    final nomePlano = plano['nome'] ?? 'Plano';
    final preco = double.tryParse(plano['preco']?.toString() ?? '0') ?? 0.0;
    final planoId = plano['id'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finalizar Compra'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processando pagamento...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Resumo do Plano
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.workspace_premium, 
                                  color: Colors.amber[700], size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'PLANO ${nomePlano.toUpperCase()}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'R\$${preco.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '/${plano['periodo'] ?? 'mensal'}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // ✅ CORREÇÃO: Mostrar ID do usuário para debug
                          const SizedBox(height: 8),
                          Text(
                            'Usuário: $_userName (ID: $_usuarioId)',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Métodos de Pagamento
                  const Text(
                    'Selecione o método de pagamento:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cartão de Crédito
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: _metodoPagamento == 1 ? Colors.blue : Colors.grey[300]!,
                        width: _metodoPagamento == 1 ? 2 : 1,
                      ),
                    ),
                    child: RadioListTile<int>(
                      title: const Row(
                        children: [
                          Icon(Icons.credit_card, color: Colors.blue, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'Cartão de Crédito',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      subtitle: const Text('Parcelado em até 12x'),
                      value: 1,
                      groupValue: _metodoPagamento,
                      onChanged: (value) {
                        setState(() {
                          _metodoPagamento = value;
                          _message = '';
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // PIX
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: _metodoPagamento == 2 ? Colors.green : Colors.grey[300]!,
                        width: _metodoPagamento == 2 ? 2 : 1,
                      ),
                    ),
                    child: RadioListTile<int>(
                      title: const Row(
                        children: [
                          Icon(Icons.pix, color: Colors.green, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'PIX',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      subtitle: const Text('Pagamento instantâneo'),
                      value: 2,
                      groupValue: _metodoPagamento,
                      onChanged: (value) {
                        setState(() {
                          _metodoPagamento = value;
                          _message = '';
                        });
                      },
                    ),
                  ),

                  // Formulário do Cartão (se selecionado)
                  if (_metodoPagamento == 1) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Dados do Cartão:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nome do Titular
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nome do Titular',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nomeTitularController,
                          decoration: InputDecoration(
                            hintText: 'Nome do titular',
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Número do Cartão
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Número do Cartão',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _numeroCartaoController,
                          decoration: InputDecoration(
                            hintText: 'Número do cartão',
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 19,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Validade e CVV
                    Row(
                      children: [
                        // Validade
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Validade',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _validadeController,
                                decoration: InputDecoration(
                                  hintText: 'MM/AA',
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                maxLength: 5,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // CVV
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'CVV',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _cvvController,
                                decoration: InputDecoration(
                                  hintText: '123',
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                keyboardType: TextInputType.number,
                                obscureText: true,
                                maxLength: 4,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // CPF
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CPF do Titular',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _cpfController,
                          decoration: InputDecoration(
                            hintText: '123.456.789-09',
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 14,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // CEP
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CEP',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _cepController,
                          decoration: InputDecoration(
                            hintText: 'CEP',
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.search),
                              onPressed: _buscarCep,
                              tooltip: 'Buscar endereço pelo CEP',
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 9,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Digite um CEP válido',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Mensagem de erro/sucesso
                  if (_message.isNotEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _message.toLowerCase().contains('sucesso') 
                            ? Colors.green[50] 
                            : Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _message.toLowerCase().contains('sucesso')
                              ? Colors.green 
                              : Colors.red,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _message.toLowerCase().contains('sucesso')
                                ? Icons.check_circle
                                : Icons.error,
                            color: _message.toLowerCase().contains('sucesso')
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _message,
                              style: TextStyle(
                                color: _message.toLowerCase().contains('sucesso')
                                    ? Colors.green[800]
                                    : Colors.red[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Botão Finalizar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      onPressed: _metodoPagamento != null && !_loading 
                          ? _processarPagamento 
                          : null,
                      child: _loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_cart_checkout, 
                                    size: 20),
                                SizedBox(width: 12),
                                Text(
                                  'Finalizar Compra',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  void _buscarCep() {
    final cep = _cepController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cep.length == 8) {
      setState(() {
        _message = 'Busca de CEP implementada aqui';
      });
    } else {
      setState(() {
        _message = 'Digite um CEP válido com 8 dígitos';
      });
    }
  }

  Widget _buildErrorScreen(String message) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Erro'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Voltar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processarPagamento() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) {
      setState(() {
        _message = 'Dados da compra não encontrados';
      });
      return;
    }

    // ✅ CORREÇÃO: Validar ID do usuário ANTES de processar
    if (_usuarioId == 0) {
      setState(() {
        _message = 'Erro: ID do usuário não encontrado. Faça login novamente.';
      });
      return;
    }

    if (_metodoPagamento == null) {
      setState(() {
        _message = 'Selecione um método de pagamento';
      });
      return;
    }

    if (_metodoPagamento == 1) {
      if (!_validarDadosCartao()) {
        return;
      }
    }

    if (_metodoPagamento == 2) {
      if (!_validarDadosPix()) {
        return;
      }
    }

    setState(() {
      _loading = true;
      _message = '';
    });

    try {
      final plano = args['plano'];
      final preco = double.tryParse(plano?['preco']?.toString() ?? '0') ?? 0.0;
      final planoId = plano?['id'] ?? 0;

      print('💰 INICIANDO PROCESSAMENTO DO PAGAMENTO:');
      print('   👤 Usuario ID: $_usuarioId');
      print('   📋 Plano ID: $planoId');
      print('   💰 Valor: R\$ $preco');

      if (_metodoPagamento == 1) {
        await _processarCartao(planoId, preco);
      } else if (_metodoPagamento == 2) {
        await _processarPix(planoId, preco);
      }

    } catch (e) {
      setState(() {
        _message = 'Erro ao processar pagamento: ${e.toString()}';
        _loading = false;
      });
    }
  }

  bool _validarDadosCartao() {
    if (_nomeTitularController.text.isEmpty ||
        _numeroCartaoController.text.isEmpty ||
        _validadeController.text.isEmpty ||
        _cvvController.text.isEmpty ||
        _cpfController.text.isEmpty ||
        _cepController.text.isEmpty) {
      setState(() {
        _message = 'Preencha todos os dados do cartão';
      });
      return false;
    }

    final cep = _cepController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cep.length != 8) {
      setState(() {
        _message = 'CEP deve ter 8 dígitos';
      });
      return false;
    }

    final expiryParts = _validadeController.text.split('/');
    if (expiryParts.length != 2 || 
        expiryParts[0].length != 2 || 
        expiryParts[1].length != 2) {
      setState(() {
        _message = 'Data de validade inválida. Use o formato MM/AA';
      });
      return false;
    }

    final cardNumber = _numeroCartaoController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cardNumber.length != 16) {
      setState(() {
        _message = 'Número do cartão deve ter 16 dígitos';
      });
      return false;
    }

    if (_cvvController.text.length < 3 || _cvvController.text.length > 4) {
      setState(() {
        _message = 'CVV deve ter 3 ou 4 dígitos';
      });
      return false;
    }

    final cpf = _cpfController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cpf.length != 11) {
      setState(() {
        _message = 'CPF deve ter 11 dígitos';
      });
      return false;
    }

    return true;
  }

  bool _validarDadosPix() {
    final cpf = _cpfController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cpf.isEmpty) {
      setState(() {
        _message = 'CPF é obrigatório para pagamento PIX';
      });
      return false;
    }

    if (cpf.length != 11) {
      setState(() {
        _message = 'CPF deve ter 11 dígitos';
      });
      return false;
    }

    return true;
  }

  // ✅ CORREÇÃO: Removido parâmetro usuarioId - usando _usuarioId da classe
  Future<void> _processarCartao(int planoId, double value) async {
    try {
      final cardNumber = _numeroCartaoController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final expiryParts = _validadeController.text.split('/');
      final cpf = _cpfController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final cep = _cepController.text.replaceAll(RegExp(r'[^0-9]'), '');
      
      print('💳 Processando cartão para usuário: $_usuarioId');

      final clienteResult = await ApiService.criarClienteAsaas(
        _userName,
        _userEmail,
        cpf,
      );

      if (!clienteResult['success']) {
        throw Exception(clienteResult['message']);
      }

      final customerId = clienteResult['cliente']['id'];

      final cobrancaResult = await ApiService.criarCobrancaCartao(
        customerId: customerId,
        value: value,
        billingType: 'CREDIT_CARD',
        creditCard: {
          'holderName': _nomeTitularController.text,
          'number': cardNumber,
          'expiryMonth': expiryParts[0],
          'expiryYear': '20${expiryParts[1]}',
          'ccv': _cvvController.text,
        },
        creditCardHolderInfo: {
          'name': _nomeTitularController.text,
          'email': _userEmail,
          'cpfCnpj': cpf,
          'postalCode': cep,
          'addressNumber': '100',
          'addressComplement': '',
          'phone': '41999999999',
          'mobilePhone': '41999999999',
        },
        remoteIp: '177.200.100.1',
      );

      if (!cobrancaResult['success']) {
        throw Exception(cobrancaResult['message']);
      }

      // ✅ CORREÇÃO: Ativar usuário com ID correto
      print('🎯 Ativando usuário após pagamento aprovado...');
      print('   👤 Usuario ID: $_usuarioId');
      
      final ativacaoResult = await ApiService.ativarUsuario(_usuarioId.toString());
      
      if (!ativacaoResult['success']) {
        print('⚠️ Pagamento aprovado mas usuário não foi ativado: ${ativacaoResult['message']}');
      } else {
        print('✅ USUÁRIO ATIVADO COM SUCESSO APÓS PAGAMENTO');
      }

      await _salvarAssinatura(
        planoId, 
        customerId, 
        cobrancaResult['cobranca']['id'], 
        'ACTIVE'
      );
      
    } catch (e) {
      setState(() {
        _message = 'Erro no processamento do cartão: ${e.toString()}';
        _loading = false;
      });
    }
  }

  // ✅ CORREÇÃO: Removido parâmetro usuarioId - usando _usuarioId da classe
  Future<void> _processarPix(int planoId, double value) async {
    try {
      final cpf = _cpfController.text.replaceAll(RegExp(r'[^0-9]'), '');

      print('💰 Processando PIX para usuário: $_usuarioId');

      final clienteResult = await ApiService.criarClienteAsaas(
        _userName,
        _userEmail,
        cpf,
      );

      if (!clienteResult['success']) {
        throw Exception(clienteResult['message']);
      }

      final customerId = clienteResult['cliente']['id'];

      final cobrancaResult = await ApiService.criarCobrancaPix(
        customerId: customerId,
        value: value,
      );

      if (!cobrancaResult['success']) {
        throw Exception(cobrancaResult['message']);
      }

      // ✅ CORREÇÃO: Ativar usuário com ID correto
      print('🎯 Ativando usuário após pagamento PIX...');
      print('   👤 Usuario ID: $_usuarioId');
      
      final ativacaoResult = await ApiService.ativarUsuario(_usuarioId.toString());
      
      if (!ativacaoResult['success']) {
        print('⚠️ Pagamento PIX aprovado mas usuário não foi ativado: ${ativacaoResult['message']}');
      } else {
        print('✅ USUÁRIO ATIVADO COM SUCESSO APÓS PAGAMENTO PIX');
      }

      if (cobrancaResult['cobranca'] != null) {
        _mostrarQrCodePix(cobrancaResult['cobranca']);
      }

      await _salvarAssinatura(
        planoId, 
        customerId,
        cobrancaResult['cobranca']['id'], 
        'PENDING'
      );
      
    } catch (e) {
      setState(() {
        _message = 'Erro no processamento PIX: ${e.toString()}';
        _loading = false;
      });
    }
  }

  // ✅ CORREÇÃO: Removido parâmetro usuarioId - usando _usuarioId da classe
  Future<void> _salvarAssinatura(int planoId, String customerId, 
    String subscriptionId, String status) async {
  try {
    print('💾 Salvando assinatura no banco...');
    print('👤 Usuario ID: $_usuarioId');
    print('📋 Plano ID: $planoId');
    print('📄 Subscription ID: $subscriptionId');
    print('📊 Status: $status');

    final assinaturaResult = await ApiService.salvarAssinatura(
      usuarioId: _usuarioId, // ✅ CORREÇÃO: Usando _usuarioId
      planoId: planoId,
      customerId: customerId,
      subscriptionId: subscriptionId,
      status: status,
    );

    if (!assinaturaResult['success']) {
      print('⚠️ Assinatura não foi salva no banco: ${assinaturaResult['message']}');
      // Continua o fluxo mesmo se não salvar a assinatura
    } else {
      print('✅ Assinatura salva com sucesso no banco');
    }

    _finalizarCompra();
      
  } catch (e) {
    print('❌ Erro ao salvar assinatura: $e');
    // Continua o fluxo mesmo com erro
    _finalizarCompra();
  }
}

  void _mostrarQrCodePix(Map<String, dynamic> cobranca) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.pix, color: Colors.green),
            SizedBox(width: 8),
            Text('Pagamento PIX'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Escaneie o QR Code para pagar:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code, size: 80, color: Colors.grey[600]),
                    const SizedBox(height: 8),
                    Text(
                      'QR Code PIX',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Ou copie o código PIX:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SelectableText(
                  cobranca['payload'] ?? cobranca['pixCode'] ?? 'CODIGO_PIX_${DateTime.now().millisecondsSinceEpoch}',
                  style: const TextStyle(
                    fontFamily: 'Monospace',
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Este código expira em 30 minutos',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Copiar Código'),
          ),
        ],
      ),
    );
  }

  void _finalizarCompra() {
    setState(() {
      _loading = false;
      _message = 'Pagamento processado com sucesso!';
    });

    Future.delayed(const Duration(seconds: 2), () async {
      print('🏠 Redirecionando para home com usuário: $_userName (ID: $_usuarioId)');

      Navigator.pushReplacementNamed(
        context,
        '/home',
        arguments: {
          'nomeUsuario': _userName,
          'usuarioId': _usuarioId,
          'userEmail': _userEmail,
        },
      );
    });
  }

  @override
  void dispose() {
    _nomeTitularController.dispose();
    _numeroCartaoController.dispose();
    _validadeController.dispose();
    _cvvController.dispose();
    _cpfController.dispose();
    _cepController.dispose();
    super.dispose();
  }
}