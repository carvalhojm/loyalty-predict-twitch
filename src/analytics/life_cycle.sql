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
),

tb_freq_valor AS (
    SELECT IdCliente,
        count(DISTINCT substr(DtCriacao, 0, 11)) AS qtdeFrequencia,
        sum(CASE WHEN QtdePontos > 0 THEN QtdePontos ELSE 0 END) as qtdePontosPos
        -- sum(abs(QtdePontos)) as qtdePontosAbs

    FROM transacoes

    WHERE DtCriacao < '{date}'
    AND DtCriacao >= date('{date}', '-28 day')

    GROUP BY idCliente

    ORDER BY DtCriacao DESC
),

tb_cluster AS (
    SELECT *,
            CASE 
                WHEN qtdeFrequencia <= 10 AND qtdePontosPos >= 1500 THEN '12-HYPER'
                WHEN qtdeFrequencia > 10 AND qtdePontosPos >= 1500 THEN '22-EFICIENTE'
                WHEN qtdeFrequencia <= 10 AND qtdePontosPos >= 750 THEN '11-INDECISO'
                WHEN qtdeFrequencia > 10 AND qtdePontosPos >= 750 THEN '21-ESFORÇADO'
                WHEN qtdeFrequencia < 5 THEN '00-LURKER'
                WHEN qtdeFrequencia <= 10 THEN '01-PREGUIÇOSO'
                WHEN qtdeFrequencia > 10 THEN '20-POTENCIAL'
            END AS cluster
                
    FROM tb_freq_valor
)


SELECT 
       date('{date}', '-1 day') AS dtRef,
       t1.*,
       t2.qtdeFrequencia,
       t2.qtdePontosPos,
       t2.cluster

FROM tb_life_cycle AS t1

LEFT JOIN tb_cluster As t2
ON t1.IdCliente = t2.IdCliente