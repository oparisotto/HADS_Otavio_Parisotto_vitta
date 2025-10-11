// models/plano.dart
class Plano {
  final int id;
  final String nome;
  final String descricao;
  final double preco;

  Plano({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.preco,
  });

  factory Plano.fromJson(Map<String, dynamic> json) {
    return Plano(
      id: json['id'],
      nome: json['nome'],
      descricao: json['descricao'],
      preco: double.tryParse(json['preco'].toString()) ?? 0.0,
    );
  }
}
