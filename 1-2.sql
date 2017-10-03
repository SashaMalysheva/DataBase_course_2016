
WITH 
OrderCost AS (
  SELECT BP.BatchOrderId, SUM(BP.Amount * P.FullWeightKg * P.PriceRubPerKg) as cst
  FROM BatchOrderPies BP
  JOIN Pies P ON BP.PieId = P.Id
  GROUP BY (BP.BatchOrderId)
)

SELECT  C.Id, 
	SUM(CASE OC.cst IS NULL WHEN true THEN 0 ELSE OC.cst END),
	AVG(CASE OC.cst IS NULL WHEN true THEN 0 ELSE OC.cst END)
FROM Customers C
	LEFT JOIN BatchOrders BO ON C.Id = BO.Customer
	LEFT JOIN OrderCost OC ON BO.Id = OC.BatchOrderId
GROUP BY C.Id

