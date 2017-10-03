WITH 
E_Popu AS (
  SELECT EP.id as id, 
	 EP.name, 
	 COUNT(T.id) as cnt
  FROM EuropeanPort as EP
  	LEFT JOIN TransferType ON TransferType.eu_port = EP.id
  	LEFT JOIN Transfer as T ON T.type = TransferType.id
  GROUP BY EP.id
)

SELECT E_Popu.name, E_Popu.cnt as cnt
FROM E_Popu
WHERE (E_Popu.cnt =  (SELECT MAX(E_Popu.cnt) FROM E_Popu))


