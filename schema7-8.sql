DROP TABLE IF EXISTS JobPosition CASCADE;
DROP TABLE IF EXISTS Employee CASCADE;
DROP TABLE IF EXISTS Vacancy CASCADE;
DROP TABLE IF EXISTS Applicant CASCADE;
DROP TABLE IF EXISTS Application CASCADE;
DROP TYPE IF EXISTS Verdict CASCADE;
DROP TABLE IF EXISTS FilteredApplication CASCADE;
DROP TYPE IF EXISTS InterviewType CASCADE;
DROP TABLE IF EXISTS Interview CASCADE;
DROP TABLE IF EXISTS Feedback CASCADE;


CREATE TABLE JobPosition (
	id SERIAL PRIMARY KEY,
	name TEXT UNIQUE NOT NULL,
	min_salary INTEGER NOT NULL CHECK(min_salary >= 0),
	max_salary INTEGER NOT NULL CHECK(max_salary >= min_salary)
);

INSERT INTO JobPosition(name, min_salary, max_salary) VALUES
  ('CEO', 5000, 10000),
  ('Technical Lead', 1500, 4000),
  ('Senior SWE', 800, 2000),
  ('Software Engineer', 800, 1500),
  ('Junior SWE', 500, 1000),
  ('QA', 500, 2000),
  ('Garbage Collector', 200, 300);
-- Сотрудник компании
CREATE TABLE Employee (
	id SERIAL PRIMARY KEY,
	name TEXT NULL
);
INSERT INTO Employee(name)
  SELECT unnest(ARRAY[
    'Иван Бездомный','Михаил Берлиоз', 'Степан  Лиходеев', 'Григорий Римский', 'Фагот', 'Азазелло', 'Бегемот',
    'Никанор Босой', 'Иван Варенуха', 'Понтий Пилат', 'Левий Матфей', 'Алоизий Могарыч',
    'Жорж Бенгальский', 'Маргарита', 'Наташа', 'Гелла', 'Аркадий Семплеяров'
  ]);


CREATE TABLE Vacancy (
	id SERIAL PRIMARY KEY,
	open_date TIMESTAMP WITH TIME ZONE NOT NULL,
	job_position_id INTEGER REFERENCES JobPosition(id),
	customer_id INTEGER REFERENCES Employee(id),
  is_open BOOLEAN
);
INSERT INTO Vacancy(open_date, job_position_id, customer_id, is_open)
SELECT
  (timestamp '2016-06-01' + random() * interval '180 days')::date,
  GREATEST(1, random() + random() +random() +random() +random() +random() +random())::INT,
  (0.5 + random() * (SELECT COUNT(*) FROM Employee))::int,
  random() > 0.75
FROM generate_series(1, 30);


CREATE TABLE Applicant (
	id SERIAL PRIMARY KEY,
	first_name TEXT NOT NULL,
	middle_name TEXT NULL, -- отчества может не быть
	last_name TEXT NOT NULL,
	cv_url TEXT NOT NULL UNIQUE
);
WITH men AS (
  SELECT random()::TEXT AS name, random() AS flag FROM generate_series(1, 200)
), women AS(
  SELECT random()::TEXT  AS name, random()AS flag FROM generate_series(1, 20)
), AllApplicants AS (
  SELECT * FROM men WHERE flag>0.75 UNION SELECT * FROM women WHERE flag>0.75
)
INSERT INTO Applicant(first_name, last_name, cv_url)
SELECT split_part(name, '_', 1) AS first_name,
       split_part(name, '_', 2) AS last_name,
       'http://hh.ru/'|| (random()*10000)::INT::TEXT || '/' || name || '.pdf' AS cv_url
FROM AllApplicants ORDER BY flag LIMIT 200;

CREATE TABLE Application (
	id SERIAL PRIMARY KEY,
	applicant_id INTEGER REFERENCES Applicant(id),
	expected_vacancy_id INTEGER REFERENCES Vacancy(id),
	expected_salary INTEGER NOT NULL CHECK(expected_salary >= 0),
	UNIQUE (applicant_id, expected_vacancy_id)
);

INSERT INTO Application(applicant_id, expected_vacancy_id, expected_salary)
SELECT *, random()*5000::INT FROM (
  SELECT id,
         (0.5 + random() * (SELECT COUNT(*) FROM Vacancy))::int
  FROM Applicant
) AS T;

WITH Duplicates AS (
  SELECT applicant_id, (0.5 + random() * (SELECT COUNT(*) FROM Vacancy))::int AS expected_vacancy_id, expected_salary
  FROM Application
  WHERE random()>0.9
)
INSERT INTO Application(applicant_id, expected_vacancy_id, expected_salary)
SELECT D.* FROM Duplicates D LEFT JOIN Application A USING(applicant_id, expected_vacancy_id)
WHERE A.applicant_id IS NULL;

CREATE TYPE Verdict AS ENUM('strong hire', 'hire', 'weak reject', 'reject');


CREATE TABLE FilteredApplication (
	application_id INTEGER PRIMARY KEY REFERENCES Application(id),
	verdict Verdict NULL
);
WITH Data AS (
  SELECT id, random() AS rnd
  FROM Application
)
INSERT INTO FilteredApplication(application_id, verdict)
SELECT id, (CASE WHEN rnd BETWEEN 0.9 AND 1 THEN 'strong hire'
                WHEN rnd BETWEEN 0.75 AND 0.9 THEN 'hire'
                WHEN rnd BETWEEN 0.5 AND 0.75 THEN 'weak reject'
                WHEN rnd BETWEEN 0.2 AND 0.5 THEN 'reject'
                ELSE NULL
           END)::Verdict
FROM Data;

CREATE TYPE InterviewType AS ENUM('onsite', 'phone');


CREATE TABLE Interview (
	id SERIAL PRIMARY KEY,
	interview_type InterviewType,
	start_time TIMESTAMP WITH TIME ZONE NOT NULL CHECK(
		EXTRACT(EPOCH FROM start_time)::INTEGER % EXTRACT(EPOCH FROM INTERVAL '1h')::INTEGER = 0),
	application_id INTEGER REFERENCES FilteredApplication(application_id),
	interviewer_id INTEGER REFERENCES Employee(id),
	UNIQUE (start_time, interviewer_id),
	UNIQUE (start_time, application_id)
);
WITH Nums AS (
  SELECT generate_series(1, 150) AS num
),
Dates AS (
  SELECT DISTINCT (timestamp '2016-06-01' + num * interval '1 day')::date as interview_date, num
  FROM Nums
),
DatesEmployees AS (
  SELECT Dates.*,
  (SELECT array_agg((0.5 + random() * (SELECT COUNT(*)-1 FROM Employee))::INT) FROM generate_series(num, num+3)) as employees
  FROM Dates
),
ApplNums AS (
  SELECT MAX(application_id) AS application_id, num FROM (
    SELECT application_id, (0.5 + random()*150)::INT AS num
    FROM FilteredApplication
  ) T
  GROUP BY num
),
Data AS (
  SELECT application_id, employee_id,
    interview_date + interval '11 hours' + interval '1 hour' * ROW_NUMBER() OVER (PARTITION BY num ORDER BY employee_id),
    (CASE random() > 0.8 WHEN true THEN 'phone' ELSE 'onsite' END)::InterviewType
  FROM ApplNums JOIN (
    SELECT DISTINCT interview_date, num, unnest(employees) AS employee_id
    FROM DatesEmployees
  ) T USING (num)
)
INSERT INTO Interview(application_id, interviewer_id, start_time, interview_type)
SELECT * FROM Data;

CREATE TABLE Feedback (
	interview_id INTEGER PRIMARY KEY REFERENCES Interview(id),
	grade DECIMAL(2, 1) NOT NULL CHECK(grade >= 1 AND grade <= 4),
	comment TEXT NULL
);
INSERT INTO Feedback(interview_id, grade)
SELECT id, LEAST(4, 1 + (random() + random() + random() + random())::NUMERIC)::NUMERIC(2,1)
FROM Interview;
