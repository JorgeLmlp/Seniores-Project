class SinalVital {
  final int? id;
  final DateTime? data;
  final String? pressao;
  final String? glicemia;
  final String? temperatura;
  final String? frequenciaCardiaca;
  final String? saturacao;

  const SinalVital({
    this.id,
    this.data,
    this.pressao,
    this.glicemia,
    this.temperatura,
    this.frequenciaCardiaca,
    this.saturacao,
  });

  factory SinalVital.fromMap(Map<String, dynamic> map) {
    return SinalVital(
      id: map['id'] as int?,
      data: map['data'] == null
          ? null
          : DateTime.tryParse(map['data'].toString()),
      pressao: map['pressao_art']?.toString(),
      glicemia: map['glicemia']?.toString(),
      temperatura: map['temperatura']?.toString(),
      frequenciaCardiaca: map['freq_cardiaca']?.toString(),
      saturacao: map['saturacao']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (data != null) 'data': data!.toIso8601String(),
    if (pressao?.trim().isNotEmpty == true) 'pressao_art': pressao,
    if (glicemia?.trim().isNotEmpty == true) 'glicemia': glicemia,
    if (temperatura?.trim().isNotEmpty == true) 'temperatura': temperatura,
    if (frequenciaCardiaca?.trim().isNotEmpty == true)
      'freq_cardiaca': frequenciaCardiaca,
    if (saturacao?.trim().isNotEmpty == true) 'saturacao': saturacao,
  };

  String get resumo => [
    if (pressao?.isNotEmpty == true) 'PA: $pressao',
    if (glicemia?.isNotEmpty == true) 'Glicemia: $glicemia',
    if (temperatura?.isNotEmpty == true) 'Temp.: $temperatura',
    if (frequenciaCardiaca?.isNotEmpty == true) 'FC: $frequenciaCardiaca',
    if (saturacao?.isNotEmpty == true) 'Sat.: $saturacao',
  ].join(' • ');
}

class SinalVitalValidation {
  static String? validar(SinalVital sinal) {
    final possuiMedida = [
      sinal.pressao,
      sinal.glicemia,
      sinal.temperatura,
      sinal.frequenciaCardiaca,
      sinal.saturacao,
    ].any((valor) => valor?.trim().isNotEmpty == true);
    if (!possuiMedida) return 'Informe pelo menos uma medida.';

    final pressao = sinal.pressao?.trim();
    if (pressao != null && pressao.isNotEmpty) {
      final partes = pressao.split('/');
      if (partes.length != 2) {
        return 'Pressão deve estar no formato 120/80 mmHg.';
      }
      final sistolica = _numero(partes[0]);
      final diastolica = _numero(partes[1]);
      if (sistolica == null ||
          diastolica == null ||
          sistolica < 50 ||
          sistolica > 250 ||
          diastolica < 30 ||
          diastolica > 150) {
        return 'Informe uma pressão entre 50/30 e 250/150 mmHg.';
      }
    }

    final regras =
        <
          String,
          ({String? valor, double minimo, double maximo, String unidade})
        >{
          'Glicemia': (
            valor: sinal.glicemia,
            minimo: 20,
            maximo: 600,
            unidade: 'mg/dL',
          ),
          'Temperatura': (
            valor: sinal.temperatura,
            minimo: 30,
            maximo: 45,
            unidade: '°C',
          ),
          'Frequência cardíaca': (
            valor: sinal.frequenciaCardiaca,
            minimo: 20,
            maximo: 240,
            unidade: 'bpm',
          ),
          'Saturação': (
            valor: sinal.saturacao,
            minimo: 50,
            maximo: 100,
            unidade: '%',
          ),
        };

    for (final entrada in regras.entries) {
      final valor = entrada.value.valor?.trim();
      if (valor == null || valor.isEmpty) continue;
      final numero = _numero(valor);
      if (numero == null ||
          numero < entrada.value.minimo ||
          numero > entrada.value.maximo) {
        return '${entrada.key} deve estar entre ${entrada.value.minimo} e '
            '${entrada.value.maximo} ${entrada.value.unidade}.';
      }
    }
    return null;
  }

  static double? _numero(String valor) {
    final normalizado = valor
        .toLowerCase()
        .replaceAll(',', '.')
        .replaceAll(RegExp(r'[^0-9.\-]'), '');
    return double.tryParse(normalizado);
  }
}
