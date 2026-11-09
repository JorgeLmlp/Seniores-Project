import os
import unittest
from unittest.mock import patch

from extensions import app


class DocumentosLegaisTest(unittest.TestCase):
    def test_documentos_disponiveis_antes_do_login(self):
        with patch.dict(os.environ, {'API_TESTING': '0'}):
            client = app.test_client()
            for rota, arquivo in [('/termos-de-uso', 'termos-de-uso'),
                                  ('/termo-consentimento', 'consentimento')]:
                resposta = client.get(rota)
                self.assertEqual(resposta.status_code, 200)
                doc = resposta.get_json()
                self.assertEqual(doc['contato'], 'jorgelmlp2@gmail.com')
                self.assertIn('jorgelmlp2@gmail.com', str(doc['blocos']))
                self.assertEqual(doc['versao'], '2026-11-09')
            self.assertEqual(client.get('/').status_code, 200)
            self.assertEqual(client.get('/pacientes/1/medicamentos').status_code, 401)
            self.assertEqual(client.post('/termos-de-uso').status_code, 401)

    def test_consentimento_inclui_todas_as_clausulas_do_pdf(self):
        doc = app.test_client().get('/termo-consentimento').get_json()
        texto = doc['blocos'][0]['texto']
        self.assertIn('CLÁUSULA PRIMEIRA', texto)
        self.assertIn('CLÁUSULA DÉCIMA SEGUNDA', texto)
        self.assertIn('RESPONSÁVEL LEGAL', texto)
