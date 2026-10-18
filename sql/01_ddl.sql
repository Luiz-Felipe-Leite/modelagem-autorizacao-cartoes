-- =====================================================================
-- Modelo dimensional: transações de cartão (esquema estrela)
-- Banco: PostgreSQL 12+ (usa coluna gerada)
-- Granularidade da fato: 1 linha = 1 tentativa de autorização de transação
-- =====================================================================

-- ---------------------------------------------------------------------
-- DIMENSÕES
-- ---------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS dim_cliente (
    id_cliente      BIGINT       PRIMARY KEY,
    dat_cadastro    DATE,
    des_uf          CHAR(2),
    des_cidade      VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS dim_cartao (
    id_cartao       BIGINT       PRIMARY KEY,
    des_tipo_cartao VARCHAR(20),          -- ex.: Crédito, Débito
    dat_emissao     DATE,
    dat_validade    DATE,
    ind_ativo       BOOLEAN      DEFAULT TRUE
);

-- BIN = 6 primeiros dígitos do PAN. Nunca armazene o PAN completo.
CREATE TABLE IF NOT EXISTS dim_bin (
    cod_bin         CHAR(6)      PRIMARY KEY,
    des_bandeira    VARCHAR(30),          -- ex.: Visa, Mastercard, Elo
    des_emissor     VARCHAR(100),
    des_produto     VARCHAR(50),          -- ex.: Gold, Platinum, Black
    des_tipo_cartao VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS dim_estabelecimento (
    id_estabelecimento  BIGSERIAL    PRIMARY KEY,   -- chave substituta (surrogate)
    des_estabelecimento VARCHAR(200) NOT NULL,
    des_cidade          VARCHAR(100),
    des_uf              CHAR(2),
    des_pais            VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS dim_mcc (
    cod_mcc         CHAR(4)      PRIMARY KEY,
    des_mcc         VARCHAR(150) NOT NULL,        -- ex.: Supermercados
    des_categoria   VARCHAR(100)                  -- agrupamento mais amplo
);

CREATE TABLE IF NOT EXISTS dim_status_transacao (
    cod_status_trans    VARCHAR(10)  PRIMARY KEY,
    des_status_trans    VARCHAR(100) NOT NULL,    -- ex.: Aprovada, Negada - Limite Indisponível
    ind_aprovada        BOOLEAN      NOT NULL
);

-- Dimensão de data (id_data no formato AAAAMMDD)
CREATE TABLE IF NOT EXISTS dim_data (
    id_data             INTEGER      PRIMARY KEY,
    dat_completa        DATE         NOT NULL UNIQUE,
    nr_ano              SMALLINT     NOT NULL,
    nr_trimestre        SMALLINT     NOT NULL,
    nr_mes              SMALLINT     NOT NULL,
    des_mes             VARCHAR(15)  NOT NULL,
    nr_dia              SMALLINT     NOT NULL,
    nr_dia_semana       SMALLINT     NOT NULL,    -- 0 = domingo
    des_dia_semana      VARCHAR(15)  NOT NULL,
    ind_fim_semana      BOOLEAN      NOT NULL
);

-- Popula a dim_data (ajuste o intervalo conforme o seu dataset)
INSERT INTO dim_data
SELECT
    (EXTRACT(YEAR FROM d) * 10000 + EXTRACT(MONTH FROM d) * 100 + EXTRACT(DAY FROM d))::INT,
    d::DATE,
    EXTRACT(YEAR FROM d)::SMALLINT,
    EXTRACT(QUARTER FROM d)::SMALLINT,
    EXTRACT(MONTH FROM d)::SMALLINT,
    (ARRAY['Janeiro','Fevereiro','Março','Abril','Maio','Junho','Julho',
           'Agosto','Setembro','Outubro','Novembro','Dezembro'])[EXTRACT(MONTH FROM d)::INT],
    EXTRACT(DAY FROM d)::SMALLINT,
    EXTRACT(DOW FROM d)::SMALLINT,
    (ARRAY['Domingo','Segunda','Terça','Quarta','Quinta','Sexta','Sábado'])[EXTRACT(DOW FROM d)::INT + 1],
    EXTRACT(DOW FROM d) IN (0, 6)
FROM generate_series('2015-01-01'::DATE, '2030-12-31'::DATE, INTERVAL '1 day') AS d
ON CONFLICT (id_data) DO NOTHING;

-- ---------------------------------------------------------------------
-- FATO
-- ---------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS fato_transacao (
    id_transacao        VARCHAR(50)    PRIMARY KEY,   -- dimensão degenerada
    id_cliente          BIGINT         NOT NULL REFERENCES dim_cliente (id_cliente),
    id_cartao           BIGINT         NOT NULL REFERENCES dim_cartao (id_cartao),
    cod_bin             CHAR(6)        REFERENCES dim_bin (cod_bin),
    id_estabelecimento  BIGINT         REFERENCES dim_estabelecimento (id_estabelecimento),
    cod_mcc             CHAR(4)        REFERENCES dim_mcc (cod_mcc),
    cod_status_trans    VARCHAR(10)    NOT NULL REFERENCES dim_status_transacao (cod_status_trans),

    dat_transacao       TIMESTAMP      NOT NULL,      -- com hora, minuto e segundo
    id_data             INTEGER        NOT NULL REFERENCES dim_data (id_data),  -- data no formato AAAAMMDD, ex.: 20260115
    valor_transacao     NUMERIC(15,2)  NOT NULL
);
