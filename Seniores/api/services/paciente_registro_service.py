"""Regras CRUD para diario, higiene, estoque, lesoes e financas."""

from datetime import datetime
from decimal import Decimal, InvalidOperation
import base64
import binascii

from models.paciente.checklist_higiene import Checklist_higiene, StatusChecklist
from models.paciente.diario_saude import DiarioSaude, STATUS_DIARIO
from models.paciente.estoque import Estoque
from models.paciente.lesao import Lesao
from models.paciente.registro_financeiro import RegistroFinanceiro
from repositories import paciente_repository


class PacienteRegistroService:
    TAMANHO_MAXIMO_FOTO = 5 * 1024 * 1024
    MIMES_DE_IMAGEM = {"image/jpeg", "image/png", "image/webp", "image/gif"}
    RECURSOS = {
        "diarios-saude": (DiarioSaude, {"humor", "dor", "fome", "mobilidade"}),
        "checklists-higiene": (Checklist_higiene, {"tarefa", "descricao", "frequencia"}),
        "estoque": (Estoque, {"nome", "quantidade"}),
        "lesoes": (Lesao, {"localizacao", "descricao"}),
        "registros-financeiros": (RegistroFinanceiro, {"descricao", "valor", "tipo"}),
    }

    def _modelo(self, recurso):
        return self.RECURSOS.get(recurso, (None, None))[0]

    def _normalizar(self, recurso, info, parcial=False):
        modelo, obrigatorios = self.RECURSOS.get(recurso, (None, None))
        if not modelo:
            return None
        dados = {campo: info[campo] for campo in modelo.CAMPOS_EDITAVEIS if campo in info}
        # Campos binarios sao controlados abaixo; o cliente envia somente Base64.
        if recurso == "lesoes":
            dados.pop("foto", None)
            dados.pop("foto_mime", None)
            if "foto_base64" in info:
                # Marca a alteracao para que uma requisicao contendo somente a foto seja valida.
                dados["foto"] = None
        if not parcial and not obrigatorios.issubset(dados):
            return None
        if not dados:
            return None
        if recurso == "diarios-saude":
            for campo in ("humor", "dor", "fome", "mobilidade"):
                if campo in dados:
                    try:
                        dados[campo] = STATUS_DIARIO(str(dados[campo]).lower())
                    except ValueError:
                        return None
            for campo in ("humor_nivel", "dor_nivel", "apetite_nivel", "mobilidade_nivel"):
                if campo in dados and (
                    not isinstance(dados[campo], int)
                    or isinstance(dados[campo], bool)
                    or not 0 <= dados[campo] <= 10
                ):
                    return None
            if "incidentes" in dados and (
                not isinstance(dados["incidentes"], list)
                or not all(isinstance(item, dict) for item in dados["incidentes"])
            ):
                return None
        elif recurso == "checklists-higiene" and "status" in dados:
            try:
                dados["status"] = StatusChecklist(str(dados["status"]).lower())
            except ValueError:
                return None
        elif recurso == "estoque":
            for campo in ("quantidade", "quantidade_minima"):
                if campo in dados and (not isinstance(dados[campo], int) or isinstance(dados[campo], bool) or dados[campo] < 0):
                    return None
        elif recurso == "lesoes" and "foto_base64" in info:
            foto_base64 = info["foto_base64"]
            if foto_base64 is None:
                dados["foto"] = None
                dados["foto_mime"] = None
            elif not isinstance(foto_base64, str):
                return None
            else:
                # Tambem aceita uma data URL: data:image/png;base64,AAAA...
                cabecalho, separador, conteudo = foto_base64.partition(",")
                if separador and cabecalho.startswith("data:"):
                    mime = cabecalho[5:].split(";", 1)[0]
                else:
                    mime = info.get("foto_mime")
                    conteudo = foto_base64
                if mime not in self.MIMES_DE_IMAGEM:
                    return None
                try:
                    foto = base64.b64decode(conteudo, validate=True)
                except (binascii.Error, ValueError):
                    return None
                if not foto or len(foto) > self.TAMANHO_MAXIMO_FOTO:
                    return None
                dados["foto"] = foto
                dados["foto_mime"] = mime
        elif recurso == "registros-financeiros":
            if "tipo" in dados and str(dados["tipo"]).lower() not in {"receita", "despesa"}:
                return None
            if "tipo" in dados:
                dados["tipo"] = dados["tipo"].lower()
            if "valor" in dados:
                try:
                    dados["valor"] = Decimal(str(dados["valor"]))
                    if dados["valor"] < 0:
                        return None
                except (InvalidOperation, ValueError):
                    return None
            if "data" in dados:
                try:
                    dados["data"] = datetime.fromisoformat(dados["data"].replace("Z", "+00:00"))
                except (AttributeError, ValueError):
                    return None
        return dados

    def criar(self, recurso, paciente_id, info):
        modelo = self._modelo(recurso)
        if not modelo:
            return None, 400
        if not paciente_repository.buscar_paciente(paciente_id):
            return None, 404
        dados = self._normalizar(recurso, info)
        if dados is None:
            return None, 400
        registro = modelo.criar(paciente_id, dados)
        return (registro, 201) if registro else (None, 500)

    def listar(self, recurso, paciente_id):
        modelo = self._modelo(recurso)
        if not modelo:
            return None, 400
        if not paciente_repository.buscar_paciente(paciente_id):
            return None, 404
        return paciente_repository.listar_registros(modelo, paciente_id), 200

    def buscar(self, recurso, registro_id):
        modelo = self._modelo(recurso)
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
        registro = registro.atualizar(dados, registro.CAMPOS_EDITAVEIS)
        return (registro, 200) if registro else (None, 500)

    def deletar(self, recurso, registro_id):
        registro, status = self.buscar(recurso, registro_id)
        if status != 200:
            return None, status
        return (None, 204) if registro.deletar() else (None, 500)
