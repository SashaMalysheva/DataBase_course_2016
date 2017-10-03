
WITH V AS 
(
	SELECT  EXTRACT(month FROM T.t_date) AS month,
		sum(ship.capacity) AS volume
	FROM Transfer as T
		JOIN transfertype ON T.type = transfertype.id
		JOIN ship ON transfertype.ship = ship.id
	GROUP BY month
)

SELECT
	V1.month :: INT AS month,
	V1.volume :: NUMERIC AS volume,
	(CASE WHEN V2.month IS NULL
		THEN 0
		ELSE 100 * ((V1.volume - V2.volume) * 1.0 / V2.volume) END) :: NUMERIC(5, 2) AS mom_growth
FROM V AS V1
LEFT JOIN V AS V2 ON V1.month = V2.month + 1;
