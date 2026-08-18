import 'incidente.dart'; // Se estiver no mesmo diretório. Caso contrário, use: import '../models/incidente.dart';

class Registro {
  final String? dataFormatada;
  final int humor;
  final int dor;
  final int apetite;
  final int mobilidade;
  final String? observacoes;
  final List<Incidente>? listaIncidentes;
  final String? tendencia;

  Registro({
    this.dataFormatada,
    this.observacoes,
    this.listaIncidentes,
    this.tendencia,
    required this.humor,
    required this.dor,
    required this.apetite,
    required this.mobilidade,
  });

  int get totalIncidentes => listaIncidentes?.length ?? 0;
}