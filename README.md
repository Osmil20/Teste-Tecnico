# Teste Tecnico - Intuitive Care

Projeto desenvolvido para o processo seletivo de estagio. O sistema realiza a coleta, processamento e visualizacao de dados de despesas da ANS.

## Estrutura
- `src/`: Codigo fonte com a logica de integracao e processamento.
- `scripts/`: Scripts para rodar as etapas do teste.
- `data/`: Pasta para armazenamento dos arquivos CSV e ZIP (gerada automaticamente).
- `sql/`: Scripts de criacao e consulta ao banco de dados.
- `api/`: Backend (FastAPI) e Frontend (Vue.js).

## Como rodar
1. Instale as dependencias: `pip install -r api/backend/requirements.txt`
2. Gere os dados iniciais: `python scripts/seed_demo_data.py`
3. Rode o processamento: `python scripts/run_teste2.py`
4. Para o banco, execute os arquivos na pasta `sql/` no seu cliente Postgres.
5. Para a web, rode o backend com `uvicorn api.backend.main:app` e abra o `index.html` na pasta `api/frontend` no navegador.
