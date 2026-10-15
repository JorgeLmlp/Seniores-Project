# Endpoints da API Seniores

Base local: `http://127.0.0.1:5001`.

## Convenções

- Endpoints JSON usam `Content-Type: application/json`.
- Uploads usam `multipart/form-data`.
- Datas e horários usam ISO 8601, por exemplo `2026-10-14T08:30:00`.
- `PUT` e `PATCH` aceitam atualização parcial nos endpoints de item.
- Respostas de criação usam `201`; consulta/atualização, `200`; exclusão,
  `204`; dados inválidos, `400`; item inexistente, `404`; duplicidade, `409`.
- As rotas ainda não possuem autenticação por token. O endpoint de login apenas
  valida as credenciais atuais.

## 1. Usuários e perfil do idoso

### Rotas

| Método | Endpoint | Finalidade |
| --- | --- | --- |
| `POST` | `/users/` | Cadastrar paciente, cuidador ou responsável |
| `GET` | `/users/` | Listar todos os usuários |
| `GET` | `/users/?tipo={tipo}` | Listar por `paciente`, `cuidador` ou `responsavel` |
| `GET` | `/users/?tipo=paciente&cuidador_id={id}` | Listar pacientes de um cuidador |
| `GET` | `/users/{tipo}/{usuario_id}/` | Consultar usuário |
| `PUT`/`PATCH` | `/users/{tipo}/{usuario_id}/` | Atualizar usuário ou perfil |
| `DELETE` | `/users/{tipo}/{usuario_id}/` | Excluir usuário |
| `POST` | `/users/login/` | Validar e-mail e senha |
| `POST` | `/paciente` | Atalho para cadastro de paciente |
| `POST` | `/cuidador` | Atalho para cadastro de cuidador |
| `POST` | `/responsavel` | Atalho para cadastro de responsável |

Cadastro completo de paciente:

```json
{
  "nome": "Maria da Silva",
  "email": "maria@example.com",
  "senha": "Senha@123",
  "telefone": "11999999999",
  "cpf": "12345678901",
  "tipo": "paciente",
  "idade": 79,
  "tipo_sanguineo": "O+",
  "preferencias": {
    "musicas": ["samba", "sertanejo"],
    "hobbies": ["xadrez", "jardinagem"]
  }
}
```

Os tipos sanguíneos aceitos são `A+`, `A-`, `B+`, `B-`, `AB+`, `AB-`, `O+`
e `O-`. `idade` deve estar entre 0 e 130. A senha nunca é retornada.

Login:

```json
{
  "email": "maria@example.com",
  "senha": "Senha@123",
  "tipo": "paciente"
}
```

O campo `tipo` do login é opcional.

## 2. Relacionamentos entre usuários

| Método | Endpoint | Finalidade |
| --- | --- | --- |
| `POST` | `/registrar_relacionamento` | Vincular paciente e responsável principal |
| `POST` | `/relacionamentos/paciente-cuidador` | Vincular paciente e cuidador |
| `POST` | `/relacionamentos/cuidador-responsavel` | Vincular cuidador e responsável |

Exemplos:

```json
{
  "cpfPaciente": "12345678901",
  "cpfResponsavel": "98765432100"
}
```

```json
{
  "cpfPaciente": "12345678901",
  "cpfCuidador": "11122233344"
}
```

```json
{
  "cpfCuidador": "11122233344",
  "cpfResponsavel": "98765432100"
}
```

## 3. Medicamentos e alertas sonoros

| Método | Endpoint | Finalidade |
| --- | --- | --- |
| `POST` | `/pacientes/{paciente_id}/medicamentos` | Cadastrar medicamento |
| `GET` | `/pacientes/{paciente_id}/medicamentos` | Listar medicamentos |
| `GET` | `/medicamentos/{medicamento_id}` | Consultar medicamento |
| `PUT`/`PATCH` | `/medicamentos/{medicamento_id}` | Atualizar medicamento |
| `DELETE` | `/medicamentos/{medicamento_id}` | Excluir medicamento |

`nome` e `dosagem` são obrigatórios:

```json
{
  "nome": "Losartana",
  "dosagem": "50 mg",
  "frequencia": "diaria",
  "horarios": ["08:00", "20:00"],
  "alertas": ["Tomar com agua"],
  "alerta_sonoro": true,
  "som_alerta": "campainha",
  "descricao": "Uso continuo",
  "fabricante": "Exemplo Farma",
  "lote": "L123",
  "quantidade": 30
}
```

## 4. Administração de medicamentos

| Método | Endpoint | Finalidade |
| --- | --- | --- |
| `POST` | `/pacientes/{paciente_id}/administracoes-medicamentos` | Confirmar administração |
| `GET` | `/pacientes/{paciente_id}/administracoes-medicamentos` | Listar confirmações |
| `GET` | `/administracoes-medicamentos/{registro_id}` | Consultar confirmação |
| `PUT`/`PATCH` | `/administracoes-medicamentos/{registro_id}` | Atualizar confirmação |
| `DELETE` | `/administracoes-medicamentos/{registro_id}` | Excluir confirmação |

```json
{
  "medicamento_id": 10,
  "horario_previsto": "2026-10-14T08:00:00",
  "administrado_em": "2026-10-14T08:02:00",
  "confirmado_por": "Cuidadora Ana",
  "observacao": "Administrado com agua"
}
```

O medicamento precisa pertencer ao mesmo paciente.

## 5. Consultas futuras

| Método | Endpoint | Finalidade |
| --- | --- | --- |
| `POST` | `/pacientes/{paciente_id}/consultas` | Anotar consulta futura |
| `GET` | `/pacientes/{paciente_id}/consultas` | Listar consultas |
| `GET` | `/consultas/{registro_id}` | Consultar anotação |
| `PUT`/`PATCH` | `/consultas/{registro_id}` | Atualizar anotação |
| `DELETE` | `/consultas/{registro_id}` | Excluir anotação |

```json
{
  "nomeDoutor": "Dra. Ana",
  "especialidade": "Cardiologia",
  "local": "Clinica Central",
  "dataHora": "2026-12-01T10:00:00",
  "alertas": ["um dia antes"],
  "exames": ["hemograma"],
  "concluida": false,
  "historico": false
}
```

Essa rota apenas anota a consulta; não realiza agendamento externo.

## 6. Exames agendados

| Método | Endpoint | Finalidade |
| --- | --- | --- |
| `POST` | `/pacientes/{paciente_id}/exames` | Cadastrar exame agendado |
| `GET` | `/pacientes/{paciente_id}/exames` | Listar exames agendados |
| `GET` | `/exames/{registro_id}` | Consultar exame |
| `PUT`/`PATCH` | `/exames/{registro_id}` | Atualizar exame |
| `DELETE` | `/exames/{registro_id}` | Excluir exame |

```json
{
  "nomeExame": "Hemograma",
  "local": "Laboratorio Central",
  "dataHora": "2026-11-20T08:30:00",
  "concluido": false,
  "historico": false
}
```

## 7. Arquivos de exames no prontuário

| Método | Endpoint | Finalidade |
| --- | --- | --- |
| `POST` | `/pacientes/{paciente_id}/exames-documentos` | Anexar PDF ou imagem |
| `GET` | `/pacientes/{paciente_id}/exames-documentos` | Listar anexos |
| `GET` | `/exames-documentos/{registro_id}/arquivo` | Baixar arquivo |
| `DELETE` | `/exames-documentos/{registro_id}` | Excluir arquivo |

O cadastro usa `multipart/form-data`:

| Campo | Obrigatório | Descrição |
| --- | --- | --- |
| `nome` | Sim | Nome do exame |
| `arquivo` | Sim | PDF, JPEG, PNG ou WebP de até 10 MB |
| `descricao` | Não | Observação textual |
| `data_exame` | Não | Data ISO 8601 |

Exemplo com cURL:

```bash
curl -X POST http://127.0.0.1:5001/pacientes/1/exames-documentos \
  -F 'nome=Hemograma' \
  -F 'data_exame=2026-10-10T09:00:00' \
  -F 'arquivo=@hemograma.pdf;type=application/pdf'
```

## 8. Sinais vitais e evolução

| Método | Endpoint | Finalidade |
| --- | --- | --- |
| `POST` | `/pacientes/{paciente_id}/sinais-vitais` | Registrar medição |
| `GET` | `/pacientes/{paciente_id}/sinais-vitais` | Listar medições |
| `GET` | `/sinais-vitais/{sinal_vital_id}` | Consultar medição |
| `PUT`/`PATCH` | `/sinais-vitais/{sinal_vital_id}` | Atualizar medição |
| `DELETE` | `/sinais-vitais/{sinal_vital_id}` | Excluir medição |
| `GET` | `/pacientes/{paciente_id}/sinais-vitais/evolucao` | Obter séries para gráficos |

Informe pelo menos uma medida:

```json
{
  "data": "2026-10-14T09:00:00",
  "pressao_art": "120/80",
  "glicemia": "95",
  "temperatura": "36.5",
  "freq_cardiaca": "72",
  "saturacao": "98"
}
```

Resposta resumida da evolução:

```json
{
  "labels": ["2026-10-14T09:00:00"],
  "series": {
    "pressao_art": ["120/80"],
    "glicemia": ["95"],
    "temperatura": ["36.5"],
    "freq_cardiaca": ["72"],
    "saturacao": ["98"]
  }
}
```

## 9. Incidentes

| Método | Endpoint | Finalidade |
| --- | --- | --- |
| `POST` | `/pacientes/{paciente_id}/incidentes` | Registrar incidente |
| `GET` | `/pacientes/{paciente_id}/incidentes` | Listar incidentes |
| `GET` | `/incidentes/{registro_id}` | Consultar incidente |
| `PUT`/`PATCH` | `/incidentes/{registro_id}` | Atualizar incidente |
| `DELETE` | `/incidentes/{registro_id}` | Excluir incidente |

```json
{
  "tipo": "queda",
  "data_hora": "2026-10-13T18:00:00",
  "descricao": "Queda sem ferimento",
  "gravidade": "leve",
  "providencias": "Paciente avaliado"
}
```

## 10. Estoque e alertas

| Método | Endpoint | Finalidade |
| --- | --- | --- |
| `POST` | `/pacientes/{paciente_id}/estoque` | Cadastrar item |
| `GET` | `/pacientes/{paciente_id}/estoque` | Listar estoque |
| `GET` | `/estoque/{registro_id}` | Consultar item |
| `PUT`/`PATCH` | `/estoque/{registro_id}` | Atualizar item ou quantidade |
| `DELETE` | `/estoque/{registro_id}` | Excluir item |
| `GET` | `/pacientes/{paciente_id}/alertas-estoque` | Listar notificações de estoque baixo |

```json
{
  "nome": "Fraldas",
  "quantidade": 8,
  "quantidade_minima": 10,
  "descricao": "Tamanho G"
}
```

`estoque_baixo` será verdadeiro e o endpoint de alertas retornará uma
notificação quando a quantidade atual for menor ou igual à mínima.

## 11. Relatório PDF e exportação por e-mail

| Método | Endpoint | Finalidade |
| --- | --- | --- |
| `GET` | `/pacientes/{paciente_id}/relatorio.pdf?mes={1-12}&ano={ano}` | Baixar relatório mensal |
| `POST` | `/pacientes/{paciente_id}/historico/email` | Enviar relatório mensal por e-mail |

Se `mes` e `ano` não forem enviados no download, a API usa o período atual.

Corpo para envio:

```json
{
  "email": "medico@example.com",
  "mes": 10,
  "ano": 2026
}
```

O envio retorna `202` quando aceito. Retorna `503` se o SMTP não estiver
configurado e `502` se o servidor de e-mail rejeitar ou não responder.

## 12. Contatos de emergência

| Método | Endpoint | Finalidade |
| --- | --- | --- |
| `POST` | `/pacientes/{paciente_id}/contatos-emergencia` | Cadastrar contato |
| `GET` | `/pacientes/{paciente_id}/contatos-emergencia` | Listar contatos |
| `GET` | `/contatos-emergencia/{registro_id}` | Consultar contato |
| `PUT`/`PATCH` | `/contatos-emergencia/{registro_id}` | Atualizar contato |
| `DELETE` | `/contatos-emergencia/{registro_id}` | Excluir contato |

```json
{
  "nome": "Carlos Silva",
  "tipo": "familiar",
  "vinculo": "filho",
  "telefone": "31988887777",
  "email": "carlos@example.com",
  "especialidade": null
}
```

`tipo` aceita `medico` ou `familiar`.

## 13. Alertas de pânico

| Método | Endpoint | Finalidade |
| --- | --- | --- |
| `POST` | `/pacientes/{paciente_id}/alertas-panico` | Registrar acionamento |
| `GET` | `/pacientes/{paciente_id}/alertas-panico` | Listar acionamentos |
| `GET` | `/alertas-panico/{registro_id}` | Consultar acionamento |
| `PUT`/`PATCH` | `/alertas-panico/{registro_id}` | Atualizar/resolver alerta |
| `DELETE` | `/alertas-panico/{registro_id}` | Excluir alerta |

```json
{
  "localizacao": "quarto",
  "mensagem": "Preciso de ajuda"
}
```

Para encerrar o atendimento:

```json
{ "resolvido": true }
```

## 14. Diário de saúde e sintomas

| Método | Endpoint | Finalidade |
| --- | --- | --- |
| `POST` | `/pacientes/{paciente_id}/diarios-saude` | Criar registro diário |
| `GET` | `/pacientes/{paciente_id}/diarios-saude` | Listar registros |
| `GET` | `/diarios-saude/{registro_id}` | Consultar registro |
| `PUT`/`PATCH` | `/diarios-saude/{registro_id}` | Atualizar registro |
| `DELETE` | `/diarios-saude/{registro_id}` | Excluir registro |

```json
{
  "humor": "bom",
  "dor": "razoavel",
  "fome": "bom",
  "mobilidade": "bom",
  "sono": "ruim",
  "humor_nivel": 8,
  "dor_nivel": 3,
  "apetite_nivel": 8,
  "mobilidade_nivel": 7,
  "sono_nivel": 4,
  "descricao": "Dormiu pouco",
  "incidentes": [],
  "duvidas": "Rever horario do remedio"
}
```

Os estados aceitos são `bom`, `ruim`, `pessimo` e `razoavel`; níveis variam
de 0 a 10.

## 15. Turnos de cuidadores

| Método | Endpoint | Finalidade |
| --- | --- | --- |
| `POST` | `/pacientes/{paciente_id}/turnos-cuidadores` | Criar turno |
| `GET` | `/pacientes/{paciente_id}/turnos-cuidadores` | Listar turnos |
| `GET` | `/turnos-cuidadores/{registro_id}` | Consultar turno |
| `PUT`/`PATCH` | `/turnos-cuidadores/{registro_id}` | Atualizar turno |
| `DELETE` | `/turnos-cuidadores/{registro_id}` | Excluir turno |

```json
{
  "cuidador_id": 3,
  "nome_cuidador": "Ana",
  "dias_semana": ["segunda", "terca", "quarta"],
  "hora_inicio": "08:00",
  "hora_fim": "18:00",
  "observacao": "Turno diurno"
}
```

### Agenda antiga compatível com o Flutter

| Método | Endpoint |
| --- | --- |
| `POST`/`GET` | `/pacientes/{paciente_id}/cuidadores` |
| `GET`/`PUT`/`PATCH`/`DELETE` | `/cuidadores/{registro_id}` |

Formato antigo:

```json
{
  "nome": "Ana",
  "funcao": "Cuidadora diurna",
  "frequencia": [false, true, true, true, true, true, false],
  "horaInicio": "08:00",
  "horaFim": "18:00",
  "ativoAgora": true
}
```

## 16. Permissões de membros

| Método | Endpoint | Finalidade |
| --- | --- | --- |
| `POST` | `/pacientes/{paciente_id}/permissoes` | Definir permissão |
| `GET` | `/pacientes/{paciente_id}/permissoes` | Listar permissões |
| `GET` | `/permissoes/{registro_id}` | Consultar permissão |
| `PUT`/`PATCH` | `/permissoes/{registro_id}` | Alterar nível |
| `DELETE` | `/permissoes/{registro_id}` | Revogar permissão |

```json
{
  "membro_tipo": "responsavel",
  "membro_id": 5,
  "nivel": "leitura"
}
```

`membro_tipo` aceita `cuidador` ou `responsavel`; `nivel` aceita `leitura` ou
`escrita`.

## 17. Dieta e restrições alimentares

| Método | Endpoint | Finalidade |
| --- | --- | --- |
| `POST` | `/pacientes/{paciente_id}/dietas-restricoes` | Cadastrar dieta/restrições |
| `GET` | `/pacientes/{paciente_id}/dietas-restricoes` | Listar registros |
| `GET` | `/dietas-restricoes/{registro_id}` | Consultar registro |
| `PUT`/`PATCH` | `/dietas-restricoes/{registro_id}` | Atualizar registro |
| `DELETE` | `/dietas-restricoes/{registro_id}` | Excluir registro |

```json
{
  "descricao_dieta": "Dieta hipossodica",
  "restricoes": ["sal", "acucar"],
  "alergias": ["lactose"],
  "observacoes": "Oferecer agua durante o dia"
}
```

## 18. Checklist de higiene

| Método | Endpoint |
| --- | --- |
| `POST`/`GET` | `/pacientes/{paciente_id}/checklists-higiene` |
| `GET`/`PUT`/`PATCH`/`DELETE` | `/checklists-higiene/{registro_id}` |

```json
{
  "tarefa": "Banho",
  "descricao": "Auxiliar no banho da manha",
  "frequencia": "diaria",
  "status": "pendente"
}
```

`status` aceita `pendente` ou `concluida`.

## 19. Lesões e fotos

| Método | Endpoint | Finalidade |
| --- | --- | --- |
| `POST` | `/pacientes/{paciente_id}/lesoes` | Registrar lesão |
| `GET` | `/pacientes/{paciente_id}/lesoes` | Listar lesões |
| `GET` | `/lesoes/{registro_id}` | Consultar lesão |
| `PUT`/`PATCH` | `/lesoes/{registro_id}` | Atualizar lesão/foto |
| `DELETE` | `/lesoes/{registro_id}` | Excluir lesão |
| `GET` | `/lesoes/{registro_id}/foto` | Baixar foto |

```json
{
  "localizacao": "Braco esquerdo",
  "descricao": "Escoriacao superficial",
  "gravidade": "leve",
  "status": "aberta",
  "foto_base64": "data:image/jpeg;base64,/9j/4AAQ..."
}
```

São aceitos JPEG, PNG, WebP e GIF de até 5 MB. Para remover somente a foto,
envie `{ "foto_base64": null }` em um `PATCH`.

## 20. Registros financeiros

| Método | Endpoint |
| --- | --- |
| `POST`/`GET` | `/pacientes/{paciente_id}/registros-financeiros` |
| `GET`/`PUT`/`PATCH`/`DELETE` | `/registros-financeiros/{registro_id}` |

```json
{
  "descricao": "Compra de medicamentos",
  "valor": 89.90,
  "tipo": "despesa",
  "data": "2026-10-14T10:30:00"
}
```

`tipo` aceita `receita` ou `despesa`; `valor` não pode ser negativo.

## 21. Destinatários de comunicados

| Método | Endpoint |
| --- | --- |
| `POST`/`GET` | `/pacientes/{paciente_id}/destinatarios` |
| `GET`/`PUT`/`PATCH`/`DELETE` | `/destinatarios/{registro_id}` |

```json
{
  "nome": "Carlos Silva",
  "vinculo": "Filho",
  "telefone": "31988887777"
}
```

## 22. Comunicados

| Método | Endpoint |
| --- | --- |
| `POST`/`GET` | `/pacientes/{paciente_id}/comunicados` |
| `GET`/`PUT`/`PATCH`/`DELETE` | `/comunicados/{registro_id}` |

```json
{
  "mensagem": "Consulta alterada para as 10 horas",
  "destinatarios": [
    {
      "nome": "Carlos Silva",
      "vinculo": "Filho",
      "telefone": "31988887777"
    }
  ]
}
```

## Resumo de cobertura

Esta documentação inclui todas as rotas registradas atualmente pelos
blueprints de usuários, relacionamentos, medicamentos, sinais vitais,
registros clínicos, registros do aplicativo, anexos e relatórios. Rotas de
item que mostram `PUT`/`PATCH` aceitam ambos os métodos.
