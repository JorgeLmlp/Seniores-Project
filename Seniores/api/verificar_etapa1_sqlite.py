"""Etapa 1 — testes funcionais isolados dos últimos recursos do Seniores.

Executa apenas em SQLite em memória. Não importa configurações reais do .env,
não conecta à Aiven, não dispara e-mails nem aciona serviços externos.

Windows (na pasta api): python verificar_etapa1_sqlite.py
"""
import os
import secrets
import sys
import unittest
from pathlib import Path

# O backend deve ser carregado SOMENTE depois destas configurações de testes.
os.environ['DATABASE_URL'] = 'sqlite:///:memory:'
os.environ['DB_AUTO_SCHEMA'] = '1'
os.environ['API_TESTING'] = '1'
os.environ['JWT_SECRET_KEY'] = secrets.token_hex(32)
os.environ['SECRET_KEY'] = secrets.token_hex(32)
for key in ('SMTP_HOST', 'SMTP_USER', 'SMTP_PASSWORD', 'SMTP_FROM', 'DB_SSL_CA'):
    os.environ.pop(key, None)
sys.path.insert(0, str(Path(__file__).resolve().parent))

from extensions import app  # noqa: E402


class Etapa1Fluxos(unittest.TestCase):
    def setUp(self):
        self.client = app.test_client()
        self.password = 'SenhaApenasParaTestes2026!'
        self.paciente_id, self.headers = self._registrar_paciente()

    def _registrar_paciente(self):
        email = f'validacao-{secrets.token_hex(7)}@example.invalid'
        cadastro = self.client.post('/users/', json={
            'nome': 'Paciente fictício', 'tipo': 'paciente', 'email': email,
            'telefone': '31988887777', 'cpf': str(secrets.randbelow(10**11)).zfill(11),
            'senha': self.password,
        })
        self.assertEqual(cadastro.status_code, 201, cadastro.get_json())
        usuario = cadastro.get_json()
        login = self.client.post('/users/login/', json={
            'email': email, 'senha': self.password,
        })
        self.assertEqual(login.status_code, 200, login.get_json())
        return usuario['id'], {'Authorization': f"Bearer {login.get_json()['token']}"}

    def _post(self, recurso, dados, paciente_id=None, headers=None):
        id = self.paciente_id if paciente_id is None else paciente_id
        return self.client.post(f'/pacientes/{id}/{recurso}', json=dados,
                                headers=self.headers if headers is None else headers)

    def _get(self, path):
        return self.client.get(path, headers=self.headers)

    def _patch(self, path, dados):
        return self.client.patch(path, json=dados, headers=self.headers)

    def _delete(self, path):
        return self.client.delete(path, headers=self.headers)

    def test_consultas_criar_editar_excluir(self):
        created = self._post('consultas', {
            'nomeDoutor': 'Profissional fictício', 'especialidade': 'Exemplo',
            'local': 'Local fictício', 'dataHora': '2026-11-10T14:00:00',
            'telefone': '3100000000', 'alertas': [], 'exames': [],
        })
        self.assertEqual(created.status_code, 201, created.get_json())
        id = created.get_json()['id']
        changed = self._patch(f'/consultas/{id}', {'telefone': '31900000000', 'motivo': 'Retorno'})
        self.assertEqual(changed.status_code, 200, changed.get_json())
        self.assertEqual(changed.get_json()['dados']['motivo'], 'Retorno')
        self.assertEqual(self._delete(f'/consultas/{id}').status_code, 204)
        self.assertEqual(self._get(f'/consultas/{id}').status_code, 404)

    def test_exames_criar_editar_excluir(self):
        created = self._post('exames', {
            'nomeExame': 'Exame fictício', 'local': 'Unidade fictícia',
            'dataHora': '2026-11-12T08:00:00', 'concluido': False,
        })
        self.assertEqual(created.status_code, 201, created.get_json())
        id = created.get_json()['id']
        changed = self._patch(f'/exames/{id}', {'concluido': True, 'telefone': '3100000000'})
        self.assertEqual(changed.status_code, 200, changed.get_json())
        self.assertIs(changed.get_json()['dados']['concluido'], True)
        self.assertEqual(self._delete(f'/exames/{id}').status_code, 204)

    def test_diario_historico_edicao_exclusao(self):
        payload = {'humor': 'bom', 'dor': 'bom', 'fome': 'bom', 'mobilidade': 'bom',
                   'descricao': 'Registro fictício'}
        created = self._post('diarios-saude', payload)
        self.assertEqual(created.status_code, 201, created.get_json())
        id = created.get_json()['id']
        registros = self._get(f'/pacientes/{self.paciente_id}/diarios-saude')
        self.assertEqual(registros.status_code, 200)
        self.assertIn(id, [r['id'] for r in registros.get_json()])
        changed = self._patch(f'/diarios-saude/{id}', {'descricao': 'Registro atualizado'})
        self.assertEqual(changed.status_code, 200, changed.get_json())
        self.assertEqual(self._delete(f'/diarios-saude/{id}').status_code, 204)

    def test_estoque_quantidade_minima(self):
        created = self._post('estoque', {'nome': 'Item fictício', 'quantidade': 2,
                                         'quantidade_minima': 3})
        self.assertEqual(created.status_code, 201, created.get_json())
        id = created.get_json()['id']
        self.assertTrue(created.get_json()['estoque_baixo'])
        updated = self._patch(f'/estoque/{id}', {'quantidade': 4})
        self.assertEqual(updated.status_code, 200, updated.get_json())
        self.assertFalse(updated.get_json()['estoque_baixo'])
        self.assertEqual(self._delete(f'/estoque/{id}').status_code, 204)

    def test_financeiro_crud_valor(self):
        created = self._post('registros-financeiros', {
            'descricao': 'Lançamento fictício', 'tipo': 'despesa',
            'valor': '12.50', 'data': '2026-10-23T12:00:00',
        })
        self.assertEqual(created.status_code, 201, created.get_json())
        id = created.get_json()['id']
        self.assertAlmostEqual(created.get_json()['valor'], 12.5)
        updated = self._patch(f'/registros-financeiros/{id}', {'valor': '15.00'})
        self.assertEqual(updated.status_code, 200, updated.get_json())
        self.assertAlmostEqual(updated.get_json()['valor'], 15.0)
        self.assertEqual(self._delete(f'/registros-financeiros/{id}').status_code, 204)

    def test_destinatarios_cpf_e_validacao(self):
        payload = {'nome': 'Responsável de teste', 'vinculo': 'Familiar',
                   'telefone': '31999990000', 'cpf': '123.456.789-00'}
        created = self._post('destinatarios', payload)
        self.assertEqual(created.status_code, 201, created.get_json())
        id = created.get_json()['id']
        self.assertEqual(created.get_json()['dados']['cpf'], '12345678900')
        invalid = self._patch(f'/destinatarios/{id}', {'cpf': '123'})
        self.assertEqual(invalid.status_code, 400)
        self.assertEqual(self._delete(f'/destinatarios/{id}').status_code, 204)

    def test_sinais_vitais_evolucao(self):
        for minuto in (0, 1):
            created = self._post('sinais-vitais', {
                'freq_cardiaca': str(70 + minuto),
                'data': f'2026-10-23T12:{minuto:02d}:00',
            })
            self.assertEqual(created.status_code, 201, created.get_json())
        resp = self._get(f'/pacientes/{self.paciente_id}/sinais-vitais/evolucao')
        self.assertEqual(resp.status_code, 200, resp.get_json())
        self.assertIn('freq_cardiaca', resp.get_json()['series'])
        self.assertEqual(len(resp.get_json()['series']['freq_cardiaca']), 2)

    def test_alerta_interno_registro_e_resolucao(self):
        created = self._post('alertas-panico', {
            'mensagem': 'Registro fictício — não chamar emergência',
            'localizacao': 'Sem localização real',
        })
        self.assertEqual(created.status_code, 201, created.get_json())
        id = created.get_json()['id']
        updated = self._patch(f'/alertas-panico/{id}', {'resolvido': True})
        self.assertEqual(updated.status_code, 200, updated.get_json())
        self.assertTrue(updated.get_json()['resolvido'])
        # Este teste NÃO aciona serviço externo ou envia mensagens.

    def test_protecao_entre_pacientes(self):
        outro_id, outro_headers = self._registrar_paciente()
        self.assertNotEqual(outro_id, self.paciente_id)
        for rota in ('diarios-saude', 'consultas', 'medicamentos', 'estoque'):
            r = self.client.get(f'/pacientes/{outro_id}/{rota}', headers=self.headers)
            self.assertEqual(r.status_code, 403, (rota, r.get_json()))
        r = self.client.get(f'/pacientes/{outro_id}/consultas', headers=outro_headers)
        self.assertEqual(r.status_code, 200, r.get_json())


if __name__ == '__main__':
    unittest.main(verbosity=2)
