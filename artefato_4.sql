--------------------------------------------------------------------------------
--                          ENTREGA 2 - ARTEFATO 4
--              Dashboard 2: Painel de Análise Operacional
--------------------------------------------------------------------------------

-- Passo 1: CRIAÇÃO DAS 6 NOVAS CONSULTAS (4 Intermediárias, 2 Avançadas)
-- E SUAS RESPECTIVAS MATERIALIZED VIEWS.

-- GRÁFICO 1 (Intermediário): Status Atual dos Equipamentos por Laboratório
-- Requisito: RE1, RE2 (Gestão de Equipamentos).
-- Complexidade: Intermediária (JOIN, GROUP BY, COUNT).
CREATE MATERIALIZED VIEW MV_DASH_STATUS_EQUIPAMENTOS AS
SELECT
    L.NM_LABORATORIO,
    E.ST_DISPONIBILIDADE,
    COUNT(E.ID_EQUIPAMENTO) AS "Quantidade"
FROM
    TB_LABORATORIO L
JOIN
    TB_EQUIPAMENTO E ON L.ID_LABORATORIO = E.CO_LABORATORIO
WHERE L.ST_REGISTRO_ATIVO = 'S'
GROUP BY
    L.NM_LABORATORIO,
    E.ST_DISPONIBILIDADE;


-- GRÁFICO 2 (Intermediário): Projetos Ativos Próximos do Prazo Final (próximos 6 meses)
-- Requisito: Original (Monitorar a execução de projetos).
-- Complexidade: Intermediária (Tabelas: 1, mas com filtro complexo de data). Para cumprir, faremos JOIN.
CREATE MATERIALIZED VIEW MV_DASH_PROJETOS_A_VENCER AS
SELECT
    P.NM_PROJETO,
    P.DT_FINAL,
    F.NM_FINANCIADOR
FROM
    TB_PROJETO P
JOIN
    TB_FINANCIADOR_PROJETO FP ON P.ID_PROJETO = FP.CO_PROJETO
JOIN
    TB_FINANCIADOR F ON FP.CO_FINANCIADOR = F.ID_FINANCIADOR
WHERE
    P.ST_PROJETO = 'A'
    AND P.DT_FINAL BETWEEN CURRENT_DATE AND (CURRENT_DATE + INTERVAL '6 months');


-- GRÁFICO 3 (Intermediário): Atividade Recente de Submissão de Relatórios (últimos 90 dias)
-- Requisito: Original (Emitir relatórios de produtividade).
-- Complexidade: Intermediária (JOIN, GROUP BY, COUNT).
CREATE MATERIALIZED VIEW MV_DASH_RELATORIOS_RECENTES AS
SELECT
    P.NM_PESQUISADOR,
    PR.NM_PROJETO,
    COUNT(R.ID_RELATORIO) AS "QtdRelatoriosSubmetidos"
FROM
    TB_RELATORIO R
JOIN
    TB_PESQUISADOR P ON R.CO_PESQUISADOR = P.ID_PESQUISADOR
JOIN
    TB_PROJETO PR ON R.CO_PROJETO = PR.ID_PROJETO
WHERE
    R.DT_SUBMISSAO >= (CURRENT_DATE - INTERVAL '90 days')
GROUP BY
    P.NM_PESQUISADOR,
    PR.NM_PROJETO;


-- GRÁFICO 4 (Intermediário): Bolsas de Pesquisa a Expirar (próximos 3 meses)
-- Requisito: Original (Gerenciar bolsas).
-- Complexidade: Intermediária (JOIN, filtro de data).
-- Nota: O modelo precisaria de uma data de fim de bolsa no pesquisador. Vamos simular com a data final do projeto.
CREATE MATERIALIZED VIEW MV_DASH_BOLSAS_A_VENCER AS
SELECT
    P.NM_PESQUISADOR,
    P.TP_BOLSA,
    PR.NM_PROJETO,
    PR.DT_FINAL AS "DataFimVinculo"
FROM
    TB_PESQUISADOR P
JOIN
    TB_PESQUISADOR_PROJETO PP ON P.ID_PESQUISADOR = PP.CO_PESQUISADOR
JOIN
    TB_PROJETO PR ON PP.CO_PROJETO = PR.ID_PROJETO
WHERE
    P.TP_BOLSA IS NOT NULL
    AND PR.DT_FINAL BETWEEN CURRENT_DATE AND (CURRENT_DATE + INTERVAL '3 months');


-- GRÁFICO 5 (Avançado): Análise de Colaboração em Publicações
-- Requisito: RE3 (Métricas de divulgação).
-- Complexidade: Avançada (JOIN, GROUP BY, COUNT, SUB-QUERY).
CREATE MATERIALIZED VIEW MV_DASH_ANALISE_COLABORACAO AS
WITH ContagemAutores AS (
    SELECT
        PUB.ID_PUBLICACAO,
        PUB.DS_TITULO,
        COUNT(PA.CO_PESQUISADOR) AS "NumeroDeAutores"
    FROM
        TB_PUBLICACAO PUB
    JOIN
        TB_PUBLICACAO_AUTORIA PA ON PUB.ID_PUBLICACAO = PA.CO_PUBLICACAO
    GROUP BY
        PUB.ID_PUBLICACAO, PUB.DS_TITULO
)
SELECT
    CA.DS_TITULO,
    CA."NumeroDeAutores",
    STRING_AGG(DISTINCT P.DS_TITULACAO, ', ') AS "TitulacoesEnvolvidas"
FROM
    ContagemAutores CA
JOIN
    TB_PUBLICACAO_AUTORIA PA ON CA.ID_PUBLICACAO = PA.CO_PUBLICACAO
JOIN
    TB_PESQUISADOR P ON PA.CO_PESQUISADOR = P.ID_PESQUISADOR
WHERE
    CA."NumeroDeAutores" > 1
GROUP BY
    CA.ID_PUBLICACAO, CA.DS_TITULO, CA."NumeroDeAutores"
ORDER BY
    CA."NumeroDeAutores" DESC;


-- GRÁFICO 6 (Avançado): Desempenho Individual vs. Média da Titulação
-- Requisito: RE5, RE6 (Avaliação de pesquisadores).
-- Complexidade: Avançada (JOIN, GROUP BY, AVG, WINDOW).
CREATE MATERIALIZED VIEW MV_DASH_DESEMPENHO_COMPARATIVO AS
SELECT
    P.NM_PESQUISADOR,
    P.DS_TITULACAO,
    AVG(A.QT_NOTA) AS "NotaMediaIndividual",
    AVG(AVG(A.QT_NOTA)) OVER (PARTITION BY P.DS_TITULACAO) AS "NotaMediaDaTitulacao"
FROM
    TB_PESQUISADOR P
JOIN
    TB_AVALIACAO A ON P.ID_PESQUISADOR = A.CO_PESQUISADOR
GROUP BY
    P.ID_PESQUISADOR, P.NM_PESQUISADOR, P.DS_TITULACAO
ORDER BY
    P.DS_TITULACAO, "NotaMediaIndividual" DESC;


--------------------------------------------------------------------------------
-- Passo 2: STORED PROCEDURE para gerenciar a atualização das visões
-- Justificativa: Centraliza a lógica de atualização do dashboard, facilitando
-- a manutenção e o agendamento da tarefa.

CREATE OR REPLACE PROCEDURE sp_atualizar_paineis_operacionais()
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE NOTICE 'Iniciando a atualização dos painéis operacionais...';

    REFRESH MATERIALIZED VIEW MV_DASH_STATUS_EQUIPAMENTOS;
    REFRESH MATERIALIZED VIEW MV_DASH_PROJETOS_A_VENCER;
    REFRESH MATERIALIZED VIEW MV_DASH_RELATORIOS_RECENTES;
    REFRESH MATERIALIZED VIEW MV_DASH_BOLSAS_A_VENCER;
    REFRESH MATERIALIZED VIEW MV_DASH_ANALISE_COLABORACAO;
    REFRESH MATERIALIZED VIEW MV_DASH_DESEMPENHO_COMPARATIVO;

    RAISE NOTICE 'Atualização dos painéis operacionais concluída com sucesso.';
END;
$$;

--------------------------------------------------------------------------------
-- Passo 3: Demonstração de Uso

-- Para carregar os dados do dashboard, a aplicação faria:
-- SELECT * FROM MV_DASH_STATUS_EQUIPAMENTOS;
-- ... e assim por diante para as outras 5 visões.

-- Para atualizar todos os gráficos de uma vez (ex: tarefa agendada):
-- CALL sp_atualizar_paineis_operacionais();
