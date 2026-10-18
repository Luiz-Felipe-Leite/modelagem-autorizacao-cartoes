-- =====================================================================
-- Carga dos CSVs nas tabelas (PostgreSQL)
-- Os CSVs ficam em /dados dentro do container (volume do docker-compose).
-- Pode rodar mais de uma vez: o TRUNCATE limpa as tabelas antes da carga.
-- A dim_data não entra aqui porque o 01_ddl.sql já a popula.
-- =====================================================================
\set ON_ERROR_STOP on

BEGIN;

TRUNCATE TABLE
    fato_transacao,
    dim_cliente,
    dim_cartao,
    dim_bin,
    dim_estabelecimento,
    dim_mcc,
    dim_status_transacao;

-- Dimensões primeiro
COPY dim_cliente (id_cliente, dat_cadastro, des_uf, des_cidade)
FROM '/dados/dim_cliente.csv' WITH (FORMAT csv, HEADER true);

COPY dim_cartao (id_cartao, des_tipo_cartao, dat_emissao, dat_validade, ind_ativo)
FROM '/dados/dim_cartao.csv' WITH (FORMAT csv, HEADER true);

COPY dim_bin (cod_bin, des_bandeira, des_emissor, des_produto, des_tipo_cartao)
FROM '/dados/dim_bin.csv' WITH (FORMAT csv, HEADER true);

COPY dim_estabelecimento (id_estabelecimento, des_estabelecimento, des_cidade, des_uf, des_pais)
FROM '/dados/dim_estabelecimento.csv' WITH (FORMAT csv, HEADER true);

COPY dim_mcc (cod_mcc, des_mcc, des_categoria)
FROM '/dados/dim_mcc.csv' WITH (FORMAT csv, HEADER true);

COPY dim_status_transacao (cod_status_trans, des_status_trans, ind_aprovada)
FROM '/dados/dim_status_transacao.csv' WITH (FORMAT csv, HEADER true);

-- Fato por último
COPY fato_transacao (id_transacao, id_cliente, id_cartao, cod_bin, id_estabelecimento,
                     cod_mcc, cod_status_trans, dat_transacao, id_data, valor_transacao)
FROM '/dados/fato_transacao.csv' WITH (FORMAT csv, HEADER true);

-- Ajusta a sequência da chave serial, já que os ids vieram preenchidos no CSV
SELECT setval(
    pg_get_serial_sequence('dim_estabelecimento', 'id_estabelecimento'),
    (SELECT MAX(id_estabelecimento) FROM dim_estabelecimento)
);

COMMIT;
