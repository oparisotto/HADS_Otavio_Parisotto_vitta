import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitta_mobile/services/api_service.dart';
import 'checkin_screen.dart';
import 'planos_screen.dart';
import '../models/header_card.dart';

class HomeScreen extends StatefulWidget {
  final String nomeUsuario;
  final int usuarioId;
  final String token;
  final bool isDarkTheme;
  final VoidCallback onToggleTheme;

  const HomeScreen({
    super.key,
    required this.nomeUsuario,
    required this.usuarioId,
    required this.token,
    required this.isDarkTheme,
    required this.onToggleTheme,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int currentIndex = 1;
  late final AnimationController animationController;
  String _planoUsuario = 'Carregando...';
  String _statusPlano = 'Carregando...';
  bool _loadingPlano = true;
  bool _isDarkTheme = false;
  Timer? _realTimeTimer;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _carregarTema();
    _carregarDadosUsuario();
    _startRealTimePlanoUpdate();
  }

  @override
  void dispose() {
    animationController.dispose();
    _realTimeTimer?.cancel();
    super.dispose();
  }

  void _startRealTimePlanoUpdate() {
    // Atualiza a cada 5 segundos
    _realTimeTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _atualizarPlanoSeNecessario();
    });
  }

  Future<void> _atualizarPlanoSeNecessario() async {
    try {
      final planoData =
          await ApiService.getPlanoUsuario(widget.usuarioId.toString());
      if (planoData['success'] == true) {
        final novoPlano = planoData['nome_plano'] ?? 'Sem plano';
        final novoStatus = planoData['status_plano'] ?? 'inativo';

        // Atualiza apenas se mudou
        if (novoPlano != _planoUsuario || novoStatus != _statusPlano) {
          setState(() {
            _planoUsuario = novoPlano;
            _statusPlano = novoStatus;
          });

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_plano', novoPlano);
          await prefs.setString('user_status_plano', novoStatus);
        }
      }
    } catch (e) {
      debugPrint('Erro atualização real-time: $e');
    }
  }

  Future<void> _carregarTema() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkTheme = prefs.getBool('isDarkTheme') ?? false;
    });
  }

  Future<void> _alternarTema() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkTheme = !_isDarkTheme;
    });
    await prefs.setBool('isDarkTheme', _isDarkTheme);
  }

  Future<void> _carregarDadosUsuario() async {
    try {
      setState(() => _loadingPlano = true);

      final planoData = await ApiService.getPlanoUsuario(
        widget.usuarioId.toString(),
      );

      if (planoData['success'] == true) {
        final planoNome = planoData['nome_plano'] ?? 'Sem plano';
        final statusPlano = planoData['status_plano'] ?? 'inativo';

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
      } else {
        throw Exception('Erro ao carregar plano');
      }
    } catch (e) {
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

  void _limparDadosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
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
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sair'),
        content: const Text('Tem certeza que deseja sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              _limparDadosUsuario();
              Navigator.of(context).pushReplacementNamed('/login');
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkTheme;
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.grey[100];

    final telas = [
      CheckinScreen(usuarioId: widget.usuarioId, isDarkTheme: _isDarkTheme),
      _homeBody(),
      PlanosScreen(
        headerCard: HeaderCard(
          nome: widget.nomeUsuario,
          plano: _planoUsuario,
          status: _statusPlano,
          planoAtivo: _statusPlano == 'ativo',
          onRefresh: _carregarDadosUsuario,
        ),
        usuarioId: widget.usuarioId,
        token: widget.token,
        isDarkTheme: _isDarkTheme,
      ),
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 3,
        title: const Text(
          'Vitta Mobile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.wb_sunny_rounded : Icons.dark_mode_rounded,
            ),
            onPressed: _alternarTema,
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app_rounded),
            onPressed: _sair,
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: telas[currentIndex],
      ),
      bottomNavigationBar: _footer(isDark),
    );
  }

  Widget _homeBody() {
    final isDark = _isDarkTheme;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white70 : Colors.black87;

    final nome = widget.nomeUsuario;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          HeaderCard(
            nome: nome,
            plano: _planoUsuario,
            status: _statusPlano,
            planoAtivo: _statusPlano == 'ativo',
            onRefresh: _carregarDadosUsuario,
          ),
          const SizedBox(height: 20),
          _searchBar(),
          const SizedBox(height: 20),
          _dicaCard(cardColor, textColor),
          const SizedBox(height: 25),
          _academiasSection(),
        ],
      ),
    );
  }

  Widget _searchBar() {
    final isDark = _isDarkTheme;
    return TextField(
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        hintText: "Buscar academias, estúdios, cidades...",
        hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey[600]),
        prefixIcon: Icon(
          Icons.search,
          color: isDark ? Colors.white54 : Colors.grey,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _dicaCard(Color cardColor, Color textColor) {
    return Card(
      color: cardColor,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.local_fire_department_rounded,
              color: Colors.green,
              size: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "💡 Dica do dia: 30 minutos de treino melhoram o humor e aumentam sua disposição!",
                style: TextStyle(color: textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _academiasSection() {
    final isDark = _isDarkTheme;
    final textColor = isDark ? Colors.white70 : Colors.black87;

    final academias = [
      {"nome": "26 Fit", "img": "assets/images/gym1.jpg"},
      {"nome": "Malhação", "img": "assets/images/gym2.jpeg"},
      {"nome": "Attivita", "img": "assets/images/gym3.jpeg"},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Academias próximas",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: textColor,
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: academias.length,
            itemBuilder: (context, i) {
              final item = academias[i];
              return _academiaCard(item['nome']!, item['img']!);
            },
          ),
        ),
      ],
    );
  }

  Widget _academiaCard(String nome, String imagem) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        image: DecorationImage(
          image: AssetImage(imagem),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.25),
            BlendMode.darken,
          ),
        ),
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            nome,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _footer(bool dark) {
    final icons = [
      Icons.qr_code_2_rounded,
      Icons.home_rounded,
      Icons.attach_money_rounded,
    ];

    final labels = ['Check-in', 'Home', 'Planos'];

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1E1E1E) : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(3, (index) {
          final selected = currentIndex == index;
          return GestureDetector(
            onTap: () => onTabTapped(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? Colors.green[700] : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    icons[index],
                    color: selected
                        ? Colors.white
                        : (dark ? Colors.white70 : Colors.grey[700]),
                  ),
                  if (selected) ...[
                    const SizedBox(width: 6),
                    Text(
                      labels[index],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
