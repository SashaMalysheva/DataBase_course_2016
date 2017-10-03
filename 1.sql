SELECT A.id, A.first_name, A.last_name
FROM Applicant as A
JOIN Application ON A.id = Application.applicant_id
GROUP BY A.id
HAVING COUNT(*) > 1

