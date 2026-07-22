from flask import Blueprint

registrar_medicamento = Blueprint("registrar_medicamento", __name__)

registrar_medicamento.route("/registrar_medicamento", methods=["POST", "PUT"])

