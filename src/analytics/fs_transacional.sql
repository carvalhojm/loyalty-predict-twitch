-- frequencias em dias

WITH tb_transacao AS (

    SELECT *,
           substr(dtCriacao, 0, 11) AS dtDia,
           cast(substr(DtCriacao, 12, 2) AS int) AS dtHora

    FROM transacoes
    WHERE dtCriacao < '{date}'
),

tb_agg_transacao AS (

       SELECT IdCliente, 
       
              -- idade na base (primeira interacao)
              max(julianday(date('{date}', '-1 day')) - julianday(dtCriacao)) AS idadeDias,

              -- frequencia em dias
              count(DISTINCT dtDia) AS qtdeAtivacaoVida,
              count(DISTINCT CASE WHEN dtDia >= date( '{date}', '-7 day') THEN dtDia END) AS qtdeAtivacaoD7,
              count(DISTINCT CASE WHEN dtDia >= date( '{date}', '-14 day') THEN dtDia END) AS qtdeAtivacaoD14,
              count(DISTINCT CASE WHEN dtDia >= date( '{date}', '-28 day') THEN dtDia END) AS qtdeAtivacaoD28,
              count(DISTINCT CASE WHEN dtDia >= date( '{date}', '-56 day') THEN dtDia END) AS qtdeAtivacaoD56,

              -- frenquencia em transacoes
              count(DISTINCT IdTransacao) AS qtdeTransacaoVida,
              count(DISTINCT CASE WHEN dtDia >= date( '{date}', '-7 day') THEN IdTransacao END) AS qtdeTransacaoD7,
              count(DISTINCT CASE WHEN dtDia >= date( '{date}', '-14 day') THEN IdTransacao END) AS qtdeTransacaoD14,
              count(DISTINCT CASE WHEN dtDia >= date( '{date}', '-28 day') THEN IdTransacao END) AS qtdeTransacaoD28,
              count(DISTINCT CASE WHEN dtDia >= date( '{date}', '-56 day') THEN IdTransacao END) AS qtdeTransacaoD56,

              -- valor dos pontos
              sum(qtdePontos) AS saldoVida,
              sum(CASE WHEN dtDia >= date( '{date}', '-7 day') THEN qtdePontos  ELSE 0 END) AS saldoD7,
              sum(CASE WHEN dtDia >= date( '{date}', '-14 day') THEN qtdePontos ELSE 0 END) AS saldoD14,
              sum(CASE WHEN dtDia >= date( '{date}', '-28 day') THEN qtdePontos ELSE 0 END) AS saldoD28,
              sum(CASE WHEN dtDia >= date( '{date}', '-56 day') THEN qtdePontos ELSE 0 END) AS saldoD56,

              -- quantidade pontos positivos
              sum(CASE WHEN qtdePontos > 0 THEN qtdePontos ELSE 0 END) AS qtdePontosPosVida,
              sum(CASE WHEN dtDia >= date( '{date}', '-7 day') AND qtdePontos > 0 THEN qtdePontos  ELSE 0 END) AS qtdePontosPosD7,
              sum(CASE WHEN dtDia >= date( '{date}', '-14 day') AND qtdePontos > 0 THEN qtdePontos ELSE 0 END) AS qtdePontosPosD14,
              sum(CASE WHEN dtDia >= date( '{date}', '-28 day') AND qtdePontos > 0 THEN qtdePontos ELSE 0 END) AS qtdePontosPosD28,
              sum(CASE WHEN dtDia >= date( '{date}', '-56 day') AND qtdePontos > 0 THEN qtdePontos ELSE 0 END) AS qtdePontosPosD56,

              -- quantidade pontos negativos
              sum(CASE WHEN qtdePontos < 0 THEN qtdePontos ELSE 0 END) AS qtdePontosNegVida,
              sum(CASE WHEN dtDia >= date( '{date}', '-7 day') AND qtdePontos < 0 THEN qtdePontos  ELSE 0 END) AS qtdePontosNegD7,
              sum(CASE WHEN dtDia >= date( '{date}', '-14 day') AND qtdePontos < 0 THEN qtdePontos ELSE 0 END) AS qtdePontosNegD14,
              sum(CASE WHEN dtDia >= date( '{date}', '-28 day') AND qtdePontos < 0 THEN qtdePontos ELSE 0 END) AS qtdePontosNegD28,
              sum(CASE WHEN dtDia >= date( '{date}', '-56 day') AND qtdePontos < 0 THEN qtdePontos ELSE 0 END) AS qtdePontosNegD56,

              -- periodo assistido -- ajustando hoprarios de UTC para BRT (UTC -3)
              count(CASE WHEN dtHora BETWEEN 10 AND 14 THEN IdTransacao END) AS qtdeTransacaoManha,
              count(CASE WHEN dtHora BETWEEN 15 AND 21 THEN IdTransacao END) AS qtdeTransacaoTarde,
              count(CASE WHEN dtHora > 21 OR dtHora < 10 THEN IdTransacao END) AS qtdeTransacaoNoite, -- madrugada vira noite porque quase nao tem

              -- percentual de periodo assistido -- ajustando hoprarios de UTC para BRT (UTC -3)
              1. * count(CASE WHEN dtHora BETWEEN 10 AND 14 THEN IdTransacao END) / count(IdTransacao) AS pctTransacaoManha,
              1. * count(CASE WHEN dtHora BETWEEN 15 AND 21 THEN IdTransacao END) / count(IdTransacao) AS pctTransacaoTarde,
              1. * count(CASE WHEN dtHora > 21 OR dtHora < 10 THEN IdTransacao END) / count(IdTransacao) AS pctTransacaoNoite 


       FROM tb_transacao

       GROUP BY IdCliente

),

tb_agg_calc AS (

       SELECT 
              *,
              -- quantidade de transações 
              COALESCE( 1. * qtdeTransacaoVida / qtdeAtivacaoVida, 0) AS qtdeTransacaoDiaVida,
              COALESCE( 1. * qtdeTransacaoD7   / qtdeAtivacaoD7, 0) AS qtdeTransacaoDiaD7,
              COALESCE( 1. * qtdeTransacaoD14  / qtdeAtivacaoD14, 0) AS qtdeTransacaoDiaD14,
              COALESCE( 1. * qtdeTransacaoD28  / qtdeAtivacaoD28, 0) AS qtdeTransacaoDiaD28,
              COALESCE( 1. * qtdeTransacaoD56  / qtdeAtivacaoD56, 0) AS qtdeTransacaoDiaD56,

              -- percentural de ativação do MAU
              COALESCE( 1. * qtdeAtivacaoD28 / 28, 0) AS pctAtivacaoMAU
              
       FROM tb_agg_transacao

),

tb_horas_dia AS (

       SELECT IdCliente,
              dtDia,
              -- max(julianaday(dtCriacao)) AS dtFinal,
              -- min(julianaday(dtCriacao)) AS dtInicio
              24 * (max(julianday(dtCriacao)) - min(julianday(dtCriacao))) AS duracao -- em horas - 0 só uma interacao


       FROM tb_transacao
       GROUP BY IdCliente, dtDia

),

tb_hora_cliente AS (
       SELECT IdCliente, -- horas assistidas
              sum(duracao) AS qtdeHorasVida,
              sum(CASE WHEN dtDia >= date('{date}', '-7 day') THEN duracao ELSE 0 END) AS qtdeHorasD7,
              sum(CASE WHEN dtDia >= date('{date}', '-14 day') THEN duracao ELSE 0 END) AS qtdeHorasD14,
              sum(CASE WHEN dtDia >= date('{date}', '-28 day') THEN duracao ELSE 0 END) AS qtdeHorasD28,
              sum(CASE WHEN dtDia >= date('{date}', '-56 day') THEN duracao ELSE 0 END) AS qtdeHorasD56

       FROM tb_horas_dia
       GROUP BY IdCliente
),

tb_lag_dia AS (

       SELECT IdCliente,
              dtDia,
              LAG(dtDia) OVER (PARTITION BY IdCliente ORDER BY dtDia) AS lagDia

       FROM tb_horas_dia
),

tb_intervalo_dias AS (

       SELECT IdCliente, -- intervalo desde ultima interacao em dia
              -- quantos dias desde que não interagia
              -- julianday(dtDia) - julianday(lagDia) AS diffDay
              avg(julianday(dtDia) - julianday(lagDia)) AS avgIntervaloDiasVida,
              avg(CASE WHEN dtDia >= date('{date}', '-28 day') THEN julianday(dtDia) - julianday(lagDia) END) AS avgIntervaloDias28 -- se null tende a infinito (corrigir depois com o maior intervalo da base no pipeline)

       FROM tb_lag_dia
       GROUP BY IdCliente
),

tb_share_produtos AS (

       SELECT -- percentual de qual produto cada usuário utiliza
              IdCliente, -- não da para confirmar que todos os produtos estão aqui, tem produtos não cadastrados
              1. * COUNT(CASE WHEN descNomeProduto = 'ChatMessage' THEN t1.IdTransacao END) / count(t1.IdTransacao) AS qtdeChatMessage,
              1. * COUNT(CASE WHEN descNomeProduto = 'Airflow Lover' THEN t1.IdTransacao END) / count(t1.IdTransacao) AS qtdeAirflowLover,
              1. * COUNT(CASE WHEN descNomeProduto = 'R Lover' THEN t1.IdTransacao END) / count(t1.IdTransacao) AS qtdeRLover,
              1. * COUNT(CASE WHEN descNomeProduto = 'Resgatar Ponei' THEN t1.IdTransacao END) / count(t1.IdTransacao) AS qtdeResgatarPonei,
              1. * COUNT(CASE WHEN descNomeProduto = 'Lista de presença ' THEN t1.IdTransacao END) / count(t1.IdTransacao) AS qtdeListadepresenca ,
              1. * COUNT(CASE WHEN descNomeProduto = 'Presença Streak' THEN t1.IdTransacao END) / count(t1.IdTransacao) AS qtdePresencaStreak,
              1. * COUNT(CASE WHEN descNomeProduto = 'Troca de Pontos StremElements' THEN t1.IdTransacao END) / count(t1.IdTransacao) AS qtdeTrocadePontosStremElements,
              1. * COUNT(CASE WHEN descNomeProduto = 'Reembolso: Troca de Pontos StreamElements' THEN t1.IdTransacao END) / count(t1.IdTransacao) AS qtdeReembolsoTrocadePontosStreamElements,
              1. * COUNT(CASE WHEN descCategoriaProduto = 'rpg' THEN t1.IdTransacao END) / count(t1.IdTransacao) AS qtdeRpg,
              1. * COUNT(CASE WHEN descCategoriaProduto = 'churn_model' THEN t1.IdTransacao END) / count(t1.IdTransacao) AS qtdeChurn_model

       FROM tb_transacao AS t1

       LEFT JOIN transacao_produto AS t2
       ON t1.IdTransacao = t2.IdTransacao

       LEFT JOIN produtos AS t3
       ON t2.IdProduto = t3.IdProduto

       GROUP BY IdCliente
),

tb_join AS (

       SELECT t1.*, -- features transacionais (interação chat)
              t2.qtdeHorasVida,
              t2.qtdeHorasD7,
              t2.qtdeHorasD14,
              t2.qtdeHorasD28,
              t2.qtdeHorasD56,
              t3.avgIntervaloDiasVida,
              t3.avgIntervaloDias28,
              t4.qtdeChatMessage,
              t4.qtdeAirflowLover,
              t4.qtdeRLover,
              t4.qtdeResgatarPonei,
              t4.qtdeListadepresenca,
              t4.qtdePresencaStreak,
              t4.qtdeTrocadePontosStremElements,
              t4.qtdeRpg,
              t4.qtdeChurn_model

       FROM tb_agg_calc AS t1

       LEFT JOIN tb_hora_cliente AS t2 
       ON t1.IdCliente = t2.IdCliente

       LEFT JOIN tb_intervalo_dias AS t3
       ON t1.IdCliente = t3.IdCliente

       LEFT JOIN tb_share_produtos AS t4 
       ON t1.IdCliente = t4.IdCliente
)

SELECT date('{date}', '-1 day') as dtRef,
       *
FROM tb_join