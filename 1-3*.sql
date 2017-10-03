
WITH M_C AS (
        SELECT
            EXTRACT(MONTH FROM BO.ExpectedDelivery) AS MONTH,
            SUM(BOP.Amount * P.FullWeightKg * P.PriceRubPerKg) AS income
        FROM
            BatchOrders BO
            JOIN BatchOrderPies BOP ON BO.Id = BOP.BatchOrderId
            JOIN Pies P ON BOP.PieId = P.Id
        GROUP BY MONTH
        ORDER BY MONTH
    )
SELECT
    MONTH::INT,
    income::BIGINT,
    CASE
        WHEN (LAST_VALUE(MONTH) OVER (ORDER BY MONTH ROWS 1 PRECEDING))=(FIRST_VALUE(MONTH) OVER (ORDER BY MONTH ROWS 1 PRECEDING))
        THEN NULL
        ELSE (100.0 * (LAST_VALUE(income) OVER (ORDER BY MONTH ROWS 1 PRECEDING)) / (FIRST_VALUE(income) OVER (ORDER BY MONTH ROWS 1 PRECEDING)))::NUMERIC(5, 2)
    END AS mom_growth
FROM
    M_C;
