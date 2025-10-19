import 'package:flutter/material.dart';

class HeaderCard extends StatelessWidget {
  final String nome;
  final String plano;
  final String status;
  final bool planoAtivo;
  final VoidCallback onRefresh;

  const HeaderCard({
    super.key,
    required this.nome,
    required this.plano,
    required this.status,
    this.planoAtivo = true,
    required this.onRefresh,
  });

  String _getIniciais(String nome) {
    final partes = nome.split(' ');
    if (partes.length == 1) return partes[0][0];
    return '${partes[0][0]}${partes[1][0]}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // ✅ SEMPRE VERDE - independente do tema
    final Color greenColor = Colors.green;
    final Color greenLight = Colors.green[100]!;
    final Color textOnGreen = Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: greenColor, // ✅ SEMPRE VERDE
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: textOnGreen.withOpacity(0.3),
            child: Text(
              _getIniciais(nome),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textOnGreen, // ✅ TEXTO BRANCO
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textOnGreen, // ✅ TEXTO BRANCO
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.workspace_premium, 
                         size: 16, 
                         color: textOnGreen), // ✅ ÍCONE BRANCO
                    const SizedBox(width: 4),
                    Text(
                      plano,
                      style: TextStyle(
                        color: textOnGreen.withOpacity(0.9), // ✅ TEXTO BRANCO
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: textOnGreen.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: textOnGreen,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: textOnGreen, // ✅ TEXTO BRANCO
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRefresh,
            icon: Icon(Icons.refresh, color: textOnGreen), // ✅ ÍCONE BRANCO
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}