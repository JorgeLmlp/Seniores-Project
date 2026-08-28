from datetime import datetime

from extensions import db
from models.paciente.paciente import Paciente
from models.paciente.registro_app import RegistroApp


class RegistroAppService:
    RECURSOS = {"consultas", "exames", "cuidadores", "destinatarios", "comunicados"}

    def _recurso_valido(self, recurso):
        return recurso in self.RECURSOS

    def criar(self, recurso, paciente_id, dados):
        if not self._recurso_valido(recurso) or not isinstance(dados, dict) or not dados:
            return None, 400
        if not Paciente.buscar_por_id(paciente_id):
            return None, 404
        registro = RegistroApp(
            paciente_id=paciente_id, recurso=recurso, dados=dados
        ).salvar()
        return (registro, 201) if registro else (None, 500)

    def listar(self, recurso, paciente_id):
        if not self._recurso_valido(recurso):
            return None, 400
        if not Paciente.buscar_por_id(paciente_id):
            return None, 404
        consulta = (
            db.select(RegistroApp)
            .where(
                RegistroApp.paciente_id == paciente_id,
                RegistroApp.recurso == recurso,
            )
            .order_by(RegistroApp.data_criacao.desc())
        )
        return db.session.scalars(consulta).all(), 200

    def buscar(self, recurso, registro_id):
        if not self._recurso_valido(recurso):
            return None, 400
        registro = db.session.get(RegistroApp, registro_id)
        if not registro or registro.recurso != recurso:
            return None, 404
        return registro, 200

    def atualizar(self, recurso, registro_id, dados):
        registro, status = self.buscar(recurso, registro_id)
        if status != 200:
            return None, status
        if not isinstance(dados, dict) or not dados:
            return None, 400
        registro.dados = {**registro.dados, **dados}
        registro.data_alteracao = datetime.now()
        registro = registro.salvar()
        return (registro, 200) if registro else (None, 500)

    def deletar(self, recurso, registro_id):
        registro, status = self.buscar(recurso, registro_id)
        if status != 200:
            return None, status
        return (None, 204) if registro.deletar() else (None, 500)

