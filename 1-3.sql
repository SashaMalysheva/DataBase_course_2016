with B_C as
(
	SELECT 
		EXTRACT(month FROM B.ExpectedDelivery) as month,
		sum(P.PriceRubPerKg * BP.Amount * P.FullWeightKg) as cost
	FROM BatchOrders B  
		JOIN BatchOrderPies        BP ON B.id = BP.BatchOrderId
		JOIN Pies		   P  ON P.id = BP.PieId
	group by month
	order by month
)

--Если предыдущего месяца не было - выводим 0
SELECT 
	BC1.month, BC1.cost::BIGINT, 
	CASE WHEN BC2.cost IS NULL THEN NULL ELSE ROUND(100 * BC1.cost / BC2.cost, 2) END as percent
from B_C BC1
LEFT JOIN B_C BC2 ON BC1.month = BC2.month + 1



