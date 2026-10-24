import io
import unittest
from uuid import uuid4

from extensions import app


class FuncionalidadesApiTest(unittest.TestCase):
    def setUp(self):
        self.client = app.test_client()
        sufixo = uuid4().hex[:12]
        resposta = self.client.post("/users/", json={
            "nome": "Idoso Completo", "email": f"idoso-{sufixo}@teste.local",
            "senha": "Senha123!", "telefone": "31999999999", "cpf": sufixo,
            "tipo": "paciente", "idade": 79, "tipo_sanguineo": "O+",
            "preferencias": {"musicas": ["samba"], "hobbies": ["xadrez"]},
        })
        self.assertEqual(resposta.status_code, 201, resposta.get_json())
        self.paciente_id = resposta.get_json()["id"]
        responsavel = self.client.post("/users/", json={
            "nome": "Responsavel Teste", "email": f"resp-{sufixo}@teste.local",
            "senha": "Senha123!", "telefone": "31988888888", "cpf": f"r{sufixo}",
            "tipo": "responsavel",
        })
        self.assertEqual(responsavel.status_code, 201, responsavel.get_json())
        self.responsavel_id = responsavel.get_json()["id"]
        cuidador = self.client.post("/users/", json={
            "nome": "Cuidador Teste", "email": f"cuidador-{sufixo}@teste.local",
            "senha": "Senha123!", "telefone": "31977777777", "cpf": f"c{sufixo}",
            "tipo": "cuidador",
        })
        self.assertEqual(cuidador.status_code, 201, cuidador.get_json())
        self.cuidador_id = cuidador.get_json()["id"]
        self.criados = []

    def tearDown(self):
        for recurso, registro_id in reversed(self.criados):
            self.client.delete(f"/{recurso}/{registro_id}")
        self.client.delete(f"/users/responsavel/{self.responsavel_id}/")
        self.client.delete(f"/users/cuidador/{self.cuidador_id}/")
        self.client.delete(f"/users/paciente/{self.paciente_id}/")

    def criar(self, recurso, dados):
        resposta = self.client.post(f"/pacientes/{self.paciente_id}/{recurso}", json=dados)
        self.assertEqual(resposta.status_code, 201, resposta.get_json())
        registro_id = resposta.get_json()["id"]
        self.criados.append((recurso, registro_id))
        return resposta.get_json()

    def test_fluxo_completo_das_funcionalidades(self):
        perfil = self.client.get(f"/users/paciente/{self.paciente_id}/").get_json()
        self.assertEqual(perfil["idade"], 79)
        self.assertEqual(perfil["tipo_sanguineo"], "O+")
        self.assertEqual(perfil["preferencias"]["hobbies"], ["xadrez"])

        medicamento = self.criar("medicamentos", {
            "nome": "Losartana", "dosagem": "50 mg", "frequencia": "diaria",
            "horarios": ["08:00"], "alerta_sonoro": True, "som_alerta": "campainha",
        })
        administracao = self.criar("administracoes-medicamentos", {
            "medicamento_id": medicamento["id"], "confirmado_por": "Cuidadora Ana",
            "administrado_em": "2026-10-14T08:01:00",
        })
        self.assertEqual(administracao["medicamento_id"], medicamento["id"])

        consulta = self.criar("consultas", {
            "nomeDoutor": "Dra. Ana", "especialidade": "Cardiologia",
            "local": "Clinica Central", "dataHora": "2026-12-01T10:00:00",
        })
        self.assertEqual(consulta["dados"]["local"], "Clinica Central")

        incidente = self.criar("incidentes", {
            "tipo": "queda", "data_hora": "2026-10-13T18:00:00",
            "descricao": "Queda sem ferimento", "gravidade": "leve",
        })
        self.assertEqual(incidente["tipo"], "queda")
        self.criar("incidentes", {
            "tipo": "intercorrencia", "data_hora": "2026-09-13T18:00:00",
            "descricao": "Fora do mes solicitado",
        })

        estoque = self.criar("estoque", {"nome": "Fraldas", "quantidade": 2, "quantidade_minima": 5})
        alertas = self.client.get(f"/pacientes/{self.paciente_id}/alertas-estoque")
        self.assertEqual(alertas.status_code, 200)
        self.assertEqual(alertas.get_json()[0]["estoque_id"], estoque["id"])

        self.criar("diarios-saude", {
            "humor": "bom", "dor": "bom", "fome": "razoavel", "mobilidade": "bom",
            "sono": "ruim", "sono_nivel": 4,
        })
        self.criar("contatos-emergencia", {
            "nome": "Carlos", "tipo": "familiar", "vinculo": "filho", "telefone": "31988887777",
        })
        self.criar("turnos-cuidadores", {
            "cuidador_id": self.cuidador_id,
            "nome_cuidador": "Ana", "dias_semana": ["segunda", "terca"],
            "hora_inicio": "08:00", "hora_fim": "18:00",
        })
        self.criar("dietas-restricoes", {
            "descricao_dieta": "Dieta hipossodica", "restricoes": ["sal"], "alergias": ["lactose"],
        })
        self.criar("permissoes", {"membro_tipo": "responsavel", "membro_id": self.responsavel_id, "nivel": "leitura"})
        self.criar("alertas-panico", {"localizacao": "quarto", "mensagem": "Preciso de ajuda"})

        sinal = self.criar("sinais-vitais", {"pressao_art": "12/8", "glicemia": "95", "temperatura": "36.5"})
        evolucao = self.client.get(f"/pacientes/{self.paciente_id}/sinais-vitais/evolucao")
        self.assertEqual(evolucao.status_code, 200)
        self.assertEqual(evolucao.get_json()["series"]["glicemia"], ["95"])

        upload = self.client.post(
            f"/pacientes/{self.paciente_id}/exames-documentos",
            data={"nome": "Hemograma", "arquivo": (io.BytesIO(b"%PDF-1.4 teste"), "hemograma.pdf", "application/pdf")},
            content_type="multipart/form-data",
        )
        self.assertEqual(upload.status_code, 201, upload.get_json())
        exame_id = upload.get_json()["id"]
        self.criados.append(("exames-documentos", exame_id))
        arquivo = self.client.get(f"/exames-documentos/{exame_id}/arquivo")
        self.assertEqual(arquivo.status_code, 200)
        self.assertEqual(arquivo.mimetype, "application/pdf")

        relatorio = self.client.get(
            f"/pacientes/{self.paciente_id}/relatorio.pdf?mes=10&ano=2026"
        )
        self.assertEqual(relatorio.status_code, 200)
        self.assertTrue(relatorio.data.startswith(b"%PDF-1.4"))
        self.assertIn(b"Queda sem ferimento", relatorio.data)
        self.assertNotIn(b"Fora do mes solicitado", relatorio.data)


if __name__ == "__main__":
    unittest.main()
