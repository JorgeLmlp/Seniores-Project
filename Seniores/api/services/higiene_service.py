from models.paciente.higiene import Higiene
from models.paciente.paciente import Paciente


class HigieneService:
    CAMPOS = {"tipo", "data_hora", "itens", "observacoes"}

    def listar(self, paciente_id):
        if not Paciente.buscar_por_id(paciente_id):
            return None, 404
        return Higiene.listar_por_paciente(paciente_id), 200

    def criar(self, paciente_id, info):
        if not Paciente.buscar_por_id(paciente_id):
            return None, 404
        dados, valido = self._dados(info)
        if not valido:
            return None, 400
        higiene = Higiene.criar(paciente_id, dados)
        return (higiene, 201) if higiene else (None, 500)

    def buscar(self, higiene_id):
        higiene = Higiene.buscar_por_id(higiene_id)
        return (higiene, 200) if higiene else (None, 404)

    def atualizar(self, higiene_id, info):
        higiene, status = self.buscar(higiene_id)
        if status != 200:
            return None, status
        dados, valido = self._dados(info)
        if not valido:
            return None, 400
        higiene = higiene.atualizar(dados)
        return (higiene, 200) if higiene else (None, 500)

    def deletar(self, higiene_id):
        higiene, status = self.buscar(higiene_id)
        if status != 200:
            return None, status
        return (None, 204) if higiene.deletar() else (None, 500)

    @classmethod
    def _dados(cls, info):
        dados = {
            campo: info[campo]
            for campo in cls.CAMPOS
            if campo in info and info[campo] is not None
        }
        if not str(dados.get("tipo") or "").strip():
            return {}, False
        if not str(dados.get("data_hora") or "").strip():
            return {}, False
        itens = dados.get("itens")
        if not isinstance(itens, dict) or not itens:
            return {}, False
        if any(not isinstance(chave, str) or not isinstance(valor, bool)
               for chave, valor in itens.items()):
            return {}, False
        dados["tipo"] = str(dados["tipo"]).strip()
        dados["data_hora"] = str(dados["data_hora"]).strip()
        dados["observacoes"] = str(dados.get("observacoes") or "").strip()
        return dados, True
