import 'package:flutter/material.dart';

enum TipoCampo { texto, inteiro, decimal, lista, data, hora, opcao, booleano }

class CampoCuidado {
  const CampoCuidado(this.chave, this.rotulo,
      {this.tipo = TipoCampo.texto,
      this.obrigatorio = false,
      this.opcoes = const {},
      this.ajuda,
      this.maximo});
  final String chave, rotulo;
  final TipoCampo tipo;
  final bool obrigatorio;
  final Map<String, String> opcoes;
  final String? ajuda;
  final int? maximo;
}

class RecursoCuidado {
  const RecursoCuidado(this.rota, this.titulo, this.descricao, this.icone,
      this.campoTitulo, this.campos);
  final String rota, titulo, descricao, campoTitulo;
  final IconData icone;
  final List<CampoCuidado> campos;
}

const recursosCuidado = <RecursoCuidado>[
  RecursoCuidado(
      'sinais-vitais',
      'Sinais vitais',
      'Registre medições e acompanhe a evolução ao longo do tempo.',
      Icons.monitor_heart_outlined,
      'data', [
    CampoCuidado('data', 'Data e hora',
        tipo: TipoCampo.data, obrigatorio: true),
    CampoCuidado('pressao_art', 'Pressão arterial (mmHg)',
        ajuda: 'Ex.: 120/80'),
    CampoCuidado('glicemia', 'Glicemia (mg/dL)', tipo: TipoCampo.decimal),
    CampoCuidado('temperatura', 'Temperatura (°C)', tipo: TipoCampo.decimal),
    CampoCuidado('freq_cardiaca', 'Frequência cardíaca (bpm)',
        tipo: TipoCampo.decimal),
    CampoCuidado('saturacao', 'Saturação (%)',
        tipo: TipoCampo.decimal, maximo: 100),
  ]),
  RecursoCuidado(
      'estoque',
      'Estoque',
      'Controle os itens e os limites de reposição.',
      Icons.inventory_2_outlined,
      'nome', [
    CampoCuidado('nome', 'Nome do item', obrigatorio: true, maximo: 100),
    CampoCuidado('quantidade', 'Quantidade atual',
        tipo: TipoCampo.inteiro, obrigatorio: true),
    CampoCuidado('quantidade_minima', 'Quantidade mínima',
        tipo: TipoCampo.inteiro),
    CampoCuidado('descricao', 'Descrição', maximo: 255),
  ]),
  RecursoCuidado(
      'checklists-higiene',
      'Higiene',
      'Organize os cuidados de higiene e marque as tarefas concluídas.',
      Icons.clean_hands_outlined,
      'tarefa', [
    CampoCuidado('tarefa', 'Tarefa', obrigatorio: true, maximo: 40),
    CampoCuidado('descricao', 'Descrição', obrigatorio: true),
    CampoCuidado('frequencia', 'Frequência', obrigatorio: true, maximo: 30),
    CampoCuidado('status', 'Situação',
        tipo: TipoCampo.opcao,
        opcoes: {'pendente': 'Pendente', 'concluida': 'Concluída'}),
  ]),
  RecursoCuidado(
      'dietas-restricoes',
      'Dieta e restrições',
      'Consulte a alimentação, as restrições e as alergias registradas.',
      Icons.restaurant_outlined,
      'descricao_dieta', [
    CampoCuidado('descricao_dieta', 'Descrição da dieta', obrigatorio: true),
    CampoCuidado('restricoes', 'Restrições alimentares',
        tipo: TipoCampo.lista, ajuda: 'Separe os itens por vírgulas.'),
    CampoCuidado('alergias', 'Alergias',
        tipo: TipoCampo.lista, ajuda: 'Separe os itens por vírgulas.'),
    CampoCuidado('observacoes', 'Observações'),
  ]),
  RecursoCuidado('lesoes', 'Lesões', 'Acompanhe lesões e suas fotografias.',
      Icons.healing_outlined, 'localizacao', [
    CampoCuidado('localizacao', 'Localização da lesão',
        obrigatorio: true, maximo: 100),
    CampoCuidado('descricao', 'Descrição', obrigatorio: true),
    CampoCuidado('gravidade', 'Gravidade', maximo: 30),
    CampoCuidado('status', 'Situação', tipo: TipoCampo.opcao, opcoes: {
      'aberta': 'Aberta',
      'em_tratamento': 'Em tratamento',
      'cicatrizada': 'Cicatrizada'
    }),
  ]),
  RecursoCuidado(
      'incidentes',
      'Incidentes',
      'Registre ocorrências e as providências tomadas.',
      Icons.report_outlined,
      'tipo', [
    CampoCuidado('tipo', 'Tipo de incidente', obrigatorio: true, maximo: 50),
    CampoCuidado('data_hora', 'Data e hora',
        tipo: TipoCampo.data, obrigatorio: true),
    CampoCuidado('descricao', 'Descrição', obrigatorio: true),
    CampoCuidado('gravidade', 'Gravidade', maximo: 30),
    CampoCuidado('providencias', 'Providências tomadas'),
  ]),
  RecursoCuidado(
      'contatos-emergencia',
      'Contatos de emergência',
      'Mantenha os contatos de familiares e médicos atualizados.',
      Icons.contact_phone_outlined,
      'nome', [
    CampoCuidado('nome', 'Nome', obrigatorio: true, maximo: 100),
    CampoCuidado('tipo', 'Tipo de contato',
        tipo: TipoCampo.opcao,
        opcoes: {'familiar': 'Familiar', 'medico': 'Médico'}),
    CampoCuidado('telefone', 'Telefone', obrigatorio: true, maximo: 30),
    CampoCuidado('vinculo', 'Vínculo', maximo: 60),
    CampoCuidado('email', 'E-mail', maximo: 120),
    CampoCuidado('especialidade', 'Especialidade', maximo: 100),
  ]),
  RecursoCuidado(
      'alertas-panico',
      'Pedidos de ajuda',
      'Registre e acompanhe pedidos de ajuda. Este registro não liga nem envia mensagens aos contatos.',
      Icons.sos_outlined,
      'mensagem', [
    CampoCuidado('mensagem', 'Mensagem', obrigatorio: true, maximo: 255),
    CampoCuidado('localizacao', 'Localização', maximo: 255),
    CampoCuidado('resolvido', 'Atendimento concluído',
        tipo: TipoCampo.booleano),
  ]),
  RecursoCuidado(
      'turnos-cuidadores',
      'Turnos de cuidado',
      'Organize os dias e horários de cada cuidador.',
      Icons.calendar_month_outlined,
      'nome_cuidador', [
    CampoCuidado('nome_cuidador', 'Nome do cuidador',
        obrigatorio: true, maximo: 100),
    CampoCuidado('dias_semana', 'Dias da semana',
        tipo: TipoCampo.lista,
        obrigatorio: true,
        opcoes: {
          'segunda': 'Segunda',
          'terca': 'Terça',
          'quarta': 'Quarta',
          'quinta': 'Quinta',
          'sexta': 'Sexta',
          'sabado': 'Sábado',
          'domingo': 'Domingo'
        }),
    CampoCuidado('hora_inicio', 'Início do turno',
        tipo: TipoCampo.hora, obrigatorio: true),
    CampoCuidado('hora_fim', 'Fim do turno',
        tipo: TipoCampo.hora, obrigatorio: true),
    CampoCuidado('observacao', 'Observação'),
  ]),
  RecursoCuidado(
      'exames-documentos',
      'Documentos de exames',
      'Guarde PDFs e imagens dos exames no prontuário.',
      Icons.folder_outlined,
      'nome', [
    CampoCuidado('nome', 'Nome do exame', obrigatorio: true, maximo: 120),
    CampoCuidado('descricao', 'Descrição'),
    CampoCuidado('data_exame', 'Data do exame', tipo: TipoCampo.data),
  ]),
  RecursoCuidado(
      'registros-financeiros',
      'Receitas e despesas',
      'Registre entradas e saídas financeiras do paciente.',
      Icons.account_balance_wallet_outlined,
      'descricao', [
    CampoCuidado('descricao', 'Descrição', obrigatorio: true),
    CampoCuidado('valor', 'Valor (R\$)',
        tipo: TipoCampo.decimal, obrigatorio: true),
    CampoCuidado('tipo', 'Tipo',
        tipo: TipoCampo.opcao,
        opcoes: {'despesa': 'Despesa', 'receita': 'Receita'}),
    CampoCuidado('data', 'Data e hora',
        tipo: TipoCampo.data, obrigatorio: true),
  ]),
];
