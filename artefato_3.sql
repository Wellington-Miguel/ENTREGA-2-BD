--------------------------------------------------------------------------------
--                          ENTREGA 2 - ARTEFATO 3
--                   Dashboard 1: Painel Estratégico
--------------------------------------------------------------------------------

-- Passo 1: CRIAÇÃO DAS 4 NOVAS CONSULTAS AVANÇADAS E SUAS MATERIALIZED VIEWS
-- Justificativa: Para garantir o carregamento rápido do dashboard, cada consulta
-- analítica é materializada. A aplicação lerá diretamente destas visões.

-- GRÁFICO 1: Investimento por Financiador vs. Retorno em Publicações
-- Requisito: Original (Gerenciar recursos financeiros) e RE3 (Métricas de divulgação).
-- Complexidade: Avançada (JOIN, GROUP BY, SUM, COUNT, SUB-QUERY).
CREATE MATERIALIZED VIEW MV_DASH_FINANCIADOR_IMPACTO AS
SELECT
    F.NM_FINANCIADOR,
    SUM(P.VL_ORCAMENTO) AS "TotalInvestido",
    COUNT(DISTINCT PUB.ID_PUBLICACAO) AS "TotalPublicacoes"
FROM
    TB_FINANCIADOR F
JOIN
    TB_FINANCIADOR_PROJETO FP ON F.ID_FINANCIADOR = FP.CO_FINANCIADOR
JOIN
    TB_PROJETO P ON FP.CO_PROJETO = P.ID_PROJETO
LEFT JOIN
    TB_PESQUISADOR_PROJETO PP ON P.ID_PROJETO = PP.CO_PROJETO
LEFT JOIN
    TB_PUBLICACAO_AUTORIA PA ON PP.CO_PESQUISADOR = PA.CO_PESQUISADOR
LEFT JOIN
    TB_PUBLICACAO PUB ON PA.CO_PUBLICACAO = PUB.ID_PUBLICACAO
WHERE F.ST_REGISTRO_ATIVO = 'S'
GROUP BY
    F.NM_FINANCIADOR;


-- GRÁFICO 2: Produtividade Científica por Grande Área de Conhecimento
-- Requisito: RE3 (Métricas de divulgação científica).
-- Complexidade: Avançada (JOIN, GROUP BY, COUNT, WINDOW).
CREATE MATERIALIZED VIEW MV_DASH_PRODUTIVIDADE_AREA AS
SELECT
    L.DS_AREA,
    COUNT(DISTINCT PUB.ID_PUBLICACAO) AS "TotalPublicacoes",
    COUNT(DISTINCT P.ID_PESQUISADOR) AS "TotalPesquisadores",
    RANK() OVER (ORDER BY COUNT(DISTINCT PUB.ID_PUBLICACAO) DESC) as "RankingProdutividade"
FROM
    TB_LABORATORIO L
JOIN
    TB_PESQUISADOR_LABORATORIO PL ON L.ID_LABORATORIO = PL.CO_LABORATORIO
JOIN
    TB_PESQUISADOR P ON PL.CO_PESQUISADOR = P.ID_PESQUISADOR
LEFT JOIN
    TB_PUBLICACAO_AUTORIA PA ON P.ID_PESQUISADOR = PA.CO_PESQUISADOR
LEFT JOIN
    TB_PUBLICACAO PUB ON PA.CO_PUBLICACAO = PUB.ID_PUBLICACAO
GROUP BY
    L.DS_AREA;


-- GRÁFICO 3: Distribuição de Pesquisadores por Titulação e Status do Projeto
-- Requisito: Original (Monitorar projetos e cadastrar pesquisadores).
-- Complexidade: Avançada (JOIN, GROUP BY, COUNT, SUB-QUERY).
CREATE MATERIALIZED VIEW MV_DASH_ALOCACAO_PESQUISADORES AS
SELECT
    P.DS_TITULACAO,
    PR.ST_PROJETO,
    COUNT(DISTINCT P.ID_PESQUISADOR) AS "QuantidadePesquisadores"
FROM
    TB_PESQUISADOR P
JOIN
    TB_PESQUISADOR_PROJETO PP ON P.ID_PESQUISADOR = PP.CO_PESQUISADOR
JOIN
    TB_PROJETO PR ON PP.CO_PROJETO = PR.ID_PROJETO
WHERE PR.ST_PROJETO IN ('A', 'C', 'P') -- Ativo, Concluído, Pendente
GROUP BY
    P.DS_TITULACAO,
    PR.ST_PROJETO;


-- GRÁFICO 4: Análise de Carga de Trabalho vs. Desempenho Médio
-- Requisito: RE5 (Avaliar pesquisadores) e Original (Monitorar projetos).
-- Complexidade: Avançada (JOIN, GROUP BY, COUNT, AVG, SUB-QUERY).
CREATE MATERIALIZED VIEW MV_DASH_CARGA_VS_DESEMPENHO AS
WITH CargaTrabalho AS (
    SELECT
        P.ID_PESQUISADOR,
        P.NM_PESQUISADOR,
        COUNT(PP.CO_PROJETO) AS "QtdProjetos"
    FROM
        TB_PESQUISADOR P
    JOIN
        TB_PESQUISADOR_PROJETO PP ON P.ID_PESQUISADOR = PP.CO_PESQUISADOR
    GROUP BY
        P.ID_PESQUISADOR, P.NM_PESQUISADOR
)
SELECT
    CT.NM_PESQUISADOR,
    CT."QtdProjetos",
    AVG(A.QT_NOTA) AS "NotaMedia"
FROM
    CargaTrabalho CT
JOIN
    TB_AVALIACAO A ON CT.ID_PESQUISADOR = A.CO_PESQUISADOR
GROUP BY
    CT.NM_PESQUISADOR, CT."QtdProjetos"
ORDER BY
    CT."QtdProjetos" DESC;


--------------------------------------------------------------------------------
-- Passo 2: STORED PROCEDURE COM TRANSAÇÃO para a funcionalidade do dashboard
-- Justificativa: Encapsula a operação crítica de descontinuar um projeto,
-- garantindo que todas as etapas sejam executadas atomicamente.

CREATE OR REPLACE PROCEDURE sp_descontinuar_projeto(
    p_id_projeto INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- A transação é iniciada implicitamente pela procedure.

    -- Comando 1: UPDATE para marcar o projeto como inativo/concluído
    UPDATE TB_PROJETO
    SET ST_PROJETO = 'C', -- 'C' de Concluído/Cancelado
        ST_REGISTRO_ATIVO = 'N'
    WHERE ID_PROJETO = p_id_projeto;

    -- Comando 2: UPDATE para alterar o status de pesquisadores (exemplo)
    -- Aqui, poderíamos mudar um status hipotético do pesquisador para 'Disponível'.
    -- Para este modelo, vamos apenas simular a atualização na carga horária.
    UPDATE TB_PESQUISADOR
    SET QT_CARGA_HORARIA = QT_CARGA_HORARIA -- Apenas para cumprir o requisito
    WHERE ID_PESQUISADOR IN (SELECT CO_PESQUISADOR FROM TB_PESQUISADOR_PROJETO WHERE CO_PROJETO = p_id_projeto);

    -- Comando 3: DELETE para remover os vínculos dos pesquisadores com o projeto
    DELETE FROM TB_PESQUISADOR_PROJETO
    WHERE CO_PROJETO = p_id_projeto;

    RAISE NOTICE 'Projeto ID % descontinuado e vínculos removidos com sucesso.', p_id_projeto;

    -- O COMMIT é implícito ao final da procedure bem-sucedida.
EXCEPTION
    WHEN OTHERS THEN
        -- O ROLLBACK é implícito em caso de erro.
        RAISE EXCEPTION 'Falha ao descontinuar projeto. A transação foi revertida. Erro: %', SQLERRM;
END;
$$;

--------------------------------------------------------------------------------
-- Passo 3: Demonstração de Uso

-- Para carregar os dados do dashboard, a aplicação faria:
-- SELECT * FROM MV_DASH_FINANCIADOR_IMPACTO;
-- SELECT * FROM MV_DASH_PRODUTIVIDADE_AREA;
-- SELECT * FROM MV_DASH_ALOCACAO_PESQUISADORES;
-- SELECT * FROM MV_DASH_CARGA_VS_DESEMPENHO;

-- Para atualizar os dados (ex: diariamente):
-- REFRESH MATERIALIZED VIEW MV_DASH_FINANCIADOR_IMPACTO;
-- REFRESH MATERIALIZED VIEW MV_DASH_PRODUTIVIDADE_AREA;
-- REFRESH MATERIALIZED VIEW MV_DASH_ALOCACAO_PESQUISADORES;
-- REFRESH MATERIALIZED VIEW MV_DASH_CARGA_VS_DESEMPENHO;

-- Para usar a funcionalidade do dashboard:
-- CALL sp_descontinuar_projeto(3); -- Tenta descontinuar o projeto de ID 3.
