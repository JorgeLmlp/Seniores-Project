# Recuperação do histórico

A integração parte da main remota `b2da172` e preserva sua estrutura `Seniores/`.
Foram recuperados 68 commits disponíveis no reflog local, incluindo os históricos
anteriores às regravações do repositório. Autores, datas e mensagens foram mantidos.
Arquivos `.env` foram removidos de 29 snapshots históricos antes da publicação;
os commits afetados e seus descendentes recebem novos hashes.

O merge de histórico preserva o código atual da main com as adaptações de deploy
e documentos legais. Versões locais divergentes permanecem acessíveis nos commits
recuperados, sem substituir automaticamente a implementação atual do GitHub.

| Ponta original | Ponta recuperada |
| --- | --- |
| `197c81d` | `197c81dbedb85a26a46fe4fc5070b62fd6c1c839` |
| `f5bff74` | `01b7e43805ebb41a8b4cd1e1de1e561dd65486d3` |
| `d0f41ee` | `a564d7e166e6579e141cf11ff671a0198d2eaa70` |
| `0ed2f8e` | `0ed2f8e2fabaf98ccad747fb129aea88221d6682` |
| `1cf56fa` | `1cf56fa0ce1bea3d1d39549be93f8412d8d750b0` |

Validação: os dois testes públicos da API e os dois testes Flutter de documentos
passaram. A suíte da API tem as mesmas três falhas e três erros da main original
(arquitetura MVC, fluxo de medicamentos/alertas e teste legado de PDF).
