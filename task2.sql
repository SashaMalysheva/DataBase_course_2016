-- 2.1
SELECT I.title
FROM Ingredients I
JOIN PieComponents PC ON PC.IngredientId = I.Id
JOIN Pies P ON P.Id = PC.PieId
GROUP BY (I.title)
HAVING (COUNT(*) > 1)


-- 1.2
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

-- 2.3
WITH 
PieCost AS (SELECT P.Id, (P.FullWeightKg * P.PriceRubPerKg) as cst FROM Pies P),
TotalCost AS (
  SELECT 
    P.Id, 
    SUM(P.cst * (CASE S.SoldAmount IS NULL WHEN true THEN 0 ELSE S.SoldAmount END)) as cst
  FROM PieCost P
  LEFT JOIN SalesStats S ON P.Id = S.PieId
  GROUP BY P.Id  
)

SELECT TC.Id, TC.cst, round(100.0 * TC.cst / (Sum(TC.cst) OVER ()), 2)
FROM TotalCost TC