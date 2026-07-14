from extensions import db
from models.relacionamento.paciente_responsavel import Paciente_responsavel
from repositories.relationship_repository import pesquisar_por_cpf


class RelationshipService:
    def vincular_responsavel(self, info):
        cpf_responsavel = info.get("cpfResponsavel")
        cpf_paciente = info.get("cpfPaciente")
        if not cpf_responsavel or not cpf_paciente:
            return None, 400

        responsavel = pesquisar_por_cpf("responsavel", cpf_responsavel)
        paciente = pesquisar_por_cpf("paciente", cpf_paciente)
        if not responsavel or not paciente:
            return None, 404

        # Mantém o responsável principal acessível diretamente em pacientes.
        paciente.responsavel_id = responsavel.id

        vinculo = db.session.get(
            Paciente_responsavel, (paciente.id, responsavel.id)
        )
        if vinculo:
            db.session.commit()
            return vinculo, 200

        vinculo = Paciente_responsavel(
            paciente_id=paciente.id,
            responsavel_id=responsavel.id,
        )
        try:
            db.session.add(vinculo)
            db.session.commit()
        except Exception:
            db.session.rollback()
            return None, 500

        return vinculo, 201
