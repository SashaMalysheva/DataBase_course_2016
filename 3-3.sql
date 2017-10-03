WITH 

ingredient_status as (
	SELECT  I.id, 
		I.title, 
		SUM(CASE WHEN PC.amountUnit = 'гр' THEN 0.001 ELSE 1 END * coalesce(PC.amount, 0) * coalesce(S.SoldAmount, 0)) AS amount 
		FROM Ingredients AS I 
			LEFT JOIN PieComponents AS PC on PC.IngredientID = I.ID 			LEFT JOIN Pies Pi on PC.PieID = Pi.ID 
			LEFT JOIN SalesStats AS S on Pi.ID = S.pieId and S.StatsType = tomorrow_type
	GROUP BY I.id
),

X AS (
	SELECT  N.id,
		N.title as ingredient_name, 
		(coalesce(I.amount, 0) * (CASE WHEN I.amountunit = 'гр' THEN 0.001 ELSE 1 END) - N.amount) AS shortage 
	FROM ingredient_status as N
		JOIN IngredientsRemaining AS I on I.IngredientId = N.id
)

SELECT * 
FROM X 
WHERE (
	CASE
		WHEN (SELECT MIN(X.shortage) FROM X) < 0 
		THEN X.shortage < 0 
		ELSE X.shortage = (SELECT MIN(X.shortage) FROM X) 
	END
)
