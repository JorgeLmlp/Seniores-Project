"""Testes funcionais, um por requisito principal da API."""

import base64
import io
import os
import unittest
from unittest.mock import patch
from uuid import uuid4

from extensions import app, db
from models.relacionamento.cuidador_responsavel import CuidadorResponsavel
from models.relacionamento.paciente_responsavel import Paciente_responsavel
from services.paciente.relatorio_service import RelatorioService


class TodasFuncionalidadesTest(unittest.TestCase):
    def setUp(self):
        self.client = app.test_client()
        self.sufixo = uuid4().hex[:10]
        self.recursos = []
        self.paciente_id = self._criar_usuario("paciente", "Idosa Teste")
        self.responsavel_id = self._criar_usuario("responsavel", "Responsavel Teste")
        self.cuidador_id = self._criar_usuario("cuidador", "Cuidador Teste")

    def tearDown(self):
        for recurso, registro_id in reversed(self.recursos):
            resposta = self.client.delete(f"/{recurso}/{registro_id}")
            self.assertEqual(
                resposta.status_code, 204,
                f"Falha ao limpar/excluir {recurso}/{registro_id}: {resposta.get_data(as_text=True)}",
            )
        # Os relacionamentos não possuem endpoint de remoção; a limpeza abaixo
        # afeta apenas os usuários únicos criados por este teste.
        with app.app_context():
            db.session.query(Paciente_responsavel).filter(
                Paciente_responsavel.paciente_id == self.paciente_id
            ).delete(synchronize_session=False)
            db.session.query(CuidadorResponsavel).filter(
                CuidadorResponsavel.cuidador_id == self.cuidador_id
            ).delete(synchronize_session=False)
            db.session.commit()
        self.assertEqual(self.client.delete(f"/users/responsavel/{self.responsavel_id}/").status_code, 204)
        self.assertEqual(self.client.delete(f"/users/cuidador/{self.cuidador_id}/").status_code, 204)
        self.assertEqual(self.client.delete(f"/users/paciente/{self.paciente_id}/").status_code, 204)

    def _criar_usuario(self, tipo, nome):
        marcador = f"{tipo}-{self.sufixo}"
        cpf = f"{tipo[0]}{self.sufixo}"
        resposta = self.client.post("/users/", json={
            "nome": nome,
            "email": f"{marcador}@test.local",
            "senha": "SenhaTeste123!",
            "telefone": "31999999999",
            "cpf": cpf,
            "tipo": tipo,
            **({"idade": 80, "tipo_sanguineo": "A+"} if tipo == "paciente" else {}),
        })
        self.assertEqual(resposta.status_code, 201, resposta.get_json())
        return resposta.get_json()["id"]

    def _criar(self, recurso, dados, paciente_id=None):
        paciente_id = paciente_id or self.paciente_id
        resposta = self.client.post(f"/pacientes/{paciente_id}/{recurso}", json=dados)
        self.assertEqual(resposta.status_code, 201, resposta.get_json())
        registro = resposta.get_json()
        self.recursos.append((recurso, registro["id"]))
        listagem = self.client.get(f"/pacientes/{paciente_id}/{recurso}")
        self.assertEqual(listagem.status_code, 200, listagem.get_data(as_text=True))
        self.assertIn(registro["id"], [item["id"] for item in listagem.get_json()])
        item = self.client.get(f"/{recurso}/{registro['id']}")
        self.assertEqual(item.status_code, 200, item.get_data(as_text=True))
        return registro

    def _excluir_agora(self, recurso, registro_id):
        resposta = self.client.delete(f"/{recurso}/{registro_id}")
        self.assertEqual(resposta.status_code, 204, resposta.get_data(as_text=True))
        self.recursos.remove((recurso, registro_id))

    def test_01_perfil_completo_do_idoso(self):
        resposta = self.client.patch(f"/users/paciente/{self.paciente_id}/", json={
            "idade": 81,
            "tipo_sanguineo": "o-",
            "preferencias": {"musicas": ["samba"], "hobbies": ["xadrez"]},
        })
        self.assertEqual(resposta.status_code, 200, resposta.get_json())
        perfil = self.client.get(f"/users/paciente/{self.paciente_id}/")
        self.assertEqual(perfil.status_code, 200)
        self.assertEqual(perfil.get_json()["idade"], 81)
        self.assertEqual(perfil.get_json()["tipo_sanguineo"], "O-")
        self.assertEqual(perfil.get_json()["preferencias"]["hobbies"], ["xadrez"])
        invalido = self.client.patch(
            f"/users/paciente/{self.paciente_id}/", json={"idade": 200}
        )
        self.assertEqual(invalido.status_code, 400)

    def test_02_crud_de_medicamentos(self):
        medicamento = self._criar("medicamentos", {
            "nome": "Losartana", "dosagem": "50 mg", "frequencia": "diaria",
            "quantidade": 30,
        })
        consulta = self.client.get(f"/medicamentos/{medicamento['id']}")
        self.assertEqual(consulta.status_code, 200)
        alteracao = self.client.patch(
            f"/medicamentos/{medicamento['id']}", json={"quantidade": 25}
        )
        self.assertEqual(alteracao.status_code, 200)
        self.assertEqual(alteracao.get_json()["quantidade"], 25)
        listagem = self.client.get(f"/pacientes/{self.paciente_id}/medicamentos")
        self.assertIn(medicamento["id"], [item["id"] for item in listagem.get_json()])
        self._excluir_agora("medicamentos", medicamento["id"])
        self.assertEqual(self.client.get(f"/medicamentos/{medicamento['id']}").status_code, 404)
        sem_frequencia = self.client.post(
            f"/pacientes/{self.paciente_id}/medicamentos",
            json={"nome": "AAS", "dosagem": "100 mg"},
        )
        self.assertEqual(sem_frequencia.status_code, 400)

    def test_03_alerta_sonoro_por_medicamento(self):
        medicamento = self._criar("medicamentos", {
            "nome": "Metformina", "dosagem": "500 mg", "frequencia": "12 horas",
            "horarios": ["08:00", "20:00"], "alertas": ["apos refeicao"],
            "alerta_sonoro": True, "som_alerta": "campainha",
        })
        self.assertTrue(medicamento["alerta_sonoro"])
        self.assertEqual(medicamento["som_alerta"], "campainha")
        invalido = self.client.patch(
            f"/medicamentos/{medicamento['id']}", json={"alerta_sonoro": "sim"}
        )
        self.assertEqual(invalido.status_code, 400)

    def test_04_confirmacao_da_administracao(self):
        medicamento = self._criar("medicamentos", {
            "nome": "AAS", "dosagem": "100 mg", "frequencia": "diaria",
        })
        administracao = self._criar("administracoes-medicamentos", {
            "medicamento_id": medicamento["id"],
            "horario_previsto": "2026-10-10T08:00:00",
            "administrado_em": "2026-10-10T08:03:00",
            "confirmado_por": "Cuidador Teste",
        })
        self.assertEqual(administracao["medicamento_id"], medicamento["id"])
        alteracao = self.client.patch(
            f"/administracoes-medicamentos/{administracao['id']}",
            json={"observacao": "Sem intercorrencias"},
        )
        self.assertEqual(alteracao.status_code, 200)
        self.assertEqual(alteracao.get_json()["observacao"], "Sem intercorrencias")

    def test_05_anotacao_de_consulta_futura(self):
        consulta = self._criar("consultas", {
            "nomeDoutor": "Dra. Ana", "especialidade": "Cardiologia",
            "local": "Clinica Central", "dataHora": "2026-12-01T10:00:00",
        })
        self.assertEqual(consulta["dados"]["local"], "Clinica Central")
        alteracao = self.client.patch(
            f"/consultas/{consulta['id']}", json={"concluida": True}
        )
        self.assertEqual(alteracao.status_code, 200)
        self.assertTrue(alteracao.get_json()["dados"]["concluida"])
        sem_local = self.client.post(f"/pacientes/{self.paciente_id}/consultas", json={
            "nomeDoutor": "Dr. B", "especialidade": "Clinica",
            "dataHora": "2026-12-02T10:00:00",
        })
        self.assertEqual(sem_local.status_code, 400)

    def test_06_anexo_de_foto_ou_pdf_de_exame(self):
        resposta = self.client.post(
            f"/pacientes/{self.paciente_id}/exames-documentos",
            data={
                "nome": "Hemograma",
                "data_exame": "2026-10-09T09:00:00",
                "arquivo": (io.BytesIO(b"%PDF-1.4 exame"), "hemograma.pdf", "application/pdf"),
            },
            content_type="multipart/form-data",
        )
        self.assertEqual(resposta.status_code, 201, resposta.get_json())
        exame = resposta.get_json()
        self.recursos.append(("exames-documentos", exame["id"]))
        download = self.client.get(f"/exames-documentos/{exame['id']}/arquivo")
        self.assertEqual(download.status_code, 200)
        self.assertEqual(download.mimetype, "application/pdf")
        self.assertEqual(download.data, b"%PDF-1.4 exame")
        formato_invalido = self.client.post(
            f"/pacientes/{self.paciente_id}/exames-documentos",
            data={"nome": "Texto", "arquivo": (io.BytesIO(b"x"), "x.txt", "text/plain")},
            content_type="multipart/form-data",
        )
        self.assertEqual(formato_invalido.status_code, 400)

    def test_07_crud_de_sinais_vitais(self):
        sinal = self._criar("sinais-vitais", {
            "data": "2026-10-10T09:00:00", "pressao_art": "120/80",
            "glicemia": "95", "temperatura": "36.5",
        })
        consulta = self.client.get(f"/sinais-vitais/{sinal['id']}")
        self.assertEqual(consulta.status_code, 200)
        alteracao = self.client.patch(
            f"/sinais-vitais/{sinal['id']}", json={"glicemia": "100"}
        )
        self.assertEqual(alteracao.get_json()["glicemia"], "100")
        vazio = self.client.post(f"/pacientes/{self.paciente_id}/sinais-vitais", json={})
        self.assertEqual(vazio.status_code, 400)

    def test_08_grafico_de_evolucao_dos_sinais(self):
        self._criar("sinais-vitais", {"data": "2026-10-02T09:00:00", "glicemia": "90"})
        self._criar("sinais-vitais", {"data": "2026-10-03T09:00:00", "glicemia": "95"})
        resposta = self.client.get(f"/pacientes/{self.paciente_id}/sinais-vitais/evolucao")
        self.assertEqual(resposta.status_code, 200)
        self.assertEqual(resposta.get_json()["series"]["glicemia"], ["90", "95"])
        self.assertEqual(len(resposta.get_json()["labels"]), 2)

    def test_09_crud_de_incidentes(self):
        incidente = self._criar("incidentes", {
            "tipo": "queda", "data_hora": "2026-10-11T18:00:00",
            "descricao": "Queda sem lesao", "gravidade": "leve",
        })
        self.assertEqual(self.client.get(f"/incidentes/{incidente['id']}").status_code, 200)
        alteracao = self.client.patch(
            f"/incidentes/{incidente['id']}", json={"providencias": "Observacao por 2 horas"}
        )
        self.assertEqual(alteracao.status_code, 200)
        self.assertEqual(alteracao.get_json()["providencias"], "Observacao por 2 horas")

    def test_10_crud_de_estoque(self):
        item = self._criar("estoque", {
            "nome": "Luvas", "quantidade": 20, "quantidade_minima": 5,
        })
        self.assertFalse(item["estoque_baixo"])
        alteracao = self.client.patch(f"/estoque/{item['id']}", json={"quantidade": 12})
        self.assertEqual(alteracao.status_code, 200)
        self.assertEqual(alteracao.get_json()["quantidade"], 12)
        negativo = self.client.patch(f"/estoque/{item['id']}", json={"quantidade": -1})
        self.assertEqual(negativo.status_code, 400)

    def test_11_notificacao_automatica_de_estoque_baixo(self):
        baixo = self._criar("estoque", {
            "nome": "Fraldas", "quantidade": 2, "quantidade_minima": 5,
        })
        self._criar("estoque", {"nome": "Gazes", "quantidade": 20, "quantidade_minima": 5})
        resposta = self.client.get(f"/pacientes/{self.paciente_id}/alertas-estoque")
        self.assertEqual(resposta.status_code, 200)
        self.assertEqual(len(resposta.get_json()), 1)
        self.assertEqual(resposta.get_json()[0]["estoque_id"], baixo["id"])
        self.assertEqual(resposta.get_json()[0]["tipo"], "estoque_baixo")

    def test_12_relatorio_mensal_consolidado_em_pdf(self):
        self._criar("incidentes", {
            "tipo": "queda", "data_hora": "2026-10-10T10:00:00",
            "descricao": "Incidente de outubro",
        })
        self._criar("incidentes", {
            "tipo": "queda", "data_hora": "2026-09-10T10:00:00",
            "descricao": "Incidente de setembro",
        })
        resposta = self.client.get(
            f"/pacientes/{self.paciente_id}/relatorio.pdf?mes=10&ano=2026"
        )
        self.assertEqual(resposta.status_code, 200)
        self.assertEqual(resposta.mimetype, "application/pdf")
        self.assertTrue(resposta.data.startswith(b"%PDF-1.4"))
        self.assertIn(b"Incidente de outubro", resposta.data)
        self.assertNotIn(b"Incidente de setembro", resposta.data)
        intervalo = self.client.get(
            f"/pacientes/{self.paciente_id}/relatorio.pdf?inicio=2026-09-01&fim=2026-09-30"
        )
        self.assertEqual(intervalo.status_code, 200)
        self.assertIn(b"Incidente de setembro", intervalo.data)
        self.assertNotIn(b"Incidente de outubro", intervalo.data)
        completo = self.client.get(
            f"/pacientes/{self.paciente_id}/relatorio.pdf?todo_historico=true"
        )
        self.assertIn(b"Incidente de setembro", completo.data)
        self.assertIn(b"Incidente de outubro", completo.data)
        self.assertEqual(
            self.client.get(
                f"/pacientes/{self.paciente_id}/relatorio.pdf?inicio=2026-10-02&fim=2026-10-01"
            ).status_code,
            400,
        )
        self.assertEqual(
            self.client.get(f"/pacientes/{self.paciente_id}/relatorio.pdf?mes=13&ano=2026").status_code,
            400,
        )

    def test_13_crud_de_contatos_de_emergencia(self):
        contato = self._criar("contatos-emergencia", {
            "nome": "Dr. Carlos", "tipo": "medico", "telefone": "31988887777",
            "especialidade": "Geriatria", "email": "carlos@test.local",
        })
        self.assertEqual(contato["tipo"], "medico")
        alteracao = self.client.patch(
            f"/contatos-emergencia/{contato['id']}", json={"telefone": "31977776666"}
        )
        self.assertEqual(alteracao.status_code, 200)
        invalido = self.client.post(f"/pacientes/{self.paciente_id}/contatos-emergencia", json={
            "nome": "Empresa", "tipo": "empresa", "telefone": "123",
        })
        self.assertEqual(invalido.status_code, 400)

    def test_14_registro_do_botao_de_panico(self):
        alerta = self._criar("alertas-panico", {
            "localizacao": "quarto", "mensagem": "Preciso de ajuda",
        })
        self.assertFalse(alerta["resolvido"])
        self.assertIsNotNone(alerta["acionado_em"])
        resolvido = self.client.patch(
            f"/alertas-panico/{alerta['id']}", json={"resolvido": True}
        )
        self.assertEqual(resolvido.status_code, 200)
        self.assertTrue(resolvido.get_json()["resolvido"])

    def test_15_diario_de_humor_apetite_e_sono(self):
        diario = self._criar("diarios-saude", {
            "humor": "bom", "dor": "razoavel", "fome": "bom",
            "mobilidade": "bom", "sono": "ruim", "sono_nivel": 4,
            "apetite_nivel": 8,
        })
        self.assertEqual(diario["sono"], "ruim")
        self.assertEqual(diario["apetite_nivel"], 8)
        invalido = self.client.patch(
            f"/diarios-saude/{diario['id']}", json={"sono_nivel": 11}
        )
        self.assertEqual(invalido.status_code, 400)

    def test_16_crud_da_escala_de_turnos(self):
        turno = self._criar("turnos-cuidadores", {
            "cuidador_id": self.cuidador_id, "nome_cuidador": "Cuidador Teste",
            "dias_semana": ["segunda", "terca"], "hora_inicio": "08:00",
            "hora_fim": "18:00",
        })
        self.assertEqual(turno["dias_semana"], ["segunda", "terca"])
        alteracao = self.client.patch(
            f"/turnos-cuidadores/{turno['id']}", json={"hora_fim": "19:00"}
        )
        self.assertEqual(alteracao.status_code, 200)
        self.assertEqual(alteracao.get_json()["hora_fim"], "19:00")

    def test_17_preferencias_musicais_e_hobbies(self):
        preferencias = {
            "musicas": ["MPB", "samba"],
            "hobbies": ["jardinagem", "leitura"],
        }
        resposta = self.client.patch(
            f"/users/paciente/{self.paciente_id}/", json={"preferencias": preferencias}
        )
        self.assertEqual(resposta.status_code, 200)
        self.assertEqual(resposta.get_json()["preferencias"], preferencias)
        invalido = self.client.patch(
            f"/users/paciente/{self.paciente_id}/", json={"preferencias": "samba"}
        )
        self.assertEqual(invalido.status_code, 400)

    def test_18_exportacao_do_historico_por_email(self):
        with patch.dict(os.environ, {
            "SMTP_HOST": "smtp.test.local", "SMTP_PORT": "587",
            "SMTP_FROM": "seniores@test.local", "SMTP_USER": "user",
            "SMTP_PASSWORD": "secret", "SMTP_TLS": "1",
        }, clear=False), patch("services.paciente.relatorio_service.smtplib.SMTP") as smtp:
            resposta = self.client.post(
                f"/pacientes/{self.paciente_id}/historico/email",
                json={"email": "medico@test.local", "mes": 10, "ano": 2026},
            )
        self.assertEqual(resposta.status_code, 202, resposta.get_json())
        instancia = smtp.return_value.__enter__.return_value
        instancia.starttls.assert_called_once()
        instancia.login.assert_called_once_with("user", "secret")
        instancia.send_message.assert_called_once()
        mensagem = instancia.send_message.call_args.args[0]
        self.assertEqual(mensagem["To"], "medico@test.local")
        self.assertEqual(mensagem.get_payload()[1].get_content_type(), "application/pdf")
        invalido = self.client.post(
            f"/pacientes/{self.paciente_id}/historico/email", json={"email": "invalido"}
        )
        self.assertEqual(invalido.status_code, 400)

    def test_19_crud_de_permissoes(self):
        permissao = self._criar("permissoes", {
            "membro_tipo": "responsavel", "membro_id": self.responsavel_id,
            "nivel": "leitura",
        })
        self.assertEqual(permissao["nivel"], "leitura")
        alteracao = self.client.patch(
            f"/permissoes/{permissao['id']}", json={"nivel": "escrita"}
        )
        self.assertEqual(alteracao.status_code, 200)
        self.assertEqual(alteracao.get_json()["nivel"], "escrita")
        inexistente = self.client.post(f"/pacientes/{self.paciente_id}/permissoes", json={
            "membro_tipo": "responsavel", "membro_id": 999999, "nivel": "leitura",
        })
        self.assertEqual(inexistente.status_code, 400)

    def test_20_crud_de_dieta_e_restricoes(self):
        dieta = self._criar("dietas-restricoes", {
            "descricao_dieta": "Dieta hipossodica", "restricoes": ["sal"],
            "alergias": ["lactose"], "observacoes": "Oferecer agua",
        })
        self.assertEqual(dieta["restricoes"], ["sal"])
        alteracao = self.client.patch(
            f"/dietas-restricoes/{dieta['id']}", json={"restricoes": ["sal", "acucar"]}
        )
        self.assertEqual(alteracao.status_code, 200)
        self.assertEqual(alteracao.get_json()["restricoes"], ["sal", "acucar"])
        invalido = self.client.post(f"/pacientes/{self.paciente_id}/dietas-restricoes", json={
            "restricoes": "sal"
        })
        self.assertEqual(invalido.status_code, 400)

    def test_21_login_e_relacionamentos_complementares(self):
        login = self.client.post("/users/login/", json={
            "email": f"paciente-{self.sufixo}@test.local", "senha": "SenhaTeste123!"
        })
        self.assertEqual(login.status_code, 200)
        self.assertNotIn("password", login.get_json())
        vinculo = self.client.post("/registrar_relacionamento", json={
            "cpfPaciente": f"p{self.sufixo}",
            "cpfResponsavel": f"r{self.sufixo}",
        })
        self.assertIn(vinculo.status_code, (200, 201))
        cuidador = self.client.post("/relacionamentos/paciente-cuidador", json={
            "cpfPaciente": f"p{self.sufixo}",
            "cpfCuidador": f"c{self.sufixo}",
        })
        self.assertEqual(cuidador.status_code, 200)
        responsavel = self.client.post("/relacionamentos/cuidador-responsavel", json={
            "cpfCuidador": f"c{self.sufixo}",
            "cpfResponsavel": f"r{self.sufixo}",
        })
        self.assertIn(responsavel.status_code, (200, 201))

    def test_22_higiene_lesoes_e_financeiro_complementares(self):
        higiene = self._criar("checklists-higiene", {
            "tarefa": "Banho", "descricao": "Banho da manha", "frequencia": "diaria",
        })
        self.assertEqual(higiene["status"], "pendente")
        foto = base64.b64encode(b"imagem-teste").decode()
        lesao = self._criar("lesoes", {
            "localizacao": "Braco", "descricao": "Escoriacao",
            "foto_base64": foto, "foto_mime": "image/png",
        })
        self.assertIsNotNone(lesao["foto_url"])
        self.assertEqual(self.client.get(f"/lesoes/{lesao['id']}/foto").data, b"imagem-teste")
        financeiro = self._criar("registros-financeiros", {
            "descricao": "Medicamento", "valor": 89.90, "tipo": "despesa",
        })
        self.assertEqual(financeiro["tipo"], "despesa")

    def test_23_agenda_destinatarios_e_comunicados_legados(self):
        agenda = self._criar("cuidadores", {
            "nome": "Ana", "funcao": "Diurna",
            "frequencia": [False, True, True, True, True, True, False],
            "horaInicio": "08:00", "horaFim": "18:00",
        })
        self.assertEqual(agenda["dados"]["horaFim"], "18:00")
        destinatario = self._criar("destinatarios", {
            "nome": "Carlos", "vinculo": "Filho", "telefone": "31988887777",
        })
        comunicado = self._criar("comunicados", {
            "mensagem": "Consulta alterada",
            "destinatarios": [destinatario["dados"]],
        })
        self.assertEqual(comunicado["dados"]["mensagem"], "Consulta alterada")

    def test_24_pdf_cria_paginas_adicionais_quando_necessario(self):
        pdf = RelatorioService._pdf([f"Linha {indice}" for indice in range(120)])
        self.assertTrue(pdf.startswith(b"%PDF-1.4"))
        self.assertIn(b"/Count 3", pdf)


if __name__ == "__main__":
    unittest.main()
