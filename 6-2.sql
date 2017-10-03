SELECT  AmericanPort.name, 
	EuropeanPort.name, 
	SUM(Ship.capacity) as volume
FROM TransferType
	INNER JOIN AmericanPort ON TransferType.am_port = AmericanPort.id 
	INNER JOIN EuropeanPort ON TransferType.eu_port = EuropeanPort.id 
	INNER JOIN Ship         ON TransferType.ship    = Ship.id
	INNER JOIN Transfer     ON Transfer.type        = TransferType.id
GROUP BY (AmericanPort.id, EuropeanPort.id)
ORDER BY volume DESC
LIMIT 1;
