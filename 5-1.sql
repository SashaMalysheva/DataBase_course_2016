WITH Plantations AS (
  SELECT Plantation.* 
  FROM Plantation 
  	INNER JOIN AmericanPort ON 
		AmericanPort.id = Plantation.port_id 
		AND 
		AmericanPort.country_id != Plantation.country_id
)
SELECT  AmericanCountry.id, 
	SUM(CASE Plantations.id IS NULL WHEN true THEN 0 ELSE 1 END) AS cnt
FROM AmericanCountry
	LEFT JOIN Plantations ON AmericanCountry.id = Plantations.country_id
GROUP BY AmericanCountry.id;
