SELECT G.name, G.rank
FROM (
	SELECT P.name, SUM(CASE B.pax_id IS NULL WHEN TRUE then 0 else 1 END) as	 rank
FROM PAX P LEFT JOIN booking b
ON P.id = b.pax_id
GROUP BY P.name
) G
ORDER BY (-G.rank, -G.name)
LIMIT 30;
