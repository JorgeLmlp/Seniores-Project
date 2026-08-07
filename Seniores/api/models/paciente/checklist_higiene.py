from extensions import db
from .base_info import Base_info
import enum

class StatusChecklist(enum.Enum):
    PENDENTE = 'pendente'
    CONCLUIDA = 'concluida'

class Checklist_higiene(Base_info):
    tarefa = db.Column(db.String(40), nullable = False)
    descricao = db.Column(db.Text, nullable = False)
    frequencia = db.Column(db.String(30), nullable = False)
    status = db.Column(db.Enum(StatusChecklist), default = StatusChecklist.PENDENTE)
    
    def concluir(self):
        self.status = StatusChecklist.CONCLUIDA
        self.alterar()        
        
        