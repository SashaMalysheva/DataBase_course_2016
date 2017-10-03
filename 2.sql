WITH
Avg AS
(
	SELECT AVG(coalesce(F.grade, 0)) as cst
	FROM  Interview as I 
	JOIN Feedback as F    ON I.id = F.interview_id
)

SELECT E.id, 
	E.name, 
	AVG(coalesce(F.grade, 0)),
	(SELECT * FROM Avg)
FROM Employee as E
	LEFT JOIN Interview I ON E.id = I.interviewer_id
	LEFT JOIN Feedback as F    ON I.id = F.interview_id
GROUP BY (E.id)
HAVING  (AVG(coalesce(F.grade, 0)) > (SELECT * FROM Avg) + 0.05) 
	OR
	(AVG(coalesce(F.grade, 0)) < (SELECT * FROM Avg) - 0.05)  


