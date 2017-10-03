WITH 
C_P AS (
	SELECT  P.id, 
		P.title as name, 
		SUM(CASE WHEN B.amount IS NULL THEN 0 ELSE 1 END) as ordered_pies_cnt 
	FROM Pies as P LEFT JOIN BatchorderPies AS B ON B.PieID = P.id
	GROUP BY P.id
)

SELECT * 
FROM C_P
WHERE C_P.ordered_pies_cnt = (SELECT MIN(C_P.ordered_pies_cnt) FROM C_P)
