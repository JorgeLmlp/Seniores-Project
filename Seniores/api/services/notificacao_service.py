from datetime import datetime, timedelta

from models.paciente.consulta import Consulta
from models.paciente.emergencia import AlertaEmergencia
from models.paciente.exame import Exame
from models.paciente.estoque import ItemEstoque
from models.paciente.incidente import Incidente
from models.paciente.notificacao import Notificacao
from models.paciente.paciente import Paciente


class NotificacaoService:
    def listar(self, paciente_id):
        if not Paciente.buscar_por_id(paciente_id):
            return None, 404
        self._sincronizar(paciente_id)
        return Notificacao.listar_por_paciente(paciente_id), 200

    def marcar(self, notificacao_id, lida):
        notificacao = Notificacao.query.get(notificacao_id)
        if not notificacao:
            return None, 404
        notificacao = notificacao.marcar(lida)
        return (notificacao, 200) if notificacao else (None, 500)

    def _sincronizar(self, paciente_id):
        agora = datetime.now()
        limite = agora + timedelta(days=7)
        itens = []

        paciente = Paciente.buscar_por_id(paciente_id)
        for remedio in paciente.remedios:
            if remedio.alerta_sonoro or remedio.horarios:
                itens.append((
                    f"medicamento:{remedio.id}", "medicamento", remedio.id,
                    "Lembrete de medicamento", f"Confira o horario de {remedio.nome}.",
                ))

        for item in ItemEstoque.listar_por_paciente(paciente_id):
            if item.quantidade <= item.quantidade_minima:
                itens.append((
                    f"estoque:{item.id}", "estoque", item.id,
                    "Estoque baixo", f"{item.nome}: {item.quantidade} disponivel.",
                ))

        for consulta in Consulta.listar_por_paciente(paciente_id):
            data = self._data(consulta.data)
            if data and agora.date() <= data.date() <= limite.date():
                itens.append((
                    f"consulta:{consulta.id}", "consulta", consulta.id,
                    "Consulta proxima", f"{consulta.titulo} em {consulta.data}.",
                ))

        for exame in Exame.listar_por_paciente(paciente_id):
            data = self._data(exame.data)
            if data and agora.date() <= data.date() <= limite.date():
                itens.append((
                    f"exame:{exame.id}", "exame", exame.id,
                    "Exame proximo", f"{exame.nome} em {exame.data}.",
                ))

        for incidente in Incidente.listar_por_paciente(paciente_id):
            if not incidente.resolvido:
                itens.append((
                    f"incidente:{incidente.id}", "incidente", incidente.id,
                    "Incidente pendente", incidente.descricao,
                ))

        for alerta in AlertaEmergencia.listar_por_paciente(paciente_id):
            if alerta.status != "resolvido":
                itens.append((
                    f"emergencia:{alerta.id}", "emergencia", alerta.id,
                    "Alerta de emergencia", "Existe um alerta aguardando resolucao.",
                ))

        for chave, tipo, referencia_id, titulo, mensagem in itens:
            if Notificacao.buscar_por_chave(chave):
                continue
            Notificacao(
                paciente_id=paciente_id,
                chave=chave,
                tipo=tipo,
                referencia_id=referencia_id,
                titulo=titulo,
                mensagem=mensagem,
            ).salvar()

    @staticmethod
    def _data(valor):
        if not valor:
            return None
        try:
            return datetime.fromisoformat(str(valor).replace("Z", "+00:00"))
        except ValueError:
            try:
                return datetime.strptime(str(valor), "%Y-%m-%d")
            except ValueError:
                return None
