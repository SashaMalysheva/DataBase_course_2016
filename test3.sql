-- Task 33
WITH
    dist AS ( -- select the distinct candidates
        SELECT DISTINCT
            j.name::TEXT AS job_name,
            j.id::INT AS job_id,
            an.applicant_id
        FROM
            Application an
            JOIN VACAncy V ON an.expected_vacancy_id=v.id
            JOIN JobPosition J ON v.job_position_id=j.id
    ),
    pop AS ( -- count the popularity of the given vacancy
        SELECT
            job_name,
            job_id,
            COUNT(job_id) AS cnt
        FROM
            dist
        GROUP BY 
            job_name, job_id
    ),
    prsf AS ( -- count all the stats regardless the prefix/suffix relations
        SELECT
            job_id,
            job_name,
            (SUM(cnt) OVER (ORDER BY cnt DESC, job_name DESC))::BIGINT AS prefix_applicant_cnt,
            (SUM(cnt) OVER () - SUM(cnt) OVER (ORDER BY cnt DESC, job_name DESC))::BIGINT AS suffix_applicant_cnt
        FROM
            pop
    )
SELECT DISTINCT *
FROM prsf
WHERE prefix_applicant_cnt >= suffix_applicant_cnt -- select only what we want
ORDER BY prefix_applicant_cnt
LIMIT 1;
--

