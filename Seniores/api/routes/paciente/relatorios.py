from flask import Blueprint

from controllers.paciente.relatorio_controller import (
    alertas_estoque, enviar_historico, evolucao_sinais_vitais, gerar_relatorio,
)


relatoriosbp = Blueprint("relatorios", __name__)
relatoriosbp.route("/pacientes/<int:paciente_id>/relatorio.pdf", methods=["GET"])(gerar_relatorio)
relatoriosbp.route("/pacientes/<int:paciente_id>/historico/email", methods=["POST"])(enviar_historico)
relatoriosbp.route("/pacientes/<int:paciente_id>/sinais-vitais/evolucao", methods=["GET"])(evolucao_sinais_vitais)
relatoriosbp.route("/pacientes/<int:paciente_id>/alertas-estoque", methods=["GET"])(alertas_estoque)
