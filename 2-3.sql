WITH TotalCost AS (
SELECT  P.Id, 
	SUM(P.FullWeightKg * P.PriceRubPerKg * (CASE S.SoldAmount IS NULL WHEN true THEN 0 ELSE S.SoldAmount END)) as cst
  FROM Pies P
  LEFT JOIN SalesStats S ON P.Id = S.PieId
  GROUP BY P.Id  
)

SELECT TC.Id, TC.cst, round(100 * TC.cst / (Sum(TC.cst) OVER ()), 2)
FROM TotalCost TC

