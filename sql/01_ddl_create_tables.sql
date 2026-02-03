DROP TABLE IF EXISTS despesas CASCADE;
DROP TABLE IF EXISTS operadoras CASCADE;

CREATE TABLE operadoras (
    cnpj VARCHAR(14) PRIMARY KEY,
    razao_social VARCHAR(255) NOT NULL,
    registro_ans VARCHAR(20),
    modalidade VARCHAR(100),
    uf CHAR(2),
    cnpj_valido BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_cnpj_length CHECK (LENGTH(cnpj) = 14),
    CONSTRAINT chk_cnpj_numeric CHECK (cnpj ~ '^[0-9]+$')
);

CREATE INDEX idx_op_razao ON operadoras(razao_social);
CREATE INDEX idx_op_uf ON operadoras(uf);

CREATE TABLE despesas (
    id SERIAL PRIMARY KEY,
    cnpj VARCHAR(14) NOT NULL,
    ano INTEGER NOT NULL,
    trimestre VARCHAR(2) NOT NULL,
    valor_despesas DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_op FOREIGN KEY (cnpj) REFERENCES operadoras(cnpj) ON DELETE CASCADE,
    CONSTRAINT uk_periodo UNIQUE (cnpj, ano, trimestre)
);

CREATE INDEX idx_desp_cnpj ON despesas(cnpj);
CREATE INDEX idx_desp_per ON despesas(ano, trimestre);

DROP MATERIALIZED VIEW IF EXISTS despesas_agregadas;

CREATE MATERIALIZED VIEW despesas_agregadas AS
SELECT 
    o.cnpj,
    o.razao_social,
    o.uf,
    COUNT(*) as qtd,
    SUM(d.valor_despesas) as total,
    AVG(d.valor_despesas) as media
FROM operadoras o
JOIN despesas d ON o.cnpj = d.cnpj
GROUP BY o.cnpj, o.razao_social, o.uf;

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_op_upd BEFORE UPDATE ON operadoras FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_desp_upd BEFORE UPDATE ON despesas FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
