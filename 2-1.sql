SELECT I.title
FROM Ingredients I
	JOIN PieComponents PC    ON I.Id = PC.IngredientId
	JOIN Pies P		 ON P.Id = PC.PieId
GROUP BY (I.title)
HAVING (COUNT(*) > 1)
