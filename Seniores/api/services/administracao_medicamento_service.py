from datetime import datetime

from extensions import db
from models.paciente.administracao_medicamento import AdministracaoMedicamento
from models.paciente.remedio import Remedio
from models.responsavel.responsavel import Responsavel


class AdministracaoMedicamentoService:
    def listar(self, medicamento_id):
        if not Remedio.buscar_por_id(medicamento_id):
            return None, 404
        return db.session.scalars(
            db.select(AdministracaoMedicamento)
            .where(AdministracaoMedicamento.medicamento_id == medicamento_id)
            .order_by(AdministracaoMedicamento.administrado_em.desc())
        ).all(), 200

    def criar(self, medicamento_id, dados):
        medicamento = Remedio.buscar_por_id(medicamento_id)
        if not medicamento:
            return None, 404
        horario = str(dados.get("horario") or "").strip()
        if not horario:
            return None, 400
        responsavel_id = dados.get("responsavel_id")
        if responsavel_id is not None:
            try:
                responsavel_id = int(responsavel_id)
            except (TypeError, ValueError):
                return None, 400
            if not Responsavel.buscar_por_id(responsavel_id):
                return None, 400
        administrado_em = dados.get("administrado_em")
        if administrado_em:
            try:
                administrado_em = datetime.fromisoformat(
                    administrado_em.replace("Z", "+00:00")
                )
            except (AttributeError, TypeError, ValueError):
                return None, 400
        administracao = AdministracaoMedicamento(
            medicamento_id=medicamento_id,
            horario=horario,
            administrado_em=administrado_em or datetime.now(),
            responsavel_id=responsavel_id,
            observacao=(dados.get("observacao") or "").strip() or None,
        )
        try:
            db.session.add(administracao)
            db.session.commit()
            return administracao, 201
        except Exception:
            db.session.rollback()
            return None, 500

    def atualizar(self, administracao_id, dados):
        administracao = db.session.get(AdministracaoMedicamento, administracao_id)
        if not administracao:
            return None, 404
        if "horario" in dados:
            horario = str(dados["horario"] or "").strip()
            if not horario:
                return None, 400
            administracao.horario = horario
        if "observacao" in dados:
            administracao.observacao = (dados["observacao"] or "").strip() or None
        try:
            db.session.commit()
            return administracao, 200
        except Exception:
            db.session.rollback()
            return None, 500

    def deletar(self, administracao_id):
        administracao = db.session.get(AdministracaoMedicamento, administracao_id)
        if not administracao:
            return False, 404
        try:
            db.session.delete(administracao)
            db.session.commit()
            return True, 204
        except Exception:
            db.session.rollback()
            return False, 500
