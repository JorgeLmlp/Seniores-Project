import unittest
from sqlalchemy import create_engine, inspect, text
from extensions import migrar_sinais_vitais


class MigracaoSinaisVitaisTest(unittest.TestCase):
    def test_tabela_antiga_preserva_dados_e_migracao_pode_repetir(self):
        engine = create_engine('sqlite:///:memory:')
        with engine.begin() as conexao:
            conexao.execute(text('CREATE TABLE sinais_vitais (id INTEGER PRIMARY KEY, temperatura VARCHAR(30))'))
            conexao.execute(text("INSERT INTO sinais_vitais VALUES (1, '36.5')"))
            migrar_sinais_vitais(conexao)
            migrar_sinais_vitais(conexao)
            registro = conexao.execute(text('SELECT id, temperatura, paciente_id FROM sinais_vitais')).one()
            self.assertEqual(tuple(registro), (1, '36.5', None))
            self.assertIn('ix_sinais_vitais_paciente_id',
                          {i['name'] for i in inspect(conexao).get_indexes('sinais_vitais')})
        engine.dispose()
