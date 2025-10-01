-- quantidade de usuários ativos por dia

SELECT substr(DtCriacao, 0, 11) AS DtDia, 
       count(DISTINCT IdCliente) AS DAU
FROM transacoes
GROUP BY 1
ORDER BY DtDia