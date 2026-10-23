from flask import Blueprint

from controllers.paciente.sinal_vital_controller import (
    atualizar_sinal_vital,
    criar_sinal_vital,
    deletar_sinal_vital,
    listar_sinais_vitais,
)


sinais_vitaisbp = Blueprint("sinais_vitais", __name__)
sinais_vitaisbp.route("/sinais-vitais", methods=["POST"])(criar_sinal_vital)
sinais_vitaisbp.route("/sinais-vitais", methods=["GET"])(listar_sinais_vitais)
sinais_vitaisbp.route("/sinais-vitais/<int:sinal_id>", methods=["PUT", "PATCH"])(atualizar_sinal_vital)
sinais_vitaisbp.route("/sinais-vitais/<int:sinal_id>", methods=["DELETE"])(deletar_sinal_vital)
