CREATE TEMP TABLE staging (
    cnpj TEXT,
    razao_social TEXT,
    trimestre TEXT,
    ano TEXT,
    valor_despesas TEXT,
    cnpj_valido TEXT,
    registro_ans TEXT,
    modalidade TEXT,
    uf TEXT
);

\COPY staging FROM 'data/processed/consolidado_despesas.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');

INSERT INTO operadoras (cnpj, razao_social)
SELECT DISTINCT 
    REGEXP_REPLACE(cnpj, '[^0-9]', '', 'g'),
    TRIM(razao_social)
FROM staging
ON CONFLICT (cnpj) DO NOTHING;

INSERT INTO despesas (cnpj, ano, trimestre, valor_despesas)
SELECT 
    REGEXP_REPLACE(cnpj, '[^0-9]', '', 'g'),
    ano::INTEGER,
    trimestre,
    valor_despesas::DECIMAL(15,2)
FROM staging
ON CONFLICT DO NOTHING;

REFRESH MATERIALIZED VIEW despesas_agregadas;
