Teste Técnico

Projeto desenvolvido com foco em integração de dados, processamento, análise e visualização de despesas da ANS.

📌 O que foi implementado

Integração com a API pública da ANS

Download e extração automática de arquivos (ZIP, CSV, TXT, XLSX)

Normalização e consolidação dos dados dos últimos 3 trimestres

Tratamento de inconsistências (CNPJ, valores inválidos, formatos divergentes)

Validação e enriquecimento com dados cadastrais das operadoras

Agregações estatísticas (total, média e desvio padrão)

Persistência e análise em banco PostgreSQL

Queries analíticas conforme solicitado no teste

API REST para exposição dos dados

Interface web simples para visualização

📁 Estrutura do Projeto
.
├── src/        # Processamento, validação e análise dos dados
├── scripts/    # Execução das etapas do teste
├── data/       # Arquivos CSV e ZIP gerados automaticamente
├── sql/        # DDL, carga e queries analíticas
└── api/
    ├── backend/   # API REST (FastAPI)
    └── frontend/  # Interface web (Vue.js)

🚀 Como Executar
pip install -r api/backend/requirements.txt
python scripts/seed_demo_data.py
python scripts/run_teste2.py
uvicorn api.backend.main:app --reload


Frontend:

api/frontend/index.html

🛠 Tecnologias

Python

FastAPI

PostgreSQL

Vue.js

SQL

📄 Observações

A pasta data/ é criada automaticamente

As decisões técnicas e trade-offs foram aplicados conforme solicitado no enunciado do teste

O projeto prioriza simplicidade, clareza e execução funcional
