from models.paciente.emergencia import AlertaEmergencia, ContatoEmergencia
from models.paciente.paciente import Paciente


class EmergenciaService:
    CONTATO_CAMPOS = {"nome", "telefone", "parentesco", "observacoes"}
    ALERTA_CAMPOS = {"localizacao", "observacoes", "status"}

    def listar_contatos(self, paciente_id):
        if not Paciente.buscar_por_id(paciente_id):
            return None, 404
        return ContatoEmergencia.listar_por_paciente(paciente_id), 200

    def criar_contato(self, paciente_id, info):
        if not Paciente.buscar_por_id(paciente_id):
            return None, 404
        dados = self._dados(info, self.CONTATO_CAMPOS)
        if not dados.get("nome") or not dados.get("telefone"):
            return None, 400
        contato = ContatoEmergencia.criar(paciente_id, dados)
        return (contato, 201) if contato else (None, 500)

    def buscar_contato(self, contato_id):
        contato = ContatoEmergencia.buscar_por_id(contato_id)
        return (contato, 200) if contato else (None, 404)

    def atualizar_contato(self, contato_id, info):
        contato, status = self.buscar_contato(contato_id)
        if status != 200:
            return None, status
        dados = self._dados(info, self.CONTATO_CAMPOS)
        if ("nome" in dados and not dados["nome"]) or ("telefone" in dados and not dados["telefone"]):
            return None, 400
        contato = contato.atualizar(dados)
        return (contato, 200) if contato else (None, 500)

    def deletar_contato(self, contato_id):
        contato, status = self.buscar_contato(contato_id)
        if status != 200:
            return None, status
        return (None, 204) if contato.deletar() else (None, 500)

    def listar_alertas(self, paciente_id):
        if not Paciente.buscar_por_id(paciente_id):
            return None, 404
        return AlertaEmergencia.listar_por_paciente(paciente_id), 200

    def criar_alerta(self, paciente_id, info):
        if not Paciente.buscar_por_id(paciente_id):
            return None, 404
        dados = self._dados(info, {"localizacao", "observacoes"})
        dados["status"] = "aberto"
        alerta = AlertaEmergencia.criar(paciente_id, dados)
        return (alerta, 201) if alerta else (None, 500)

    def resolver_alerta(self, alerta_id):
        alerta = AlertaEmergencia.buscar_por_id(alerta_id)
        if not alerta:
            return None, 404
        alerta = alerta.atualizar({"status": "resolvido"})
        return (alerta, 200) if alerta else (None, 500)

    @staticmethod
    def _dados(info, campos):
        return {
            campo: info[campo]
            for campo in campos
            if campo in info and info[campo] is not None
        }
