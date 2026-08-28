import 'package:flutter/material.dart';

class Notificacao {
  final String titulo;
  final String subtitulo;
  final String horario;
  final IconData icone;
  final Color corIcone;
  final String categoria; // => Alertas, agendamentos e medicamentos
  final String secao; // => Hoje, ontem, esta semana, mes passado...
  bool lida;

  Notificacao({
    required this.titulo,
    required this.subtitulo,
    required this.horario,
    required this.icone,
    required this.corIcone,
    required this.categoria,
    required this.secao,
    this.lida = false,
  });
}
