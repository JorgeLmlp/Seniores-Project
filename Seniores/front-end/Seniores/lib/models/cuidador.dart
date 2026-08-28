class Cuidador {
  final String nome;
  final String funcao;
  final String telefone1;
  final String telefone2;
  final List<bool> frequencia;
  final String horaInicio;
  final String horaFim;
  final String observacoes;
  final bool ativoAgora;

  Cuidador({
    required this.nome,
    required this.funcao,
    this.telefone1 = '',
    this.telefone2 = '',
    required this.frequencia,
    required this.horaInicio,
    required this.horaFim,
    this.observacoes = '',
    this.ativoAgora = false,
  });

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'funcao': funcao,
        'telefone1': telefone1,
        'telefone2': telefone2,
        'frequencia': frequencia,
        'horaInicio': horaInicio,
        'horaFim': horaFim,
        'observacoes': observacoes,
        'ativoAgora': ativoAgora,
      };

  factory Cuidador.fromJson(Map<String, dynamic> json) => Cuidador(
        nome: json['nome'] as String? ?? '',
        funcao: json['funcao'] as String? ?? '',
        telefone1: json['telefone1'] as String? ?? '',
        telefone2: json['telefone2'] as String? ?? '',
        frequencia: (json['frequencia'] as List<dynamic>? ?? [])
            .map((item) => item as bool)
            .toList(),
        horaInicio: json['horaInicio'] as String? ?? '',
        horaFim: json['horaFim'] as String? ?? '',
        observacoes: json['observacoes'] as String? ?? '',
        ativoAgora: json['ativoAgora'] as bool? ?? false,
      );

  String get frequenciaResumida {
    bool todos = frequencia.every((element) => element);
    bool segASex = !frequencia[0] &&
        frequencia[1] &&
        frequencia[2] &&
        frequencia[3] &&
        frequencia[4] &&
        frequencia[5] &&
        !frequencia[6];

    bool finsDeSemana = frequencia[0] &&
        !frequencia[1] &&
        !frequencia[2] &&
        !frequencia[3] &&
        !frequencia[4] &&
        !frequencia[5] &&
        frequencia[6];

    if (todos) {
      return 'Todos os dias';
    } else if (segASex) {
      return 'De seg a sex';
    } else if (finsDeSemana) {
      return 'Finais de semana';
    } else {
      const dias = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
      List<String> diasAtivos = [];
      for (int i = 0; i < frequencia.length; i++) {
        if (frequencia[i]) {
          diasAtivos.add(dias[i]);
        }
      }
      return diasAtivos.join(', ');
    }
  }
}
