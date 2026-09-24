from repositories.relacionamento import relacionamento_repository


class RelacionamentoService:
    """Cria e consulta o vinculo entre paciente e responsavel pelo CPF."""

    def vincular_responsavel(self, info):
        """Define o responsavel principal e registra o vinculo muitos-para-muitos."""
        cpf_responsavel = info.get("cpfResponsavel")
        cpf_paciente = info.get("cpfPaciente")
        if not cpf_responsavel or not cpf_paciente:
            return None, 400

        responsavel = relacionamento_repository.pesquisar_por_cpf(
            "responsavel", cpf_responsavel
        )
        paciente = relacionamento_repository.pesquisar_por_cpf(
            "paciente", cpf_paciente
        )
        if not responsavel or not paciente:
            return None, 404

        vinculo, criado = relacionamento_repository.vincular_paciente_responsavel(
            paciente, responsavel
        )
        if not vinculo:
            return None, 500
        return vinculo, 201 if criado else 200

    def vincular_paciente_cuidador(self, info):
        cpf_paciente = info.get("cpfPaciente")
        cpf_cuidador = info.get("cpfCuidador")
        if not cpf_paciente or not cpf_cuidador:
            return None, 400

        paciente = relacionamento_repository.pesquisar_por_cpf(
            "paciente", cpf_paciente
        )
        cuidador = relacionamento_repository.pesquisar_por_cpf(
            "cuidador", cpf_cuidador
        )
        if not paciente or not cuidador:
            return None, 404

        paciente = relacionamento_repository.vincular_paciente_cuidador(
            paciente, cuidador
        )
        return (paciente, 200) if paciente else (None, 500)

    def vincular_cuidador_responsavel(self, info):
        cpf_cuidador = info.get("cpfCuidador")
        cpf_responsavel = info.get("cpfResponsavel")
        if not cpf_cuidador or not cpf_responsavel:
            return None, 400

        cuidador = relacionamento_repository.pesquisar_por_cpf(
            "cuidador", cpf_cuidador
        )
        responsavel = relacionamento_repository.pesquisar_por_cpf(
            "responsavel", cpf_responsavel
        )
        if not cuidador or not responsavel:
            return None, 404

        vinculo, criado = relacionamento_repository.vincular_cuidador_responsavel(
            cuidador, responsavel
        )
        if not vinculo:
            return None, 500
        return vinculo, 201 if criado else 200
