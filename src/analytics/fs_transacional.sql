-- frequencias em dias

WITH tb_transacao AS (

    SELECT *,
           substr(dtCriacao, 0, 11) AS dtDia  

    FROM transacoes

    WHERE dtCriacao < '2025-09-28'
)

SELECT IdClienete, -- frequencia em dias
       count(DISTINCT dtDia) AS qtdeAtivacaoVida,
       count(DISTINCT CASE WHEN dtDia >= date( '2025-09-28', '-7 day') THEN dtDia END) AS qtdeAtivacaoD7

       -- frenquencia em transacoes

       -- valor dos pontos

       -- quantidade pontos positivos

       -- 

FROM tb_transacao

GROUP BY IdClienete

tb_agg_calculado
 -- quantidade transacao

 -- percentual mau

-- fim do with
)

tb_horas_dias
SELECT
-- horas assistidas
)
-- fim do with

tb_hora_cliente
-- horas assistidas por dia

)
tb_lag_dia
-- quantidade de dias que a pessoa vem
)

-- intervalo de dias para voltar 
-- media de intervalo entre os dias

