"""Testes isolados de filtros de periodo (sem acesso ao banco real)."""
import ast
from datetime import datetime, timedelta
from pathlib import Path
import unittest


RAIZ = Path(__file__).resolve().parents[1]
ARQUIVO = RAIZ / 'services' / 'paciente' / 'relatorio_service.py'


def periodo():
    fonte = ast.parse(ARQUIVO.read_text(encoding='utf8'))
    cls = next(no for no in fonte.body if isinstance(no, ast.ClassDef) and no.name == 'RelatorioService')
    metodo = next(no for no in cls.body if isinstance(no, ast.FunctionDef) and no.name == '_periodo')
    # Extrai somente a funcao pura; sem importar Flask/SQLAlchemy.
    metodo.decorator_list = []
    contexto = {'datetime': datetime, 'timedelta': timedelta}
    exec(compile(ast.Module(body=[metodo], type_ignores=[]), str(ARQUIVO), 'exec'), contexto)
    return contexto['_periodo']


class PeriodoRelatorioTest(unittest.TestCase):
    def test_filtro_mensal_virada_de_ano(self):
        inicio, fim, modo = periodo()(ano=2026, mes=12)
        self.assertEqual((inicio, fim, modo), (datetime(2026, 12, 1), datetime(2027, 1, 1), 'mensal'))

    def test_datas_inclusivas(self):
        inicio, fim, modo = periodo()(inicio='2026-10-01', fim='2026-10-23')
        self.assertEqual((inicio, fim, modo), (datetime(2026, 10, 1), datetime(2026, 10, 24), 'intervalo'))

    def test_periodo_invertido_recusado(self):
        with self.assertRaises(ValueError):
            periodo()(inicio='2026-10-24', fim='2026-10-01')

    def test_filtros_ambiguos_recusados(self):
        with self.assertRaises(ValueError):
            periodo()(todo_historico=True, mes=10)

    def test_todo_historico(self):
        inicio, fim, modo = periodo()(todo_historico=True)
        self.assertEqual(modo, 'todo')
        self.assertLess(inicio, fim)


if __name__ == '__main__':
    unittest.main()
