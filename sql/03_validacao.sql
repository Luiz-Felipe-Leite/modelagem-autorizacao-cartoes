-- =====================================================================
-- Validação da carga
-- =====================================================================

-- 1) Contagem de linhas (esperado: 500, 749, 24, 150, 22, 10, 5844, 20000)
SELECT 'dim_cliente' AS tabela, COUNT(*) AS linhas FROM dim_cliente
UNION ALL SELECT 'dim_cartao',           COUNT(*) FROM dim_cartao
UNION ALL SELECT 'dim_bin',              COUNT(*) FROM dim_bin
UNION ALL SELECT 'dim_estabelecimento',  COUNT(*) FROM dim_estabelecimento
UNION ALL SELECT 'dim_mcc',              COUNT(*) FROM dim_mcc
UNION ALL SELECT 'dim_status_transacao', COUNT(*) FROM dim_status_transacao
UNION ALL SELECT 'dim_data',             COUNT(*) FROM dim_data
UNION ALL SELECT 'fato_transacao',       COUNT(*) FROM fato_transacao;

-- 2) Chaves órfãs na fato (esperado: tudo zero)
SELECT
    COUNT(*) FILTER (WHERE c.id_cliente IS NULL)          AS orfaos_cliente,
    COUNT(*) FILTER (WHERE ca.id_cartao IS NULL)          AS orfaos_cartao,
    COUNT(*) FILTER (WHERE b.cod_bin IS NULL)             AS orfaos_bin,
    COUNT(*) FILTER (WHERE e.id_estabelecimento IS NULL)  AS orfaos_estabelecimento,
    COUNT(*) FILTER (WHERE m.cod_mcc IS NULL)             AS orfaos_mcc,
    COUNT(*) FILTER (WHERE s.cod_status_trans IS NULL)    AS orfaos_status,
    COUNT(*) FILTER (WHERE d.id_data IS NULL)             AS orfaos_data
FROM fato_transacao f
LEFT JOIN dim_cliente c           ON c.id_cliente = f.id_cliente
LEFT JOIN dim_cartao ca           ON ca.id_cartao = f.id_cartao
LEFT JOIN dim_bin b               ON b.cod_bin = f.cod_bin
LEFT JOIN dim_estabelecimento e   ON e.id_estabelecimento = f.id_estabelecimento
LEFT JOIN dim_mcc m               ON m.cod_mcc = f.cod_mcc
LEFT JOIN dim_status_transacao s  ON s.cod_status_trans = f.cod_status_trans
LEFT JOIN dim_data d              ON d.id_data = f.id_data;

-- 3) Sanidade dos valores (esperado: nulos = 0, valores <= 0 = 0)
SELECT
    COUNT(*) FILTER (WHERE valor_transacao IS NULL OR dat_transacao IS NULL) AS nulos_obrigatorios,
    COUNT(*) FILTER (WHERE valor_transacao <= 0)                            AS valores_nao_positivos,
    MIN(dat_transacao)                                                      AS primeira_transacao,
    MAX(dat_transacao)                                                      AS ultima_transacao
FROM fato_transacao;

-- 4) Taxa de aprovação geral (esperado: perto de 93%)
SELECT ROUND(100.0 * COUNT(*) FILTER (WHERE s.ind_aprovada) / COUNT(*), 2) AS pct_aprovacao
FROM fato_transacao f
JOIN dim_status_transacao s ON s.cod_status_trans = f.cod_status_trans;
