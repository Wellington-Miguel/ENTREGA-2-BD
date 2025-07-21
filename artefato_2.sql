--    ENTREGA 2 - ARTEFATO 2

CREATE MATERIALIZED VIEW MV_PARTICIPACOES_EVENTOS AS
SELECT
    CO_PESQUISADOR,
    CO_EVENTO
FROM
    TB_PESQUISADOR_EVENTO;


CREATE OR REPLACE PROCEDURE sp_inscrever_pesquisador_evento(
    p_id_pesquisador INT,
    p_id_evento INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_pesquisador_ativo CHAR(1);
    v_ja_inscrito BOOLEAN;
BEGIN
    -- Comando 1: SELECT (Validação de Pesquisador Ativo)
    -- Verifica diretamente na tabela principal se o pesquisador está ativo.
    SELECT ST_REGISTRO_ATIVO INTO v_pesquisador_ativo
    FROM TB_PESQUISADOR
    WHERE ID_PESQUISADOR = p_id_pesquisador;

    IF v_pesquisador_ativo <> 'S' THEN
        RAISE EXCEPTION 'Pesquisador com ID % está inativo e não pode ser inscrito.', p_id_pesquisador;
    END IF;

    -- Comando 2: SELECT (Validação de Inscrição Duplicada)
    -- Utiliza a Materialized View para uma verificação de alta performance.
    SELECT EXISTS (
        SELECT 1
        FROM MV_PARTICIPACOES_EVENTOS
        WHERE CO_PESQUISADOR = p_id_pesquisador AND CO_EVENTO = p_id_evento
    ) INTO v_ja_inscrito;

    IF v_ja_inscrito THEN
        RAISE EXCEPTION 'O pesquisador com ID % já está inscrito no evento ID %.', p_id_pesquisador, p_id_evento;
    END IF;

    -- Se ambas as validações passarem, executa a inserção.

    -- Comando 3: INSERT na tabela associativa
    INSERT INTO TB_PESQUISADOR_EVENTO (CO_PESQUISADOR, CO_EVENTO)
    VALUES (p_id_pesquisador, p_id_evento);

    -- Após a inserção bem-sucedida, atualiza a visão materializada.
    REFRESH MATERIALIZED VIEW CONCURRENTLY MV_PARTICIPACOES_EVENTOS;

    RAISE NOTICE 'Inscrição do pesquisador ID % no evento ID % realizada com sucesso!', p_id_pesquisador, p_id_evento;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Ocorreu um erro na inscrição: %', SQLERRM;
END;
$$;

-- Nota: Para usar REFRESH CONCURRENTLY, a view precisa de um índice único.
CREATE UNIQUE INDEX idx_mv_participacoes_eventos ON MV_PARTICIPACOES_EVENTOS (CO_PESQUISADOR, CO_EVENTO);


