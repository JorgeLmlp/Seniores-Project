"""Validacao e coordenacao dos recursos de cuidado; o CRUD vive nos models."""

from datetime import datetime

from models.medicamento.remedio import Remedio
from models.cuidador.cuidador import Cuidador
from models.paciente.cuidados import (
    AdministracaoMedicamento, AlertaPanico, ContatoEmergencia, DietaRestricao,
    Incidente, PermissaoMembro, TurnoCuidador,
)
from models.responsavel.responsavel import Responsavel
from repositories import medicamento_repository, paciente_repository, usuario_repository


class CuidadosService:
    CONFIG = {
        "administracoes-medicamentos": (
            AdministracaoMedicamento,
            {"medicamento_id", "confirmado_por"},
        ),
        "incidentes": (Incidente, {"tipo", "data_hora", "descricao"}),
        "contatos-emergencia": (ContatoEmergencia, {"nome", "tipo", "telefone"}),
        "turnos-cuidadores": (
            TurnoCuidador,
            {"cuidador_id", "nome_cuidador", "dias_semana", "hora_inicio", "hora_fim"},
        ),
        "dietas-restricoes": (DietaRestricao, {"restricoes"}),
        "permissoes": (PermissaoMembro, {"membro_tipo", "membro_id", "nivel"}),
        "alertas-panico": (AlertaPanico, set()),
    }

    def _config(self, recurso):
        return self.CONFIG.get(recurso, (None, None))

    def _normalizar(self, recurso, info, parcial=False):
        modelo, obrigatorios = self._config(recurso)
        if not modelo or not isinstance(info, dict):
            return None
        dados = {campo: info[campo] for campo in modelo.CAMPOS_EDITAVEIS if campo in info}
        if not parcial and not obrigatorios.issubset(dados):
            return None
        if parcial and not dados:
            return None

        campos_data = {
            "administracoes-medicamentos": ("horario_previsto", "administrado_em"),
            "incidentes": ("data_hora",),
        }.get(recurso, ())
        for campo in campos_data:
            if campo in dados and dados[campo] is not None:
                try:
                    dados[campo] = datetime.fromisoformat(dados[campo].replace("Z", "+00:00"))
                except (AttributeError, ValueError):
                    return None

        for campo, valor in dados.items():
            if campo in {"confirmado_por", "tipo", "descricao", "nome", "telefone", "nome_cuidador", "hora_inicio", "hora_fim"}:
                if not isinstance(valor, str) or not valor.strip():
                    return None
                dados[campo] = valor.strip()

        if recurso == "administracoes-medicamentos" and "medicamento_id" in dados:
            medicamento = medicamento_repository.buscar_por_id(dados["medicamento_id"])
            if not medicamento:
                return None
            dados["_medicamento"] = medicamento
        elif recurso == "contatos-emergencia" and "tipo" in dados:
            dados["tipo"] = dados["tipo"].lower()
            if dados["tipo"] not in {"medico", "familiar"}:
                return None
        elif recurso == "turnos-cuidadores":
            if "dias_semana" in dados:
                dias = dados["dias_semana"]
                if not isinstance(dias, list) or not dias or not all(isinstance(dia, str) for dia in dias):
                    return None
            if "cuidador_id" in dados:
                cuidador_id = dados["cuidador_id"]
                if not isinstance(cuidador_id, int) or isinstance(cuidador_id, bool):
                    return None
                if not usuario_repository.buscar_por_id(Cuidador, cuidador_id):
                    return None
        elif recurso == "dietas-restricoes":
            for campo in ("restricoes", "alergias"):
                if campo in dados and (not isinstance(dados[campo], list) or not all(isinstance(v, str) for v in dados[campo])):
                    return None
        elif recurso == "permissoes":
            if "nivel" in dados and dados["nivel"] not in {"leitura", "escrita"}:
                return None
            if "membro_tipo" in dados and dados["membro_tipo"] not in {"cuidador", "responsavel"}:
                return None
            if "membro_id" in dados and (not isinstance(dados["membro_id"], int) or isinstance(dados["membro_id"], bool)):
                return None
            tipo = dados.get("membro_tipo")
            membro_id = dados.get("membro_id")
            if tipo and membro_id is not None:
                classe = {"cuidador": Cuidador, "responsavel": Responsavel}.get(tipo)
                if not classe or not usuario_repository.buscar_por_id(classe, membro_id):
                    return None
        elif recurso == "alertas-panico" and "resolvido" in dados and not isinstance(dados["resolvido"], bool):
            return None
        return dados

    def criar(self, recurso, paciente_id, info):
        modelo, _ = self._config(recurso)
        if not modelo:
            return None, 400
        if not paciente_repository.buscar_paciente(paciente_id):
            return None, 404
        dados = self._normalizar(recurso, info)
        if dados is None:
            return None, 400
        medicamento = dados.pop("_medicamento", None)
        if medicamento and medicamento.paciente_id != paciente_id:
            return None, 400
        registro = modelo.criar(paciente_id, dados)
        return (registro, 201) if registro else (None, 500)

    def listar(self, recurso, paciente_id):
        modelo, _ = self._config(recurso)
        if not modelo:
            return None, 400
        if not paciente_repository.buscar_paciente(paciente_id):
            return None, 404
        return paciente_repository.listar_registros(modelo, paciente_id), 200

    def buscar(self, recurso, registro_id):
        modelo, _ = self._config(recurso)
        if not modelo:
            return None, 400
        registro = paciente_repository.buscar_registro(modelo, registro_id)
        return (registro, 200) if registro else (None, 404)

    def atualizar(self, recurso, registro_id, info):
        registro, status = self.buscar(recurso, registro_id)
        if status != 200:
            return None, status
        dados = self._normalizar(recurso, info, parcial=True)
        if dados is None:
            return None, 400
        medicamento = dados.pop("_medicamento", None)
        if medicamento and medicamento.paciente_id != registro.paciente_id:
            return None, 400
        registro = registro.atualizar(dados, registro.CAMPOS_EDITAVEIS)
        return (registro, 200) if registro else (None, 500)

    def deletar(self, recurso, registro_id):
        registro, status = self.buscar(recurso, registro_id)
        if status != 200:
            return None, status
        return (None, 204) if registro.deletar() else (None, 500)
