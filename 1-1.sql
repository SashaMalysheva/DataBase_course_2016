SELECT A.Title
FROM
(
	SELECT DISTINCT I.Title, count(*) as rank 
	FROM Ingredients I
		LEFT JOIN PieComponents         PC ON I.id = PC.IngredientId
		LEFT JOIN Pies                  P  ON P.id = PC.PieId
	GROUP BY I.id
) A
WHERE A.rank <= 1


