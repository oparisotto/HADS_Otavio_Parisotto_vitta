import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitta_mobile/services/api_service.dart';
import 'checkin_screen.dart';
import 'planos_screen.dart';

class HomeScreen extends StatefulWidget {
  final String nomeUsuario;
  final int usuarioId;
  final String token;

  const HomeScreen({
    super.key,
    required this.nomeUsuario,
    required this.usuarioId,
    required this.token,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int currentIndex = 1;
  late final AnimationController animationController;
  String _planoUsuario = 'Carregando...';
  String _statusPlano = 'Carregando...';
  bool _loadingPlano = true;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _carregarDadosUsuario();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  Future<void> _carregarDadosUsuario() async {
    try {
      setState(() {
        _loadingPlano = true;
      });

      // ✅ CORREÇÃO: Buscar dados atualizados da API
      final planoData = await ApiService.getPlanoUsuario(widget.usuarioId.toString());
      
      if (planoData['success'] == true) {
        final planoNome = planoData['nome_plano'] ?? 'Sem plano';
        final statusPlano = planoData['status_plano'] ?? 'inativo';
        
        // ✅ CORREÇÃO: Salvar no SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_plano', planoNome);
        await prefs.setString('user_status_plano', statusPlano);
        await prefs.setInt('current_user_id', widget.usuarioId);
        await prefs.setString('current_user_name', widget.nomeUsuario);
        await prefs.setString('user_token', widget.token);

        setState(() {
          _planoUsuario = planoNome;
          _statusPlano = statusPlano;
          _loadingPlano = false;
        });
        
        print('✅ Dados do usuário carregados: $planoNome - $statusPlano');
      } else {
        throw Exception('Erro ao carregar plano');
      }
    } catch (e) {
      print('❌ Erro ao carregar dados do usuário: $e');
      
      // ✅ CORREÇÃO: Tentar carregar do cache em caso de erro
      final prefs = await SharedPreferences.getInstance();
      final cachedPlano = prefs.getString('user_plano') ?? 'Sem plano';
      final cachedStatus = prefs.getString('user_status_plano') ?? 'inativo';
      
      setState(() {
        _planoUsuario = cachedPlano;
        _statusPlano = cachedStatus;
        _loadingPlano = false;
      });
    }
  }

  void _atualizarDadosUsuario() async {
    await _carregarDadosUsuario();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Dados atualizados! Plano: $_planoUsuario - Status: $_statusPlano'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _limparDadosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_plano');
    await prefs.remove('user_status_plano');
    await prefs.remove('current_user_id');
    await prefs.remove('current_user_name');
    await prefs.remove('user_token');
    
    print('✅ Dados do usuário limpos');
  }

  void onTabTapped(int index) {
    setState(() {
      currentIndex = index;
      animationController.forward(from: 0);
    });
  }

  Future<void> _sair() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sair'),
          content: const Text('Tem certeza que deseja sair?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _limparDadosUsuario();
                Navigator.of(context).pushReplacementNamed('/login');
              },
              child: const Text('Sair', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final nome = widget.nomeUsuario;
    final iniciais = nome.isNotEmpty
        ? nome.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'U';

    final List<Widget> telas = [
      CheckinScreen(usuarioId: widget.usuarioId),
      _homeBody(nome, iniciais),
      PlanosScreen(
        nomeUsuario: widget.nomeUsuario,
        usuarioId: widget.usuarioId,
        token: widget.token,
        onPlanoAtualizado: _carregarDadosUsuario,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Vitta Mobile'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _sair,
            tooltip: 'Sair',
          ),
        ],
      ),
      body: telas[currentIndex],
      bottomNavigationBar: _footer(),
    );
  }

  Widget _homeBody(String nome, String iniciais) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 0, left: 16, right: 16, bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header do usuário
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.green[700],
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
                      style: const TextStyle(
                        color: Colors.green,
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
                          nome,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _loadingPlano
                            ? const Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Carregando plano...',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Plano: $_planoUsuario',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Status: $_statusPlano',
                                    style: TextStyle(
                                      color: _statusPlano == 'ativo' 
                                          ? Colors.green[100] 
                                          : Colors.orange[100],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: ${widget.usuarioId}',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: _atualizarDadosUsuario,
                    tooltip: 'Atualizar dados',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Barra de busca
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(15),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: "Buscar academias, estúdios, cidades...",
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Dica do dia
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.fitness_center, color: Colors.green, size: 40),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Dica do dia: 30 minutos de exercícios físicos por dia aumentam sua energia e melhoram seu humor! 💪",
                      style: TextStyle(color: Colors.grey[800], fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Academias perto de você
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Mais perto de você",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 18),
                  onPressed: () {},
                ),
              ],
            ),
            SizedBox(
              height: 140,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _academiaCard("26 Fit", "assets/images/gym1.jpg"),
                  _academiaCard("Malhação", "assets/images/gym2.jpeg"),
                  _academiaCard("Attivita", "assets/images/gym3.jpeg"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _academiaCard(String nome, String imagem) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      margin: const EdgeInsets.only(right: 12),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          image: const DecorationImage(
            image: AssetImage('assets/images/gym1.jpg'), // Placeholder
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black,
              BlendMode.darken,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              nome,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _footer() {
    return Container(
      height: 75,
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, -2),
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _FooterButton(
            icon: Icons.check_circle_outline,
            label: 'Check-in',
            selected: currentIndex == 0,
            onTap: () => onTabTapped(0),
          ),
          _FooterButton(
            icon: Icons.home_outlined,
            label: 'Home',
            selected: currentIndex == 1,
            onTap: () => onTabTapped(1),
          ),
          _FooterButton(
            icon: Icons.attach_money_rounded,
            label: 'Planos',
            selected: currentIndex == 2,
            onTap: () => onTabTapped(2),
          ),
        ],
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FooterButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? Colors.green[700] : Colors.transparent,
      ),
      padding: const EdgeInsets.all(10),
      child: IconButton(
        icon: Icon(icon, color: selected ? Colors.white : Colors.grey[700], size: 28),
        onPressed: onTap,
      ),
    );
  }
}