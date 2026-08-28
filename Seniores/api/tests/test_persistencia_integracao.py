import unittest
from uuid import uuid4

from extensions import app


class PersistenciaIntegracaoTest(unittest.TestCase):
    """Smoke test real; usa o MySQL indicado por DATABASE_URL e limpa seus dados."""

    def setUp(self):
        self.client = app.test_client()
        sufixo = uuid4().hex[:12]
        resposta = self.client.post(
            "/users/",
            json={
                "nome": "Paciente Teste Integracao",
                "email": f"persistencia-{sufixo}@seniores.test",
                "senha": "SenhaTeste123!",
                "telefone": "31999999999",
                "cpf": sufixo,
                "tipo": "paciente",
            },
        )
        self.assertEqual(resposta.status_code, 201, resposta.get_json())
        self.paciente_id = resposta.get_json()["id"]
        self.itens_criados = []

    def tearDown(self):
        for recurso, registro_id in reversed(self.itens_criados):
            self.client.delete(f"/{recurso}/{registro_id}")
        self.client.delete(f"/users/paciente/{self.paciente_id}/")

    def _criar_e_confirmar(self, recurso, dados):
        resposta = self.client.post(
            f"/pacientes/{self.paciente_id}/{recurso}", json=dados
        )
        self.assertEqual(resposta.status_code, 201, resposta.get_json())
        registro_id = resposta.get_json()["id"]
        self.itens_criados.append((recurso, registro_id))

        listagem = self.client.get(
            f"/pacientes/{self.paciente_id}/{recurso}"
        )
        self.assertEqual(listagem.status_code, 200, listagem.get_json())
        self.assertIn(registro_id, [item["id"] for item in listagem.get_json()])

    def test_persiste_medicamento_diario_e_registro_flexivel(self):
        self._criar_e_confirmar(
            "medicamentos",
            {
                "nome": "Medicamento Teste",
                "dosagem": "10 mg",
                "frequencia": "diário",
                "horarios": ["08:00"],
                "alertas": ["Com água"],
            },
        )
        self._criar_e_confirmar(
            "diarios-saude",
            {
                "humor": "bom",
                "dor": "razoavel",
                "fome": "bom",
                "mobilidade": "bom",
                "humor_nivel": 9,
                "dor_nivel": 4,
                "apetite_nivel": 8,
                "mobilidade_nivel": 7,
                "incidentes": [],
            },
        )
        self._criar_e_confirmar(
            "consultas",
            {
                "nomeDoutor": "Dra. Teste",
                "especialidade": "Clínica geral",
                "dataHora": "2026-08-28T10:00:00",
            },
        )


if __name__ == "__main__":
    unittest.main()
