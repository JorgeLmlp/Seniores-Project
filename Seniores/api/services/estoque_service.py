from models.paciente.estoque import ItemEstoque
from models.paciente.paciente import Paciente


class EstoqueService:
    CAMPOS = {
        "nome", "categoria", "quantidade", "quantidade_minima", "unidade",
        "observacoes",
    }

    def listar(self, paciente_id):
        if not Paciente.buscar_por_id(paciente_id):
            return None, 404
        return ItemEstoque.listar_por_paciente(paciente_id), 200

    def criar(self, paciente_id, info):
        if not Paciente.buscar_por_id(paciente_id):
            return None, 404
        dados, valido = self._dados(info)
        if not valido or not dados.get("nome"):
            return None, 400
        item = ItemEstoque.criar(paciente_id, dados)
        return (item, 201) if item else (None, 500)

    def buscar(self, item_id):
        item = ItemEstoque.buscar_por_id(item_id)
        return (item, 200) if item else (None, 404)

    def atualizar(self, item_id, info):
        item, status = self.buscar(item_id)
        if status != 200:
            return None, status
        dados, valido = self._dados(info)
        if not valido or ("nome" in dados and not dados["nome"]):
            return None, 400
        item = item.atualizar(dados)
        return (item, 200) if item else (None, 500)

    def deletar(self, item_id):
        item, status = self.buscar(item_id)
        if status != 200:
            return None, status
        return (None, 204) if item.deletar() else (None, 500)

    @classmethod
    def _dados(cls, info):
        dados = {
            campo: info[campo]
            for campo in cls.CAMPOS
            if campo in info and info[campo] is not None
        }
        for campo in ("quantidade", "quantidade_minima"):
            if campo in dados:
                valor = dados[campo]
                if isinstance(valor, bool) or not isinstance(valor, int) or valor < 0:
                    return {}, False
        dados.setdefault("quantidade", 0)
        dados.setdefault("quantidade_minima", 0)
        return dados, True
