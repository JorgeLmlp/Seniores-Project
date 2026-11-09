"""Testes de regressao para preservar as responsabilidades do MVC da API.

Estes testes analisam o codigo-fonte sem importar a aplicacao. Assim, uma
violacao de camada e apontada antes mesmo de a API precisar de um banco ativo.
"""

import ast
from pathlib import Path
import unittest


API_DIR = Path(__file__).resolve().parents[1]


def arquivos_python(camada):
    """Devolve apenas os fontes da camada, ignorando caches do Python."""
    return sorted(
        arquivo
        for arquivo in (API_DIR / camada).rglob("*.py")
        if "__pycache__" not in arquivo.parts
    )


def nome_da_chamada(no):
    """Reconstrói nomes como ``db.session.commit`` a partir de um no AST."""
    partes = []
    while isinstance(no, ast.Attribute):
        partes.append(no.attr)
        no = no.value
    if isinstance(no, ast.Name):
        partes.append(no.id)
    return ".".join(reversed(partes))


def modulos_importados(arvore):
    """Extrai o modulo raiz de cada import encontrado no arquivo."""
    for no in ast.walk(arvore):
        if isinstance(no, ast.ImportFrom) and no.module:
            yield no, no.module.split(".", 1)[0]
        elif isinstance(no, ast.Import):
            for alias in no.names:
                yield no, alias.name.split(".", 1)[0]


class ArquiteturaMvcTest(unittest.TestCase):
    """Garante o fluxo Route -> Controller -> Service -> Repository/Model."""

    def test_repositories_nao_executam_escritas(self):
        # Repository e a porta de leitura deste projeto. Escritas e transacoes
        # pertencem aos models, conforme a arquitetura documentada no README.
        operacoes_proibidas = {
            "db.session.add",
            "db.session.add_all",
            "db.session.delete",
            "db.session.flush",
            "db.session.commit",
            "db.session.rollback",
        }
        violacoes = []

        for arquivo in arquivos_python("repositories"):
            arvore = ast.parse(arquivo.read_text(encoding="utf-8"), filename=str(arquivo))
            for no in ast.walk(arvore):
                if isinstance(no, ast.Call) and nome_da_chamada(no.func) in operacoes_proibidas:
                    violacoes.append(f"{arquivo.relative_to(API_DIR)}:{no.lineno}")

        self.assertEqual([], violacoes, f"Escrita encontrada em repository: {violacoes}")

    def test_http_fica_em_routes_e_controllers(self):
        # Models, repositories e services nao devem conhecer request/response
        # do Flask; isso os mantem reutilizaveis e testaveis isoladamente.
        violacoes = []
        for camada in ("models", "repositories", "services"):
            for arquivo in arquivos_python(camada):
                arvore = ast.parse(arquivo.read_text(encoding="utf-8"), filename=str(arquivo))
                for no in ast.walk(arvore):
                    modulo = no.module if isinstance(no, ast.ImportFrom) else None
                    nomes = [alias.name for alias in no.names] if isinstance(no, ast.Import) else []
                    if modulo == "flask" or "flask" in nomes:
                        violacoes.append(f"{arquivo.relative_to(API_DIR)}:{no.lineno}")

        self.assertEqual([], violacoes, f"Dependencia HTTP fora da camada web: {violacoes}")

    def test_controllers_e_services_nao_acessam_db_diretamente(self):
        # Consultas passam pelos repositories e escritas pelos models. Impedir
        # o import de `extensions` evita SQLAlchemy escondido nessas camadas.
        violacoes = []
        for camada in ("controllers", "services"):
            for arquivo in arquivos_python(camada):
                arvore = ast.parse(arquivo.read_text(encoding="utf-8"), filename=str(arquivo))
                for no in ast.walk(arvore):
                    modulo = no.module if isinstance(no, ast.ImportFrom) else None
                    nomes = [alias.name for alias in no.names] if isinstance(no, ast.Import) else []
                    if modulo == "extensions" or "extensions" in nomes:
                        violacoes.append(f"{arquivo.relative_to(API_DIR)}:{no.lineno}")

        self.assertEqual([], violacoes, f"Acesso direto ao banco fora do Model/Repository: {violacoes}")

    def test_dependencias_seguem_o_fluxo_das_camadas(self):
        # Cada camada pode conhecer apenas as camadas seguintes do fluxo. Isso
        # impede, por exemplo, uma rota pulando o controller para chamar service.
        proibidos_por_camada = {
            "routes": {"services", "repositories", "models", "extensions"},
            "controllers": {"repositories", "models", "extensions"},
            "repositories": {"routes", "controllers", "services"},
            "models": {"routes", "controllers", "services", "repositories"},
        }
        violacoes = []

        for camada, proibidos in proibidos_por_camada.items():
            for arquivo in arquivos_python(camada):
                arvore = ast.parse(arquivo.read_text(encoding="utf-8"), filename=str(arquivo))
                for no, modulo in modulos_importados(arvore):
                    if modulo in proibidos:
                        violacoes.append(
                            f"{arquivo.relative_to(API_DIR)}:{no.lineno} importa {modulo}"
                        )

        self.assertEqual([], violacoes, f"Dependencia contraria ao fluxo MVC: {violacoes}")


if __name__ == "__main__":
    unittest.main()
