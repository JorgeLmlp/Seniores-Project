"""Operações comuns aos registros usados pelas telas do aplicativo.

Os services de consulta, exame, cuidador, destinatário e comunicado herdam
esta classe. Assim, o CRUD não precisa ser repetido em todos os arquivos, mas
cada service concreto continua responsável por validar seus próprios campos.
"""

from datetime import datetime

from repositories.paciente import registro_app_repository


class RegistroPacienteService:
    """Implementa o CRUD compartilhado pelos services concretos.

    Esta classe não é usada diretamente pelo controller. O controller escolhe
    uma de suas subclasses, como ``ConsultaService`` ou ``ExameService``.
    """

    # A subclasse informa o valor salvo na coluna `recurso` da tabela.
    RECURSO = None
    # `frozenset` é um conjunto imutável usado apenas para conferir chaves.
    CAMPOS_OBRIGATORIOS = frozenset()

    def _normalizar(self, dados, parcial=False):
        """Confere o formato básico e devolve uma cópia dos dados recebidos.

        Em uma criação todos os campos obrigatórios precisam estar presentes.
        Em uma atualização parcial (PATCH), somente os campos enviados são
        verificados pelo service concreto.
        """
        # O corpo da requisição deve ser um objeto JSON não vazio.
        if not isinstance(dados, dict) or not dados:
            return None
        # `issubset` confirma se todas as chaves obrigatórias estão em `dados`.
        if not parcial and not self.CAMPOS_OBRIGATORIOS.issubset(dados):
            return None
        # A cópia impede que a normalização altere o dicionário original.
        return dict(dados)

    def criar(self, paciente_id, dados):
        """Valida e cria um registro vinculado a um paciente existente."""
        # Chama também a validação específica implementada pela subclasse.
        dados = self._normalizar(dados)
        if dados is None:
            return None, 400
        # Não permite criar um registro para um paciente inexistente.
        if not registro_app_repository.buscar_paciente(paciente_id):
            return None, 404

        # Os campos específicos permanecem no JSON `dados`. O campo `recurso`
        # permite distinguir consultas, exames e os demais tipos na tabela.
        registro = registro_app_repository.criar(
            paciente_id, self.RECURSO, dados
        )
        # O model retorna None quando ocorre algum erro ao gravar no banco.
        return (registro, 201) if registro else (None, 500)

    def listar(self, paciente_id):
        """Lista somente os registros deste recurso e deste paciente."""
        if not registro_app_repository.buscar_paciente(paciente_id):
            return None, 404

        # Os dois filtros são necessários porque vários recursos compartilham
        # a tabela `registros_app`.
        return registro_app_repository.listar(paciente_id, self.RECURSO), 200

    def buscar(self, registro_id):
        """Busca por ID e impede acessar o registro pela rota de outro tipo."""
        registro = registro_app_repository.buscar(registro_id)
        # Exemplo: um registro de exame não pode ser retornado por /consultas.
        if not registro or registro.recurso != self.RECURSO:
            return None, 404
        return registro, 200

    def atualizar(self, registro_id, dados):
        """Mescla os campos enviados com o JSON que já está armazenado."""
        registro, status = self.buscar(registro_id)
        if status != 200:
            return None, status

        # `parcial=True` permite alterar um único campo sem reenviar o objeto.
        dados = self._normalizar(dados, parcial=True)
        if dados is None:
            return None, 400

        # As chaves novas substituem apenas as chaves correspondentes antigas.
        registro.dados = {**registro.dados, **dados}
        registro.data_alteracao = datetime.now()
        registro = registro_app_repository.salvar(registro)
        return (registro, 200) if registro else (None, 500)

    def deletar(self, registro_id):
        """Remove um registro somente quando ele pertence a este recurso."""
        registro, status = self.buscar(registro_id)
        if status != 200:
            return None, status
        return (
            (None, 204)
            if registro_app_repository.deletar(registro)
            else (None, 500)
        )


def texto_preenchido(valor):
    """Aceita apenas texto que contenha ao menos um caractere não vazio."""
    return isinstance(valor, str) and bool(valor.strip())


def data_iso_valida(valor):
    """Confere datas ISO 8601, formato produzido por DateTime do Flutter."""
    if not texto_preenchido(valor):
        return False
    try:
        # O sufixo `Z` representa UTC e é convertido para o formato aceito pelo
        # `datetime`. Datas sem fuso também continuam sendo aceitas.
        datetime.fromisoformat(valor.replace("Z", "+00:00"))
        return True
    except ValueError:
        # Uma data malformada vira erro de validação, e não erro interno 500.
        return False
