SELECT COUNT(*)
FROM (
  SELECT COUNT(*) AS cnt
  FROM transfertype
  JOIN transfer ON transfertype.id = transfer.type
  GROUP BY ship
) C
WHERE cnt <= 1;
