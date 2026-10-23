"""Reune os blueprints que a aplicacao registra ao iniciar."""

from .usuario.registrar import *
from .usuario.usuarios import usuariosbp
from .usuario.registrar_relacionamentos import registrar_relacionamento
from .medicamento.medicamento import medicamentobp
from .paciente.sinais_vitais import sinais_vitaisbp
from .paciente.consultas import consultasbp
from .paciente.exames import examesbp
from .paciente.estoque import estoquebp
from .paciente.incidentes import incidentesbp
from .paciente.emergencia import emergenciabp
from .paciente.diario import diariobp
from .paciente.gastos import gastosbp
from .paciente.notificacoes import notificacoesbp
from .paciente.comunicados import comunicadosbp
from .paciente.relatorio import relatoriobp
from .paciente.documentos_exames import documentos_examesbp
from .paciente.higiene import higienebp
from .paciente.lesoes import lesoesbp
from .paciente.dietas import dietasbp
blueprints = [
        # A ordem nao altera as URLs; ela apenas organiza os grupos de rotas.
        registrarbp, 
        usuariosbp,
        registrar_relacionamento,
        medicamentobp,
        sinais_vitaisbp,
        consultasbp,
        examesbp,
        estoquebp,
        incidentesbp,
        emergenciabp,
        diariobp,
        gastosbp,
        notificacoesbp,
        comunicadosbp,
        relatoriobp,
        documentos_examesbp,
        higienebp,
        lesoesbp,
        dietasbp,
    ]

__all__ = ["blueprints"]
