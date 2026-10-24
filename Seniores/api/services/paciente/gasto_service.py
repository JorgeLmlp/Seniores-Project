import math
from services.paciente.registro_paciente_service import RegistroPacienteService, texto_preenchido


class GastoService(RegistroPacienteService):
    RECURSO = 'gastos'
    CAMPOS_OBRIGATORIOS = frozenset({'categoria', 'valor', 'tipo'})

    def _normalizar(self, dados, parcial=False):
        dados = super()._normalizar(dados, parcial)
        if dados is None:
            return None
        if 'categoria' in dados and not texto_preenchido(dados['categoria']):
            return None
        if 'valor' in dados:
            valor = dados['valor']
            if isinstance(valor, bool) or not isinstance(valor, (float, int)) or not math.isfinite(valor) or valor <= 0:
                return None
        if 'tipo' in dados and dados['tipo'] not in ('Mensal', 'Anual'):
            return None
        return dados
