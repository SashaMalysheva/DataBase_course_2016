WITH 
PieCost AS (SELECT P.Id, (P.FullWeightKg * P.PriceRubPerKg) as cst FROM Pies P),

OrderCost AS (
  SELECT O.BatchOrderId, SUM(O.Amount * PC.cst) as cst
  FROM BatchOrderPies O
  JOIN PieCost PC ON O.PieId = PC.Id
  GROUP BY (O.BatchOrderId)
)

SELECT 
C.Id, 
SUM(CASE OC.cst IS NULL WHEN true THEN 0 ELSE OC.cst END),
AVG(CASE OC.cst IS NULL WHEN true THEN 0 ELSE OC.cst END)
FROM Customers C
LEFT JOIN BatchOrders O ON C.Id = O.Customer
LEFT JOIN OrderCost OC ON O.Id = OC.BatchOrderId
GROUP BY C.Id

