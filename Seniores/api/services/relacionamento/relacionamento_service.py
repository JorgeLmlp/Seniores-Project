from models.cuidador.cuidador import Cuidador
from models.paciente.paciente import Paciente
from models.relacionamento.cuidador_responsavel import CuidadorResponsavel
from models.relacionamento.paciente_responsavel import Paciente_responsavel
from models.responsavel.responsavel import Responsavel
from repositories import relacionamento_repository, usuario_repository


class RelacionamentoService:
    """Cria e consulta o vinculo entre paciente e responsavel pelo CPF."""

    def vincular_responsavel(self, info):
        """Define o responsavel principal e registra o vinculo muitos-para-muitos."""
        cpf_responsavel = info.get("cpfResponsavel")
        cpf_paciente = info.get("cpfPaciente")
        if not cpf_responsavel or not cpf_paciente:
            return None, 400

        responsavel = usuario_repository.buscar_por_cpf(Responsavel, cpf_responsavel)
        paciente = usuario_repository.buscar_por_cpf(Paciente, cpf_paciente)
        if not responsavel or not paciente:
            return None, 404

        existente = relacionamento_repository.buscar_paciente_responsavel(paciente.id, responsavel.id)
        vinculo, criado = Paciente_responsavel.criar_ou_atualizar(paciente, responsavel, existente)
        if not vinculo:
            return None, 500
        return vinculo, 201 if criado else 200

    def vincular_paciente_cuidador(self, info):
        cpf_paciente = info.get("cpfPaciente")
        cpf_cuidador = info.get("cpfCuidador")
        if not cpf_paciente or not cpf_cuidador:
            return None, 400

        paciente = usuario_repository.buscar_por_cpf(Paciente, cpf_paciente)
        cuidador = usuario_repository.buscar_por_cpf(Cuidador, cpf_cuidador)
        if not paciente or not cuidador:
            return None, 404

        paciente = paciente.vincular_cuidador(cuidador)
        return (paciente, 200) if paciente else (None, 500)

    def vincular_cuidador_responsavel(self, info):
        cpf_cuidador = info.get("cpfCuidador")
        cpf_responsavel = info.get("cpfResponsavel")
        if not cpf_cuidador or not cpf_responsavel:
            return None, 400

        cuidador = usuario_repository.buscar_por_cpf(Cuidador, cpf_cuidador)
        responsavel = usuario_repository.buscar_por_cpf(Responsavel, cpf_responsavel)
        if not cuidador or not responsavel:
            return None, 404

        existente = relacionamento_repository.buscar_cuidador_responsavel(cuidador.id, responsavel.id)
        vinculo, criado = CuidadorResponsavel.criar_ou_buscar(cuidador, responsavel, existente)
        if not vinculo:
            return None, 500
        return vinculo, 201 if criado else 200
