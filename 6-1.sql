SELECT  C.id, 
	C.name
FROM CoffeeCustomer as C 
	LEFT JOIN Transfer ON C.id = Transfer.customer_id
GROUP BY C.id
HAVING (SUM(CASE Transfer.customer_id IS NULL WHEN true THEN 0 ELSE 1 END) = 0)
