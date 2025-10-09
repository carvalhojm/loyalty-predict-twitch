-- ABT
CREATE TABLE abt_fiel AS

WITH tb_join AS ( 

    SELECT t1.dtRef, -- coluna temporal
           t1.IdCliente,
           t1.descLifeCycle,
           t2.descLifeCycle, -- 28 dias para frente no futuro da base
           CASE WHEN t2.descLifeCycle = '02-FIEL' THEN 1 ELSE 0 END AS flFiel, -- variavel resposta (flag)
           row_number() OVER(PARTITION BY t1.IdCliente ORDER BY random()) AS RandomCol -- criando numero aleatorio para outro parametro de seleção para diminuir vies (filtro)

    FROM life_cycle AS t1

    LEFT JOIN life_cycle AS t2 -- futuro em relação ao passado
    ON t1.IdCliente = t2.IdCliente
    AND date(t1.dtRef, '+28 day') = date(t2.dtRef)

    WHERE ((t1.dtRef >= '2024-03-01' AND t1.dtRef <= '2025-08-01') 
            OR t1.dtRef = '2025-09-01') -- safra e safra virgem para aplicar no modelo dados separados temporalmente
    AND t1.descLifeCycle <> '05-ZUMBI' -- retirando zumbis

),

tb_cohort AS (

    SELECT t1.dtRef,
           t1.IdCliente,
           t1.flFiel

    FROM tb_join AS t1

    WHERE RandomCol <= 2 -- reduzindo a autocorrelação nos usuários selecionando só duas datas
    ORDER BY idCliente, dtRef

)

SELECT t1.*, -- juntando todas as feature stores
       t2.idadeDias,
       t2.qtdeAtivacaoVida,
       t2.qtdeAtivacaoD7,
       t2.qtdeAtivacaoD14,
       t2.qtdeAtivacaoD28,
       t2.qtdeAtivacaoD56,
       t2.qtdeTransacaoVida,
       t2.qtdeTransacaoD7,
       t2.qtdeTransacaoD14,
       t2.qtdeTransacaoD28,
       t2.qtdeTransacaoD56,
       t2.saldoVida,
       t2.saldoD7,
       t2.saldoD14,
       t2.saldoD28,
       t2.saldoD56,
       t2.qtdePontosPosVida,
       t2.qtdePontosPosD7,
       t2.qtdePontosPosD14,
       t2.qtdePontosPosD28,
       t2.qtdePontosPosD56,
       t2.qtdePontosNegVida,
       t2.qtdePontosNegD7,
       t2.qtdePontosNegD14,
       t2.qtdePontosNegD28,
       t2.qtdePontosNegD56,
       t2.qtdeTransacaoManha,
       t2.qtdeTransacaoTarde,
       t2.qtdeTransacaoNoite,
       t2.pctTransacaoManha,
       t2.pctTransacaoTarde,
       t2.pctTransacaoNoite,
       t2.qtdeTransacaoDiaVida,
       t2.qtdeTransacaoDiaD7,
       t2.qtdeTransacaoDiaD14,
       t2.qtdeTransacaoDiaD28,
       t2.qtdeTransacaoDiaD56,
       t2.pctAtivacaoMAU,
       t2.qtdeHorasVida,
       t2.qtdeHorasD7,
       t2.qtdeHorasD14,
       t2.qtdeHorasD28,
       t2.qtdeHorasD56,
       t2.avgIntervaloDiasVida,
       t2.avgIntervaloDias28,
       t2.qtdeChatMessage,
       t2.qtdeAirflowLover,
       t2.qtdeRLover,
       t2.qtdeResgatarPonei,
       t2.qtdeListadepresenca,
       t2.qtdePresencaStreak,
       t2.qtdeTrocadePontosStremElements,
       t2.qtdeRpg,
       t2.qtdeChurn_model,
       t3.qtdeFrequencia,
       t3.descLifeCycleAtual,
       t3.descLifeCycleD28,
       t3.pctCurioso,
       t3.pctFiel,
       t3.pctTurista,
       t3.pctDesencantada,
       t3.pctZumbi,
       t3.pctReconquistado,
       t3.pctReborn,
       t3.avgFreqGrupo,
       t3.ratioFreqGrupo,
       t4.qtdeCursosCompletos,
       t4.qtdeCursosIncompletos,
       t4.carreira,
       t4.coletaDados2024,
       t4.dsDatabricks2024,
       t4.dsPontos2024,
       t4.estatistica2024,
       t4.estatistica2025,
       t4.github2024,
       t4.github2025,
       t4.iaCanal2025,
       t4.lagoMago2024,
       t4.machineLearning2025,
       t4.matchmakingTramparDeCasa2024,
       t4.ml2024,
       t4.mlflow2025,
       t4.pandas2024,
       t4.pandas2025,
       t4.python2024,
       t4.python2025,
       t4.sql2020,
       t4.sql2025,
       t4.streamlit2025,
       t4.tramparLakehouse2024,
       t4.tseAnalytics2024,
       t4.qtdeDiasUltiAtividade

FROM tb_cohort AS t1

LEFT JOIN fs_transacional AS t2
ON t1.IdCliente = t2.idCliente
AND t1.dtRef = t2.dtRef

LEFT JOIN fs_life_cycle AS t3
ON t1.IdCliente = t3.idCliente
AND t1.dtRef = t3.dtRef

LEFT JOIN fs_education AS t4
ON t1.IdCliente = t4.idCliente
AND t1.dtRef = t4.dtRef