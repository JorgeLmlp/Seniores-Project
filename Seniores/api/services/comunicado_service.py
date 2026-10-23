from models.paciente.comunicado import Comunicado
from models.paciente.paciente import Paciente
from extensions import db


class ComunicadoService:
    def _destinatarios_permitidos(self, paciente):
        ids = {responsavel.id for responsavel in paciente.responsaveis}
        if paciente.cuidador_id:
            ids.add(paciente.cuidador_id)
        return ids

    def _validar(self, paciente_id, dados):
        paciente = Paciente.buscar_por_id(paciente_id)
        titulo = (dados.get("titulo") or "").strip()
        mensagem = (dados.get("mensagem") or "").strip()
        destinatarios = dados.get("destinatarios")
        if not paciente:
            return None, None, 404
        if not titulo or not mensagem or not isinstance(destinatarios, list):
            return paciente, None, 400
        try:
            destinatarios = {int(item) for item in destinatarios}
        except (TypeError, ValueError):
            return paciente, None, 400
        permitidos = self._destinatarios_permitidos(paciente)
        if not destinatarios or not destinatarios.issubset(permitidos):
            return paciente, None, 400
        return paciente, sorted(destinatarios), 200

    def listar(self, paciente_id):
        if not Paciente.buscar_por_id(paciente_id):
            return None, 404
        return db.session.scalars(
            db.select(Comunicado)
            .where(Comunicado.paciente_id == paciente_id)
            .order_by(Comunicado.criado_em.desc())
        ).all(), 200

    def criar(self, paciente_id, dados):
        paciente, destinatarios, status = self._validar(paciente_id, dados)
        if status != 200:
            return None, status
        comunicado = Comunicado(
            paciente_id=paciente.id,
            titulo=dados["titulo"].strip(),
            mensagem=dados["mensagem"].strip(),
            destinatarios=destinatarios,
            status="enviado",
        )
        try:
            db.session.add(comunicado)
            db.session.commit()
            return comunicado, 201
        except Exception:
            db.session.rollback()
            return None, 500

    def atualizar(self, paciente_id, comunicado_id, dados):
        comunicado = db.session.get(Comunicado, comunicado_id)
        if not comunicado or comunicado.paciente_id != paciente_id:
            return None, 404
        _, destinatarios, status = self._validar(paciente_id, dados)
        if status != 200:
            return None, status
        comunicado.titulo = dados["titulo"].strip()
        comunicado.mensagem = dados["mensagem"].strip()
        comunicado.destinatarios = destinatarios
        try:
            db.session.commit()
            return comunicado, 200
        except Exception:
            db.session.rollback()
            return None, 500

    def deletar(self, paciente_id, comunicado_id):
        comunicado = db.session.get(Comunicado, comunicado_id)
        if not comunicado or comunicado.paciente_id != paciente_id:
            return False, 404
        try:
            db.session.delete(comunicado)
            db.session.commit()
            return True, 204
        except Exception:
            db.session.rollback()
            return False, 500

    def reenviar(self, paciente_id, comunicado_id):
        comunicado = db.session.get(Comunicado, comunicado_id)
        if not comunicado or comunicado.paciente_id != paciente_id:
            return None, 404
        comunicado.status = "enviado"
        try:
            db.session.commit()
            return comunicado, 200
        except Exception:
            db.session.rollback()
            return None, 500
