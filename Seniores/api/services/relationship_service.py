from models.relacionamento.paciente_responsavel import Paciente_responsavel
from repositories.relationship_repository import pesquisarPorCpf
from extensions import db
TIPOS_RELACIONAMENTO= {
    "paciente_responsavel" : Paciente_responsavel,
}

class RelationshipService:
    """dados devem ser algo como: 
    {
        "cpfResponsavel" : "208.168.010-61"
        "cpfPaciente" : "418.779.130-22"
    }
    """
    def vincularResponsavel(self, info):
        cpfResponsavel = info.get("cpfResponsavel")
        cpfPaciente = info.get("cpgPaciente")
        if cpfResponsavel and cpfPaciente:    
            resp_id = pesquisarPorCpf("responsavel", cpfResponsavel)
            paci_id = pesquisarPorCpf("paciente", cpfPaciente)
            
            if resp_id and paci_id:
                paciente_responsavel = {
                    "responsavel_id" : resp_id,
                    "paciente_id" : paci_id,
                }
                db.session.add(paciente_responsavel)
                db.session.commit()
                
                                
