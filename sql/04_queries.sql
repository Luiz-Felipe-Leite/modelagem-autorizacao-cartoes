-- =====================================================================
-- Perguntas de negócio respondidas pelo modelo
-- =====================================================================

-- 1) Qual a taxa de aprovação geral e como ela evolui mês a mês?

-- Taxa de aprovação geral:

WITH tx_aprovacao_geral AS (
SELECT 
    COUNT(*) AS total_transacoes,
    SUM(CASE WHEN d.des_status_trans = 'Aprovada' THEN 1 ELSE 0 END) AS aprovadas
FROM fato_transacao ft
INNER JOIN dim_status_transacao ds ON ft.cod_status_trans = ds.cod_status_trans
)
SELECT 
    ROUND(aprovadas * 100.0 / total_transacoes, 2) AS taxa_aprovacao_geral
FROM tx_aprovacao_geral;

-- Taxa de aprovação mês a mês:

WITH tx_aprovacao_mes AS (
SELECT 
    TO_CHAR(dat_transacao, 'YYYY-MM') AS mes,
    COUNT(*) AS total_transacoes,
    SUM(CASE WHEN d.des_status_trans = 'Aprovada' THEN 1 ELSE 0 END) AS aprovadas,
    SUM(CASE WHEN d.des_status_trans <> 'Aprovada' THEN 1 ELSE 0 END) AS negadas
FROM fato_transacao ft
INNER JOIN dim_status_transacao ds ON ft.cod_status_trans = ds.cod_status_trans
GROUP BY 1
)
SELECT 
    mes,
    total_transacoes,
    aprovadas,
    negadas,
    ROUND(aprovadas * 100.0 / total_transacoes, 2) AS taxa_aprovacao_mes
FROM tx_aprovacao_mes
ORDER BY 1;

-- 2) Qual a taxa de aprovação por MCC e por categoria de estabelecimento?


-- 3) Quais os principais motivos de negativa e como a distribuição muda por mês?


-- 4) A aprovação muda por bandeira, tipo de cartão e produto?


-- 5) Quais emissores têm a pior taxa de aprovação?


-- 6) Qual o volume financeiro e o ticket médio por mês e por categoria?


-- 7) As negativas por limite indisponível têm ticket maior que as aprovadas?


-- 8) Qual a variação mês a mês do volume aprovado?


-- 9) Em quais horas do dia e dias da semana há mais transações e menor aprovação?


-- 10) Dias úteis e fins de semana se comportam de forma diferente?


-- 11) Quais os 10 estabelecimentos com maior volume e maior taxa de negativa?


-- 12) Quais clientes tiveram mais negativas e quem tentou de novo no mesmo dia?


-- 13) Como volume e aprovação se distribuem por estado do cliente?


-- 14) Que parcela das negativas vem de cartão vencido?

