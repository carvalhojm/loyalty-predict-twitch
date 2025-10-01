/*
curioso -> idade < 7
fiel -> recência < 7 e recência anterior < 15
turista -> 7 <= recência <= 14
desencantado -> 14 < recência <= 28
zumbi -> recência > 28
reconquistado -> recência  < 7 e 14 <= recencia anterior <= 28
reborn -> recência  < 7 e recencia anterior > 28
*/

-- usuários e interacoes unicos por dia
WITH tb_daily AS (
    SELECT DISTINCT
        IdCliente,
        substr(DtCriacao, 0, 11) AS dtDia        
    FROM transacoes
    WHERE DtCriacao <= '{date}' -- placeholder para python
),


tb_idade AS (
    SELECT IdCliente, -- calcula idade -> cria as colunas da primeira e ultima interacao
        -- min(dtDia) AS dtPrimInteracao,
        cast(max(julianday('{date}') - julianday(dtDia)) as int) AS qtdeDiasPrimeiraInteracao,
        -- max(dtDia) AS dtUltTransacao,
        cast(min(julianday('{date}') - julianday(dtDia)) as int) AS qtdeDiasUltimaInteracao

    FROM tb_daily
    GROUP BY IdCliente
),

tb_rn AS (
    SELECT *, -- rankeando dias para filtrar penultimo interacao
           row_number() OVER (PARTITION BY IdCliente ORDER BY dtDia DESC) AS rnDia
    FROM tb_daily
),

tb_penultima_interecao AS (
    SELECT *, -- cria a de penultima interacao
           CAST(julianday('{date}') - julianday(dtDia) AS INT) AS qtdeDiasPenultimaInteracao
    FROM tb_rn
    WHERE rnDia = 2
),

tb_life_cycle AS (
    SELECT t1.*, -- categoriza os usuários com base nos dias de interacao
           t2.qtdeDiasPenultimaInteracao,
           CASE
               WHEN qtdeDiasPrimeiraInteracao <= 7 THEN '01-CURIOSO'
               WHEN qtdeDiasUltimaInteracao <= 7 AND qtdeDiasPenultimaInteracao - qtdeDiasUltimaInteracao <= 14 THEN '02-FIEL'
               WHEN qtdeDiasUltimaInteracao BETWEEN 8 AND 14 THEN '03-TURISTA'
               WHEN qtdeDiasUltimaInteracao BETWEEN 15 AND 28 THEN '04-DESENCANTADO'
               WHEN qtdeDiasUltimaInteracao >= 28 THEN '05-ZUMBI'
               WHEN qtdeDiasUltimaInteracao <= 7 AND qtdeDiasPenultimaInteracao - qtdeDiasUltimaInteracao BETWEEN 15 AND 27 THEN '02-RECONQUISTADO'
               WHEN qtdeDiasUltimaInteracao <= 7 AND qtdeDiasPenultimaInteracao - qtdeDiasUltimaInteracao > 27 THEN '02-REBORN'
           END AS descLifeCycle

    FROM tb_idade AS t1

    LEFT JOIN tb_penultima_interecao AS t2
    ON t1.IdCliente = t2.IdCliente
)

SELECT date('{date}', '-1 day') AS dtRef,
       *
FROM tb_life_cycle