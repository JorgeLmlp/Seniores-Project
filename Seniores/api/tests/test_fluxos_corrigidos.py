import unittest
from datetime import datetime
from unittest.mock import patch
from uuid import uuid4
from zoneinfo import ZoneInfo
from extensions import app


class FluxosCorrigidosTest(unittest.TestCase):
    def setUp(self):
        self.client = app.test_client()
        self.contas = {}
        for tipo in ('paciente', 'responsavel', 'cuidador'):
            email = f'{uuid4().hex}@teste.local'
            cpf = str(uuid4().int % (10**11)).zfill(11)
            resposta = self.client.post('/users/', json={'nome': tipo, 'email': email,
                'cpf': cpf, 'telefone': '11999999999', 'senha': 'Senha123!', 'tipo': tipo})
            self.assertEqual(resposta.status_code, 201)
            login = self.client.post('/users/login/', json={'email': email, 'senha': 'Senha123!'}).get_json()
            self.contas[tipo] = {**login, 'headers': {'Authorization': f"Bearer {login['token']}"}}
        self.p = self.contas['paciente']
        self.r = self.contas['responsavel']
        self.c = self.contas['cuidador']

    def test_convite_aceite_e_acesso_por_papel(self):
        self.assertEqual(self.client.get('/minha-conta/pacientes').status_code, 401)
        self.assertEqual(self.client.post('/minha-conta/pacientes', headers=self.c['headers'], json={'cpf': self.p['cpf']}).status_code, 403)
        self.assertEqual(self.client.post('/minha-conta/pacientes', headers=self.r['headers'], json={'cpf': self.p['cpf']}).status_code, 200)
        rota = f"/pacientes/{self.p['id']}/medicamentos"
        self.assertEqual(self.client.get(rota, headers=self.c['headers']).status_code, 403)
        pedido = self.client.post('/minha-conta/solicitacoes', headers=self.r['headers'], json={'email': self.c['email'].upper(), 'paciente_id': self.p['id']})
        self.assertEqual(pedido.status_code, 201, pedido.get_json())
        id = pedido.get_json()['id']
        lista = self.client.get('/minha-conta/solicitacoes', headers=self.c['headers']).get_json()
        self.assertEqual(lista[0]['paciente']['nome'], 'paciente')
        self.assertEqual(lista[0]['responsavel']['nome'], 'responsavel')
        self.assertEqual(self.client.patch(f'/minha-conta/solicitacoes/{id}', headers=self.r['headers'], json={'status': 'aceita'}).status_code, 403)
        self.assertEqual(self.client.patch(f'/minha-conta/solicitacoes/{id}', headers=self.c['headers'], json={'status': 'aceita'}).status_code, 200)
        self.assertEqual(self.client.patch(f'/minha-conta/solicitacoes/{id}', headers=self.c['headers'], json={'status': 'recusada'}).status_code, 409)
        self.assertEqual(self.client.get(rota, headers=self.c['headers']).status_code, 200)
        self.assertEqual(self.client.post('/relacionamentos/paciente-cuidador', headers=self.c['headers'], json={}).status_code, 403)

    def test_recusa_nao_concede_acesso(self):
        self.client.post('/minha-conta/pacientes', headers=self.r['headers'], json={'cpf': self.p['cpf']})
        pedido = self.client.post('/minha-conta/solicitacoes', headers=self.r['headers'], json={'email': self.c['email'], 'paciente_id': self.p['id']}).get_json()
        self.assertEqual(self.client.patch(f"/minha-conta/solicitacoes/{pedido['id']}", headers=self.c['headers'], json={'status': 'recusada'}).status_code, 200)
        self.assertEqual(self.client.get('/minha-conta/pacientes', headers=self.c['headers']).get_json(), [])

    def test_convite_de_cuidador_exige_email_cadastrado(self):
        self.client.post('/minha-conta/pacientes', headers=self.r['headers'], json={'cpf': self.p['cpf']})
        resposta = self.client.post('/minha-conta/solicitacoes', headers=self.r['headers'], json={
            'cpf': self.c['cpf'],
            'paciente_id': self.p['id'],
        })
        self.assertEqual(resposta.status_code, 404)
        self.assertIn('e-mail', resposta.get_json()['erro'])

    def test_consulta_sem_exame_gasto_e_doses(self):
        prefixo = f"/pacientes/{self.p['id']}"
        headers = self.p['headers']
        consulta = self.client.post(prefixo + '/consultas', headers=headers, json={'nomeDoutor': 'Ana', 'especialidade': 'Clínica', 'local': 'Rua A', 'dataHora': '2026-10-20T14:30:00', 'exames': []})
        self.assertEqual(consulta.status_code, 201, consulta.get_json())
        gasto = self.client.post(prefixo + '/gastos', headers=headers, json={'categoria': 'Farmácia', 'valor': 12.50, 'tipo': 'Mensal', 'cor': 'azul'})
        self.assertEqual(gasto.status_code, 201, gasto.get_json())
        self.assertEqual(self.client.get(prefixo + '/gastos', headers=headers).get_json()[0]['dados']['valor'], 12.50)
        med = self.client.post(prefixo + '/medicamentos', headers=headers, json={'nome': 'Remédio', 'dosagem': '1 mg', 'horarios': ['08:00']}).get_json()
        self.assertEqual(self.client.patch(f"/medicamentos/{med['id']}", headers=headers, json={'dosagem': '2 mg'}).get_json()['dosagem'], '2 mg')
        rota = f"/medicamentos/{med['id']}/doses/2026-10-20"
        for concluida in (True, False):
            self.assertEqual(self.client.put(rota, headers=headers, json={'horario': '08:00', 'concluida': concluida}).status_code, 200)
            self.assertEqual(self.client.get(rota, headers=headers).get_json()['08:00'], concluida)
        self.assertEqual(self.client.get(f"/medicamentos/{med['id']}/doses/2026-10-21", headers=headers).get_json(), {})
        self.assertEqual(self.client.get(rota, headers=self.c['headers']).status_code, 403)
        pdf = self.client.get(prefixo + '/relatorio.pdf?ano=2026&mes=10', headers=headers)
        self.assertEqual(pdf.status_code, 200)
        self.assertTrue(pdf.data.startswith(b'%PDF-'))
        self.assertEqual(self.client.get(prefixo + '/relatorio.pdf?ano=0&mes=10', headers=headers).status_code, 400)

    def test_atualizacao_conta(self):
        resposta = self.client.patch('/minha-conta', headers=self.r['headers'], json={'nome': 'Novo nome'})
        self.assertEqual(resposta.status_code, 200)
        self.assertEqual(self.client.get('/minha-conta', headers=self.r['headers']).get_json()['name'], 'Novo nome')

    def test_dose_atrasada_avisa_paciente_e_responsavel(self):
        self.client.post('/minha-conta/pacientes', headers=self.r['headers'], json={'cpf': self.p['cpf']})
        medicamento = self.client.post(
            f"/pacientes/{self.p['id']}/medicamentos",
            headers=self.p['headers'],
            json={'nome': 'Losartana', 'dosagem': '50 mg', 'horarios': ['08:00']},
        ).get_json()

        class DataHoraFixa(datetime):
            @classmethod
            def now(cls, tz=None):
                return cls(2026, 10, 23, 10, 0, tzinfo=tz or ZoneInfo('America/Sao_Paulo'))

        rota_alertas = f"/pacientes/{self.p['id']}/alertas-medicamentos"
        with patch('routes.medicamento.doses.datetime', DataHoraFixa):
            alerta_paciente = self.client.get(rota_alertas, headers=self.p['headers']).get_json()
            alerta_responsavel = self.client.get(rota_alertas, headers=self.r['headers']).get_json()
            self.assertEqual(alerta_paciente[0]['tipo'], 'medicamento_atrasado')
            self.assertTrue(alerta_paciente[0]['responsavel_notificado'])
            self.assertEqual(alerta_responsavel[0]['medicamento'], 'Losartana')

            rota_dose = f"/medicamentos/{medicamento['id']}/doses/2026-10-23"
            self.client.put(
                rota_dose,
                headers=self.p['headers'],
                json={'horario': '08:00', 'concluida': True},
            )
            self.assertEqual(
                self.client.get(rota_alertas, headers=self.r['headers']).get_json(),
                [],
            )
