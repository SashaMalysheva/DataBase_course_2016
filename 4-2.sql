SELECT  CoffeeCustomer.id AS customer_id, 
	SUM(CASE Ship.id IS NULL WHEN true THEN 0 ELSE Ship.capacity * CoffeeCustomer.price END)::NUMERIC AS sum,
	AVG(CASE Ship.id IS NULL WHEN true THEN 0 ELSE Ship.capacity * CoffeeCustomer.price END)::NUMERIC AS avg
FROM CoffeeCustomer
	LEFT JOIN Transfer ON CoffeeCustomer.id = Transfer.customer_id
	LEFT JOIN TransferType ON Transfer.type = TransferType.id
	LEFT JOIN Ship ON TransferType.ship = Ship.id
GROUP BY CoffeeCustomer.id;
