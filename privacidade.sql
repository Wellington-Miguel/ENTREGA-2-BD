

-- PASSO 1: CRIAÇÃO DOS PAPÉIS (ROLES)

CREATE ROLE gestor_estrategico;
CREATE ROLE coordenador_operacional;
CREATE ROLE auditor_externo;

-- PASSO 2: CONCESSÃO DE PERMISSÕES GRANULARES

-- Permissões para o COORDENADOR OPERACIONAL
-- Permite gerenciar as principais tabelas operacionais.
GRANT SELECT, INSERT, UPDATE ON
    TB_PESQUISADOR,
    TB_PROJETO,
    TB_EQUIPAMENTO,
    TB_RELATORIO,
    TB_AVALIACAO,
    TB_PESQUISADOR_PROJETO,
    TB_PESQUISADOR_LABORATORIO
TO coordenador_operacional;

-- Permissão para chamar as procedures de negócio
GRANT EXECUTE ON PROCEDURE sp_cadastrar_pesquisador_em_projeto TO coordenador_operacional;
GRANT EXECUTE ON PROCEDURE sp_inscrever_pesquisador_evento TO coordenador_operacional;
-- ...e assim por diante para outras procedures.


-- Permissões para o GESTOR ESTRATÉGICO
-- Acesso de leitura às visões materializadas dos dashboards.
GRANT SELECT ON
    MV_DASH_FINANCIADOR_IMPACTO,
    MV_DASH_PRODUTIVIDADE_AREA,
    MV_DASH_ALOCACAO_PESQUISADORES,
    MV_DASH_CARGA_VS_DESEMPENHO,
    MV_DASH_STATUS_EQUIPAMENTOS
TO gestor_estrategico;

-- Para proteger o e-mail do pesquisador, criamos uma VIEW que mascara o dado.
CREATE VIEW VW_PESQUISADORES_MASCARADOS AS
SELECT
    ID_PESQUISADOR,
    NM_PESQUISADOR,
    -- Mascara o e-mail, mostrando apenas o início e o domínio
    CONCAT(SUBSTRING(DS_EMAIL, 1, 3), '...
@', SPLIT_PART(DS_EMAIL, '@', 2)) AS DS_EMAIL_MASCARADO,
    DS_TITULACAO,
    ST_REGISTRO_ATIVO
FROM
    TB_PESQUISADOR;

-- O gestor terá acesso a esta VIEW, e não à tabela original.
GRANT SELECT ON VW_PESQUISADORES_MASCARADOS TO gestor_estrategico;


-- Permissões para o AUDITOR EXTERNO
-- Acesso de leitura apenas a dados públicos e não sensíveis.
GRANT SELECT ON TB_PUBLICACAO TO auditor_externo;
GRANT SELECT (ID_PROJETO, NM_PROJETO, DT_INICIO, DT_FINAL, ST_PROJETO) ON TB_PROJETO TO auditor_externo;


