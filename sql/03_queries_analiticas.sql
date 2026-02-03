-- ============================================================================
-- Queries Analíticas
-- Autor: Candidato Júnior
-- Data: 2026-02-03
-- ============================================================================

-- ============================================================================
-- QUERY 1: Top 5 operadoras com maior crescimento percentual de despesas
-- ============================================================================

-- Trade-off: Tratamento de operadoras sem dados em todos os trimestres
-- Decisão: Incluir apenas operadoras com dados no primeiro E último trimestre
-- Justificativa:
--   - Crescimento percentual só faz sentido com dados nos dois períodos
--   - Operadoras sem dados podem ter encerrado atividades ou problemas de coleta
--   - Evita divisão por zero ou resultados enganosos
--   - Permite análise mais confiável de crescimento real

WITH periodos AS (
    -- Identificar primeiro e último trimestre disponíveis
    SELECT 
        MIN(CONCAT(ano, trimestre)) as primeiro_periodo,
        MAX(CONCAT(ano, trimestre)) as ultimo_periodo
    FROM despesas
),
despesas_primeiro_trimestre AS (
    -- Despesas no primeiro trimestre
    SELECT 
        d.cnpj,
        o.razao_social,
        d.valor_despesas as valor_inicial
    FROM despesas d
    INNER JOIN operadoras o ON d.cnpj = o.cnpj
    CROSS JOIN periodos p
    WHERE CONCAT(d.ano, d.trimestre) = p.primeiro_periodo
        AND d.valor_despesas > 0  -- Evitar divisão por zero
),
despesas_ultimo_trimestre AS (
    -- Despesas no último trimestre
    SELECT 
        d.cnpj,
        d.valor_despesas as valor_final
    FROM despesas d
    CROSS JOIN periodos p
    WHERE CONCAT(d.ano, d.trimestre) = p.ultimo_periodo
)
SELECT 
    dpt.cnpj,
    dpt.razao_social,
    dpt.valor_inicial,
    dut.valor_final,
    ROUND(
        ((dut.valor_final - dpt.valor_inicial) / dpt.valor_inicial * 100)::NUMERIC, 
        2
    ) as crescimento_percentual,
    CASE 
        WHEN dut.valor_final > dpt.valor_inicial THEN '↑ CRESCIMENTO'
        WHEN dut.valor_final < dpt.valor_inicial THEN '↓ REDUÇÃO'
        ELSE '= ESTÁVEL'
    END as tendencia
FROM despesas_primeiro_trimestre dpt
INNER JOIN despesas_ultimo_trimestre dut ON dpt.cnpj = dut.cnpj
ORDER BY crescimento_percentual DESC
LIMIT 5;

-- Comentário sobre a query:
-- Esta query utiliza CTEs (Common Table Expressions) para melhor legibilidade
-- e manutenibilidade. O uso de INNER JOIN garante que apenas operadoras com
-- dados em ambos os períodos sejam consideradas.


-- QUERY 2: Distribuição de despesas por UF (Top 5 estados)


-- Trade-off: Agregação simples vs agregação com detalhes
-- Decisão: Incluir tanto total quanto média por operadora
-- Justificativa:
--   - Total mostra volume absoluto (importante para gestão de recursos)
--   - Média por operadora mostra eficiência relativa (normaliza por tamanho do mercado)
--   - Permite análise mais rica e comparações mais justas entre estados

SELECT 
    o.uf,
    COUNT(DISTINCT o.cnpj) as numero_operadoras,
    SUM(d.valor_despesas) as total_despesas,
    ROUND(AVG(d.valor_despesas)::NUMERIC, 2) as media_despesas_por_registro,
    ROUND(
        (SUM(d.valor_despesas) / COUNT(DISTINCT o.cnpj))::NUMERIC, 
        2
    ) as media_despesas_por_operadora,
    -- Percentual do total nacional
    ROUND(
        (SUM(d.valor_despesas) * 100.0 / SUM(SUM(d.valor_despesas)) OVER ())::NUMERIC,
        2
    ) as percentual_nacional
FROM operadoras o
INNER JOIN despesas d ON o.cnpj = d.cnpj
WHERE o.uf IS NOT NULL
GROUP BY o.uf
ORDER BY total_despesas DESC
LIMIT 5;

-- Análise adicional: Distribuição por modalidade dentro dos top 5 estados
WITH top_ufs AS (
    SELECT o.uf
    FROM operadoras o
    INNER JOIN despesas d ON o.cnpj = d.cnpj
    WHERE o.uf IS NOT NULL
    GROUP BY o.uf
    ORDER BY SUM(d.valor_despesas) DESC
    LIMIT 5
)
SELECT 
    o.uf,
    o.modalidade,
    COUNT(DISTINCT o.cnpj) as numero_operadoras,
    SUM(d.valor_despesas) as total_despesas,
    ROUND(
        (SUM(d.valor_despesas) * 100.0 / SUM(SUM(d.valor_despesas)) OVER (PARTITION BY o.uf))::NUMERIC,
        2
    ) as percentual_uf
FROM operadoras o
INNER JOIN despesas d ON o.cnpj = d.cnpj
WHERE o.uf IN (SELECT uf FROM top_ufs)
    AND o.modalidade IS NOT NULL
GROUP BY o.uf, o.modalidade
ORDER BY o.uf, total_despesas DESC;


-- ============================================================================
-- QUERY 3: Operadoras com despesas acima da média em pelo menos 2 trimestres
-- ============================================================================

-- Trade-off: Abordagem de implementação
-- Decisão: Usar CTE com window function e agregação
-- Justificativa:
--   - Performance: Window functions são otimizadas pelo PostgreSQL
--   - Manutenibilidade: Código mais legível e fácil de modificar
--   - Legibilidade: CTEs tornam a lógica clara e sequencial
--   - Alternativas consideradas:
--     * Subqueries correlacionadas: mais lentas e difíceis de ler
--     * Tabelas temporárias: overhead desnecessário para esta análise
--     * Self-joins: mais complexos e menos performáticos

WITH media_geral_por_trimestre AS (
    -- Calcular média geral de despesas por trimestre
    SELECT 
        ano,
        trimestre,
        AVG(valor_despesas) as media_geral
    FROM despesas
    GROUP BY ano, trimestre
),
despesas_comparadas AS (
    -- Comparar cada despesa com a média do seu trimestre
    SELECT 
        d.cnpj,
        d.ano,
        d.trimestre,
        d.valor_despesas,
        m.media_geral,
        CASE 
            WHEN d.valor_despesas > m.media_geral THEN 1
            ELSE 0
        END as acima_media
    FROM despesas d
    INNER JOIN media_geral_por_trimestre m 
        ON d.ano = m.ano AND d.trimestre = m.trimestre
),
contagem_acima_media AS (
    -- Contar quantos trimestres cada operadora ficou acima da média
    SELECT 
        cnpj,
        SUM(acima_media) as trimestres_acima_media,
        COUNT(*) as total_trimestres,
        ROUND(AVG(valor_despesas)::NUMERIC, 2) as media_despesas_operadora,
        MAX(media_geral) as media_geral_referencia
    FROM despesas_comparadas
    GROUP BY cnpj
)
SELECT 
    o.cnpj,
    o.razao_social,
    o.uf,
    o.modalidade,
    c.trimestres_acima_media,
    c.total_trimestres,
    c.media_despesas_operadora,
    c.media_geral_referencia,
    ROUND(
        ((c.media_despesas_operadora - c.media_geral_referencia) / c.media_geral_referencia * 100)::NUMERIC,
        2
    ) as percentual_acima_media
FROM contagem_acima_media c
INNER JOIN operadoras o ON c.cnpj = o.cnpj
WHERE c.trimestres_acima_media >= 2
ORDER BY c.trimestres_acima_media DESC, c.media_despesas_operadora DESC;

-- Resultado agregado: Quantas operadoras atendem ao critério?
WITH media_geral_por_trimestre AS (
    SELECT 
        ano,
        trimestre,
        AVG(valor_despesas) as media_geral
    FROM despesas
    GROUP BY ano, trimestre
),
despesas_comparadas AS (
    SELECT 
        d.cnpj,
        CASE 
            WHEN d.valor_despesas > m.media_geral THEN 1
            ELSE 0
        END as acima_media
    FROM despesas d
    INNER JOIN media_geral_por_trimestre m 
        ON d.ano = m.ano AND d.trimestre = m.trimestre
)
SELECT 
    COUNT(DISTINCT cnpj) as total_operadoras_criterio
FROM (
    SELECT cnpj
    FROM despesas_comparadas
    GROUP BY cnpj
    HAVING SUM(acima_media) >= 2
) sub;



-- QUERIES ADICIONAIS PARA ANÁLISE EXPLORATÓRIA


-- Query 4: Evolução temporal das despesas (visão geral)
SELECT 
    ano,
    trimestre,
    COUNT(DISTINCT cnpj) as operadoras_ativas,
    SUM(valor_despesas) as total_despesas,
    ROUND(AVG(valor_despesas)::NUMERIC, 2) as media_despesas,
    ROUND(STDDEV(valor_despesas)::NUMERIC, 2) as desvio_padrao,
    MIN(valor_despesas) as min_despesas,
    MAX(valor_despesas) as max_despesas
FROM despesas
GROUP BY ano, trimestre
ORDER BY ano, trimestre;


-- Query 5: Operadoras com maior variabilidade de despesas
-- (podem indicar problemas de dados ou sazonalidade)
SELECT 
    o.cnpj,
    o.razao_social,
    o.uf,
    da.numero_trimestres,
    da.total_despesas,
    da.media_despesas,
    da.desvio_padrao,
    ROUND(
        (da.desvio_padrao / NULLIF(da.media_despesas, 0) * 100)::NUMERIC,
        2
    ) as coeficiente_variacao
FROM despesas_agregadas da
INNER JOIN operadoras o ON da.cnpj = o.cnpj
WHERE da.numero_trimestres >= 2
    AND da.media_despesas > 0
ORDER BY coeficiente_variacao DESC
LIMIT 10;


-- Query 6: Ranking de operadoras por modalidade
SELECT 
    o.modalidade,
    o.cnpj,
    o.razao_social,
    o.uf,
    da.total_despesas,
    RANK() OVER (
        PARTITION BY o.modalidade 
        ORDER BY da.total_despesas DESC
    ) as ranking_modalidade
FROM despesas_agregadas da
INNER JOIN operadoras o ON da.cnpj = o.cnpj
WHERE o.modalidade IS NOT NULL
ORDER BY o.modalidade, ranking_modalidade
LIMIT 20;


-- ============================================================================
-- ÍNDICES ADICIONAIS PARA OTIMIZAÇÃO (se necessário)
-- ============================================================================

-- Após análise de performance, criar índices adicionais se necessário:
-- CREATE INDEX idx_despesas_ano_trimestre ON despesas(ano, trimestre);
-- CREATE INDEX idx_despesas_valor_desc ON despesas(valor_despesas DESC);


-- ============================================================================
-- FIM DAS QUERIES ANALÍTICAS
-- ============================================================================

-- Para executar queries individuais:
-- psql -U postgres -d ans_database -f 03_queries_analiticas.sql

-- Para exportar resultados para CSV:
-- psql -U postgres -d ans_database -c "SELECT * FROM ..." -o resultado.csv --csv
