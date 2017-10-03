SELECT C.id, C.name 
FROM  Customers as C 
	LEFT JOIN Batchorders as B ON B.customer = C.id
WHERE B.id IS NULL

