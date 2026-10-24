"""Reune os blueprints que a aplicacao registra ao iniciar."""

from .usuario.registrar import registrarbp
from .usuario.usuarios import usuariosbp
from .usuario.recuperacao_senha import recuperacao_senhapb
from .relacionamento.relacionamento import registrar_relacionamento
from .medicamento.medicamento import medicamentobp
from .paciente.sinais_vitais import sinais_vitaisbp
from .paciente.registros import registros_pacientebp
from .paciente.registros_app import registros_appbp
from .paciente.cuidados import cuidadosbp
from .paciente.exames_documentos import exames_documentosbp
from .paciente.relatorios import relatoriosbp
from .relacionamento.solicitacoes import solicitacoesbp
from .medicamento.doses import dosesbp
blueprints = [
        solicitacoesbp,
        dosesbp,
        # A ordem nao altera as URLs; ela apenas organiza os grupos de rotas.
        registrarbp, 
        usuariosbp,
        recuperacao_senhapb,
        registrar_relacionamento,
        medicamentobp,
        sinais_vitaisbp,
        registros_pacientebp,
        registros_appbp,
        cuidadosbp,
        exames_documentosbp,
        relatoriosbp,
    ]

__all__ = ["blueprints"]
