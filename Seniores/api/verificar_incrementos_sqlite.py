"""Isolated smoke tests: ONLY ephemeral SQLite; never Aiven or other remote DB.

Run: cd api && python verificar_incrementos_sqlite.py
"""
import base64
import os
import secrets
import sys
import unittest
from pathlib import Path

# Environment must be selected BEFORE importing the app or calling load_dotenv.
os.environ['DATABASE_URL'] = 'sqlite:///:memory:'
os.environ['DB_AUTO_SCHEMA'] = '1'
os.environ['API_TESTING'] = '1'
os.environ['JWT_SECRET_KEY'] = secrets.token_hex(32)
os.environ['SECRET_KEY'] = secrets.token_hex(32)
sys.path.insert(0, str(Path(__file__).resolve().parent))

from extensions import app  # noqa: E402


class SmokeTests(unittest.TestCase):
    def setUp(self):
        self.client = app.test_client()
        self.email = f"smoke-{secrets.token_hex(6)}@example.invalid"
        self.password = 'SenhaValidaParaTeste123!'
        self.user = self.client.post('/users/', json={
            'nome': 'Paciente de teste', 'tipo': 'paciente', 'email': self.email,
            'telefone': '31999999999', 'cpf': str(secrets.randbelow(10**11)).zfill(11),
            'senha': self.password,
        }).get_json()
        assert 'id' in self.user, self.user
        token = self.client.post('/users/login/', json={
            'email': self.email, 'senha': self.password,
        }).get_json()['token']
        self.headers = {'Authorization': f'Bearer {token}'}

    def med(self):
        resposta = self.client.post(f"/pacientes/{self.user['id']}/medicamentos",
            json={'nome': 'Medicamento fictício', 'dosagem': 'exemplo',
                  'frequencia': 'Diária', 'horarios': ['09:00']},
            headers=self.headers)
        self.assertEqual(resposta.status_code, 201, resposta.get_json())
        return resposta.get_json()['id']

    def test_foto_autorizada_usa_tabela_existente(self):
        id = self.med()
        url = f'/medicamentos/{id}/foto'
        # Minimal PNG signature adequate for transport validation; not a real clinical picture.
        image_bytes = b'\x89PNG\r\n\x1a\n' + b'fake-image-smoke-test'
        resposta = self.client.put(url, headers=self.headers, json={
            'mime_type': 'image/png',
            'foto_base64': base64.b64encode(image_bytes).decode('ascii'),
        })
        self.assertEqual(resposta.status_code, 200, resposta.get_json())
        self.assertEqual(resposta.get_json()['foto_url'], url)
        self.assertEqual(self.client.get(url, headers=self.headers).data, image_bytes)
        self.assertEqual(self.client.delete(url, headers=self.headers).status_code, 200)
        self.assertEqual(self.client.get(url, headers=self.headers).status_code, 404)

    def test_administracao_idempotente_e_desfazer(self):
        id = self.med()
        rota = f'/medicamentos/{id}/doses/2026-10-23'
        registro = {'horario': '09:00', 'concluida': True, 'observacao': 'Sem observação clínica'}
        for _ in range(2):
            r = self.client.put(rota, json=registro, headers=self.headers)
            self.assertEqual(r.status_code, 200, r.get_json())
        lista = self.client.get(
            f"/pacientes/{self.user['id']}/administracoes-medicamentos", headers=self.headers)
        self.assertEqual(lista.status_code, 200)
        self.assertEqual(len(lista.get_json()), 1)
        self.assertEqual(lista.get_json()[0]['observacao'], registro['observacao'])
        self.assertEqual(self.client.put(rota, headers=self.headers, json={
            'horario': '09:00', 'concluida': False,
        }).status_code, 200)
        self.assertEqual(self.client.get(
            f"/pacientes/{self.user['id']}/administracoes-medicamentos",
            headers=self.headers).get_json(), [])

    def test_exclusao_bloqueia_registros_dependentes(self):
        r = self.client.delete('/minha-conta', headers=self.headers,
            json={'senha': 'senha incorreta'})
        self.assertEqual(r.status_code, 403)
        self.med()
        r = self.client.delete('/minha-conta', headers=self.headers,
            json={'senha': self.password})
        self.assertEqual(r.status_code, 409, r.get_json())


if __name__ == '__main__':
    unittest.main(verbosity=2)
