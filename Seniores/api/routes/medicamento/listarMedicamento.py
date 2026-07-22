from flask import Blueprint

listar_medicamento = Blueprint("listar_medicamento", __name__)
listar_medicamento.route("/listar_medicamento", methods=["GET"])