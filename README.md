# Seniores

[![Android APK](https://github.com/JorgeLmlp/Seniores-Project/actions/workflows/android-release.yml/badge.svg)](https://github.com/JorgeLmlp/Seniores-Project/actions/workflows/android-release.yml)
[![Latest release](https://img.shields.io/github/v/release/JorgeLmlp/Seniores-Project?label=APK)](https://github.com/JorgeLmlp/Seniores-Project/releases/latest)

O Seniores é um aplicativo Flutter com API Flask para organizar o acompanhamento
de saúde e a rotina de cuidados de pessoas idosas. Pacientes, responsáveis e
cuidadores podem manter medicamentos, consultas, exames, sinais vitais,
incidentes, contatos, dietas, estoque e relatórios em um único fluxo.

## Download para Android

[Baixar o APK mais recente](https://github.com/JorgeLmlp/Seniores-Project/releases/latest/download/seniores-android.apk)

O APK publicado em Releases é gerado automaticamente após análise e testes. Para
instalação fora da Play Store, o Android pode solicitar autorização para instalar
aplicativos da fonte usada no download.

## Estrutura

```text
Seniores/
├── api/          API REST em Flask e SQLAlchemy
└── front-end/    Aplicativo Flutter para Android, iOS, Web e desktop
```

A API segue o fluxo `Route → Controller → Service → Repository/Model`. O
aplicativo consome a API por HTTPS e guarda apenas a sessão e dados necessários
ao funcionamento local.

## Executar a API

Requisitos: Python 3.11+ e MySQL. SQLite é aceito apenas nos testes.

```powershell
cd Seniores/api
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
Copy-Item .env.example .env
python app.py
```

Preencha o `.env` local com `DATABASE_URL`, `SECRET_KEY` e `JWT_SECRET_KEY`.
Segredos não devem ser adicionados ao Git. Para um cliente Web em outro domínio,
configure `CORS_ORIGINS` com a lista explícita de origens autorizadas.

## Executar o aplicativo

Requisitos: Flutter 3.44.1 e Java 17.

```powershell
cd Seniores/front-end
flutter pub get
flutter run --dart-define=API_URL=https://sua-api.example.com
```

## Testes

```powershell
cd Seniores/front-end
flutter analyze
flutter test

cd ../api
$env:API_TESTING = '1'
$env:DATABASE_URL = 'sqlite:///:memory:'
$env:JWT_SECRET_KEY = 'uma-chave-de-testes-com-pelo-menos-32-caracteres'
python -m unittest discover -s tests -v
```

## Segurança e privacidade

O projeto lida com dados pessoais e de saúde. Não use dados reais em ambientes
de desenvolvimento. Credenciais pertencem ao provedor de implantação ou ao
arquivo `.env` local, nunca ao código-fonte ou ao aplicativo Flutter. Relate uma
possível vulnerabilidade diretamente ao mantenedor, sem publicar detalhes em uma
issue aberta.

Documentação adicional:

- [API e configuração](Seniores/api/README.md)
- [Endpoints](Seniores/api/README_ENDPOINTS.md)
- [Front-end](Seniores/front-end/README.md)
