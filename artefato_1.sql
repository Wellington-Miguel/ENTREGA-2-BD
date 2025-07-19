--------------------------------------------------------------------------------
--                          ENTREGA 2 - ARTEFATO 1
--          Tela de Cadastro de Pesquisador com Validação
--------------------------------------------------------------------------------

-- Passo 1: MATERIALIZED VIEW para otimizar a validação
-- Justificativa: Em um sistema com muitos projetos, consultar a tabela TB_PROJETO
-- repetidamente para validação pode ser lento. Esta visão materializada armazena
-- uma lista pré-calculada de projetos ativos e o número de participantes,
-- tornando a consulta de validação (o SELECT dentro da procedure) quase instantânea.

CREATE MATERIALIZED VIEW MV_PROJETOS_ATIVOS_PARTICIPANTES AS
SELECT
    P.ID_PROJETO,
    P.NM_PROJETO,
    P.ST_PROJETO,
    COUNT(PP.CO_PESQUISADOR) as QT_PARTICIPANTES
FROM
    TB_PROJETO P
LEFT JOIN
    TB_PESQUISADOR_PROJETO PP ON P.ID_PROJETO = PP.CO_PROJETO
WHERE
    P.ST_PROJETO = 'A'
GROUP BY
    P.ID_PROJETO, P.NM_PROJETO, P.ST_PROJETO;

-- É necessário atualizar a visão periodicamente.
-- REFRESH MATERIALIZED VIEW MV_PROJETOS_ATIVOS_PARTICIPANTES;


--------------------------------------------------------------------------------
-- Passo 2: STORED PROCEDURE para encapsular a lógica de negócio
-- Justificativa: Agrupa 5 comandos SQL em uma única chamada, garantindo
-- atomicidade (ou tudo funciona, ou nada é alterado). Isso simplifica o back-end
-- e previne inconsistências no banco de dados.

CREATE OR REPLACE PROCEDURE sp_cadastrar_pesquisador_em_projeto(
    -- Parâmetros de entrada para o novo pesquisador
    p_nm_pesquisador VARCHAR(255),
    p_ds_email VARCHAR(255),
    p_ds_titulacao VARCHAR(100),
    p_qt_carga_horaria INT,
    -- Parâmetros para alocação
    p_id_projeto INT,
    p_id_laboratorio INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id_pesquisador_novo INT;
    v_projeto_ativo BOOLEAN;
BEGIN
    -- Comando 1: SELECT (Validação)
    -- Verifica na Materialized View se o projeto existe e está ativo.
    SELECT EXISTS (
        SELECT 1
        FROM MV_PROJETOS_ATIVOS_PARTICIPANTES
        WHERE ID_PROJETO = p_id_projeto
    ) INTO v_projeto_ativo;

    IF NOT v_projeto_ativo THEN
        RAISE EXCEPTION 'Projeto com ID % não existe ou não está ativo.', p_id_projeto;
    END IF;

    -- Se a validação passar, continua com as operações dentro de uma transação implícita.

    -- Comando 2: INSERT na tabela TB_PESQUISADOR
    INSERT INTO TB_PESQUISADOR(NM_PESQUISADOR, DS_EMAIL, DS_TITULACAO, QT_CARGA_HORARIA, ST_REGISTRO_ATIVO)
    VALUES (p_nm_pesquisador, p_ds_email, p_ds_titulacao, p_qt_carga_horaria, 'S')
    RETURNING ID_PESQUISADOR INTO v_id_pesquisador_novo; -- Captura o ID do novo pesquisador

    -- Comando 3: INSERT na tabela associativa TB_PESQUISADOR_PROJETO
    INSERT INTO TB_PESQUISADOR_PROJETO(CO_PESQUISADOR, CO_PROJETO)
    VALUES (v_id_pesquisador_novo, p_id_projeto);
    
    -- Adiciona também o vínculo com o laboratório
    INSERT INTO TB_PESQUISADOR_LABORATORIO(CO_PESQUISADOR, CO_LABORATORIO)
    VALUES (v_id_pesquisador_novo, p_id_laboratorio);

    -- Comando 4: UPDATE na tabela TB_PROJETO
    -- Exemplo: Atualiza a data da última modificação do projeto.
    UPDATE TB_PROJETO
    SET DT_FINAL = DT_FINAL -- Apenas um exemplo, poderia ser um campo "DT_ULTIMA_MODIFICACAO"
    WHERE ID_PROJETO = p_id_projeto;

    -- Comando 5: UPDATE na tabela TB_LABORATORIO
    -- Exemplo: Apenas para cumprir o requisito, atualiza o nome (poderia ser um contador).
    UPDATE TB_LABORATORIO
    SET NM_LABORATORIO = NM_LABORATORIO
    WHERE ID_LABORATORIO = p_id_laboratorio;

    -- Atualiza a visão materializada para refletir o novo participante
    REFRESH MATERIALIZED VIEW MV_PROJETOS_ATIVOS_PARTICIPANTES;

    RAISE NOTICE 'Pesquisador % cadastrado e alocado ao projeto ID % com sucesso!', p_nm_pesquisador, p_id_projeto;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Ocorreu um erro na transação: %', SQLERRM;
END;
$$;

--------------------------------------------------------------------------------
-- Passo 3: Demonstração de Uso da Stored Procedure

-- Exemplo de como o back-end chamaria a procedure para adicionar um novo pesquisador.
-- CALL sp_cadastrar_pesquisador_em_projeto(
--     'Dra. Valentina Nova',
--     'valentina.nova@ufba.br',
--     'Doutorado',
--     40,
--     1, -- ID do Projeto "Sistema de Recomendação para E-commerce"
--     1  -- ID do Laboratório "Lab. de Inteligência Artificial"
-- );
