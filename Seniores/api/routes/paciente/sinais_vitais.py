from flask import Blueprint

from controllers.paciente.sinal_vital_controller import criar_sinal_vital


sinais_vitaisbp = Blueprint("sinais_vitais", __name__)
sinais_vitaisbp.route("/sinais-vitais", methods=["POST"])(criar_sinal_vital)
