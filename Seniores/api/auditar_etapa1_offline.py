"""Checks estruturais SEM executar a API e SEM acessar Aiven.

Execute na raiz do projeto: python auditar_etapa1_offline.py
Não substitui flutter analyze, testes de widget ou validação de API/SQLite.
"""
import ast
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent
API = ROOT / 'api'
LIB = ROOT / 'front-end' / 'lib'
failures = []
passes = 0


def check(label, condition):
    global passes
    if condition:
        passes += 1
        print(f'[OK] {label}')
    else:
        failures.append(label)
        print(f'[PENDENTE] {label}')


def has(path, *tokens):
    p = ROOT / path
    if not p.is_file():
        return False
    text = p.read_text(encoding='utf-8-sig')
    return all(token in text for token in tokens)


python_files = list(API.rglob('*.py'))
python_errors = []
for file in python_files:
    try:
        ast.parse(file.read_text(encoding='utf-8-sig'), filename=str(file))
    except SyntaxError as error:
        python_errors.append(f'{file.relative_to(ROOT)}: {error}')
check(f'Sintaxe de {len(python_files)} arquivos Python', not python_errors)

imports_ausentes = []
dart_files = list(LIB.rglob('*.dart'))
for file in dart_files:
    text = file.read_text(encoding='utf-8-sig')
    for uri in re.findall(r'''\b(?:import|export|part)\s+['"](\.{1,2}/[^'\"]+)['"]''', text):
        if not (file.parent / uri).resolve().is_file():
            imports_ausentes.append(f'{file.relative_to(ROOT)} -> {uri}')
check(f'Imports relativos de {len(dart_files)} arquivos Dart', not imports_ausentes)

check('Foto de medicamentos: rota GET/PUT/DELETE e interface',
      has('api/routes/medicamento/medicamento.py', 'foto_medicamento', 'PUT', 'DELETE')
      and has('front-end/lib/pages/medicamentos/tela_detalhes_medicamento.dart',
              '_carregarFoto', '_foto'))
check('Administração de doses: horário, quem confirmou e observação',
      has('api/routes/medicamento/doses.py',
          'horario_previsto', 'confirmado_por', 'administrado_em', 'observacao'))
check('Exclusão de conta: confirmação, senha e HTTP 409',
      has('api/routes/relacionamento/solicitacoes.py',
          "@solicitacoesbp.delete('/minha-conta')", 'senha_confere', '409')
      and has('front-end/lib/pages/tela_conta.dart', '_excluirConta'))
check('Consultas e exames: detalhes, edição, mapa, telefone',
      has('front-end/lib/pages/cuidados/tela_detalhes_consulta.dart',
          'EditarAgendamento', 'AcoesExternas.mapa', 'AcoesExternas.telefone')
      and has('front-end/lib/pages/cuidados/tela_detalhes_exames.dart',
              'EditarAgendamento', 'AcoesExternas.mapa'))
check('Diário: filtro por período e exclusão',
      has('front-end/lib/pages/registro diario/tela_relatorio.dart',
          'showDateRangePicker', '_excluirSelecionado'))
check('Sinais vitais: consumo da evolução e filtro de data',
      has('front-end/lib/pages/modulos_clinicos.dart',
          'sinais-vitais/evolucao', 'showDateRangePicker'))
check('Estoque: ajuste rápido pela API',
      has('front-end/lib/pages/modulos_clinicos.dart', '_ajustarEstoque', "atualizarRegistro('estoque'"))
check('Gastos: categoria, valores e proteção de filtro removido',
      has('front-end/lib/pages/gastos/tela_gastos.dart',
          '_categoriaAtiva', '_filtrados', "_categoriaAtiva != 'todas'"))
check('Destinatários: validação de CPF no serviço',
      has('api/services/paciente/destinatario_service.py', 'cpf', '11'))
check('Notificações: leitura local e abertura de módulo',
      has('front-end/lib/pages/tela_notificacoes.dart',
          '_marcarLido', '_abrirRelacionado', '_restaurarLidos'))
check('Alertas: não afirma envio de socorro automático',
      has('front-end/lib/pages/modulos_clinicos.dart',
          'NÃO chama emergência', '_resolverAlerta'))
check('Testes SQLite locais da Etapa 1 disponíveis',
      has('api/verificar_etapa1_sqlite.py', 'sqlite:///:memory:', 'unittest.main')
      and has('api/verificar_incrementos_sqlite.py', 'sqlite:///:memory:', 'unittest.main'))

print(f'\nChecagens estruturais: {passes}/{passes + len(failures)}')
if python_errors:
    print('Sintaxe Python:', '\n'.join(python_errors[:10]))
if imports_ausentes:
    print('Imports Dart ausentes:', '\n'.join(imports_ausentes[:10]))
if failures:
    print('Itens estruturais pendentes:', ', '.join(failures))
    raise SystemExit(1)
print('IMPORTANTE: checks estruturais OK; funcionalidades ainda precisam dos testes Flutter/SQLite.')
