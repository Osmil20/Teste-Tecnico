# Guia de Correcao

## Criterios Avaliados

1. **Organizacao de Pastas**: 
   Verificar se o candidato separou o codigo fonte (`src`) dos scripts de execucao. O uso da pasta `api/` para o serviço web demonstra boa prática arquitetural.

2. **Qualidade do Codigo Python**:
   - Uso de classes e metodos.
   - Validacao de CNPJ (algoritmo completo).
   - Manipulacao de arquivos com `pandas`.
   - Tratamento de excecoes em chamadas de rede e leitura de arquivos.

3. **Banco de Dados**:
   - Modelagem das tabelas (PKs, FKs).
   - Uso de indices para performance.
   - Queries analiticas corretas.

4. **Web / API**:
   - API funcional com FastAPI/Flask dentro da pasta `api/`.
   - Frontend consumindo a API corretamente.
   - Graficos coerentes com os dados.

## Pontos de Atencao
- Verifique se os caminhos de arquivos sao relativos (correto) ou absolutos (errado).
- Veja se as dependencias estao listadas no `requirements.txt`.
- O README deve ser direto e funcional.
