from extensions import db
from .base_info import Base_info
import enum

class StatusChecklist(enum.Enum):
    PENDENTE = 'pendente'
    CONCLUIDA = 'concluida'

class Checklist_higiene(Base_info):
    __tablename__ = "checklists_higiene"

    tarefa = db.Column(db.String(40), nullable = False)
    descricao = db.Column(db.Text, nullable = False)
    frequencia = db.Column(db.String(30), nullable = False)
    status = db.Column(db.Enum(StatusChecklist), default = StatusChecklist.PENDENTE)
    CAMPOS_EDITAVEIS = {"tarefa", "descricao", "frequencia", "status"}

    def concluir(self):
        self.status = StatusChecklist.CONCLUIDA
        return self.atualizar({}, self.CAMPOS_EDITAVEIS)

    @property
    def to_dict(self):
        return {
            "id": self.id, "paciente_id": self.paciente_id, "tarefa": self.tarefa,
            "descricao": self.descricao, "frequencia": self.frequencia,
            "status": self.status.value,
            "data_criacao": self.data_criacao.isoformat() if self.data_criacao else None,
            "data_alteracao": self.data_alteracao.isoformat() if self.data_alteracao else None,
        }
