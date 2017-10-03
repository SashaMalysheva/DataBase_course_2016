WITH 
F as 
(
	SELECT distinct JP.id, JP.name, A.id as app_id
	FROM Application A 
		LEFT JOIN Vacancy V ON A.expected_vacancy_id = V.id
		LEFT JOIN Jobposition JP ON V.job_position_id = JP.id
),

X AS
(
	SELECT F.id, F.name, count(*) as count
	FROM F
	GROUP BY F.id, F.name
),

Y AS
(SELECT *, row_number() over (ORDER BY count) as n from X),

Z AS
(select *, 		
		(SELECT sum(t2.count) 
		 FROM Y AS t2 WHERE t2.n >= t1.n) AS preff,
		coalesce((SELECT sum(t2.count) 
		 FROM Y AS t2 WHERE t2.n < t1.n), 0) AS suff
		 FROM Y AS t1)

SELECT Z.id, Z.name, Z.preff, Z.suff FROM Z
WHERE  Z.preff - Z.suff = (SELECT MIN(Z.preff - Z.suff) FROM Z where Z.preff - Z.suff >= 0)


