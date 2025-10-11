import 'package:flutter/material.dart';

class CheckinScreen extends StatelessWidget {
  CheckinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lista de exemplo de check-ins
    final checkins = [
      'Check-in 01: 08/10/2025',
      'Check-in 02: 09/10/2025',
      'Check-in 03: 10/10/2025',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Check-ins'), backgroundColor: Colors.green[700]),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: checkins.length,
        itemBuilder: (_, i) => Card(
          child: ListTile(
            leading: const Icon(Icons.check_circle_outline, color: Colors.green),
            title: Text(checkins[i]),
          ),
        ),
      ),
    );
  }
}
