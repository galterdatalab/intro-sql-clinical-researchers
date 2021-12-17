-- Basic Operations
SELECT 2 + 4
SELECT ROUND(2.5834, 2)
SELECT 'Hello' + ' there ' + 'friends!'

-- Selecting and Filtering

-- One Column
SELECT patient_id
FROM patient_mrns

-- Two Columns
SELECT patient_id, patient_mrn_id
FROM patient_mrns

-- All Columns
SELECT *
FROM patient_mrns

-- DISTINCT
SELECT DISTINCT patient_id
FROM patient_mrns

-- TOP
SELECT TOP 3 patient_id,  patient_mrn_id
FROM patient_mrns

-- WHERE
SELECT start_dts, end_dts
FROM edw_emr_ods.encounters
WHERE patient_id = '1'

--WHERE AND
SELECT patient_id, department_id, start_dts, end_dts
FROM edw_emr_ods.encounters
WHERE patient_id = '1' AND department_id = '4'

--WHERE AND OR
SELECT patient_id, department_id, start_dts, end_dts
FROM edw_emr_ods.encounters
WHERE patient_id = '1' AND department_id = '2' OR department_id = '4'

-- BETWEEN
SELECT patient_id, department_id, start_dts, end_dts
FROM edw_emr_ods.encounters
WHERE start_dts BETWEEN '2009-05-23' AND '2011-05-11'

-- WHERE IN
SELECT *
FROM diagnoses
WHERE title in ('Shortness of breath', 'Chest pain')

-- NULL, IS NULL, IS NOT NULL
SELECT start_dts, end_dts
FROM edw_emr_ods.encounters
WHERE patient_id = '1'

SELECT start_dts, end_dts
FROM edw_emr_ods.encounters
WHERE patient_id = '1' AND end_dts IS NULL

SELECT start_dts, end_dts
FROM edw_emr_ods.encounters
WHERE patient_id = '1' AND end_dts IS NOT NULL

-- (NOT) LIKE
SELECT *
FROM edw_emr_ods.encounters enc
WHERE enc.start_dts LIKE '%2011-04-02%'

SELECT *
FROM diagnoses
WHERE title LIKE '%HYPER%'

SELECT *
FROM diagnoses
WHERE title NOT LIKE '%HYPER%'

-- Column Aliases
SELECT start_dts, end_dts
FROM encounters
WHERE patient_id = '1'

SELECT start_dts AS start, e.end_dts AS end
FROM encounters
WHERE patient_id = '1'

-- Table Aliases
SELECT start_dts, end_dts
FROM encounters
WHERE patient_id = '1'

SELECT e.start_dts, e.end_dts
FROM encounters AS e
WHERE e.patient_id = '1'

--ORDER BY
SELECT *
FROM diagnoses

SELECT *
FROM diagnoses
ORDER BY title DESC

-- GROUP BY
SELECT COUNT(encounter_id) AS "Number of Encounters", provider_id
FROM encounters
GROUP BY provider_id
ORDER BY  "Number of Encounters" DESC

-- HAVING
-- The HAVING clause is used in place of the WHERE keyword when working with aggregate functions.
SELECT COUNT(encounter_id) AS "Number of Encounters", provider_id
FROM encounters
GROUP BY provider_id
HAVING  COUNT(encounter_id) > 1
ORDER BY  "Number of Encounters" DESC

-- INNER JOIN
SELECT p.patient_id,
       p.patient_nm,
       p.dob,
       p.gender_cd,
       gc.gender_title
FROM patients p
INNER JOIN gender_codes gc
ON p.gender_cd = gc.gender_code_id

-- LEFT OUTER JOIN
SELECT p.patient_id,
       p.patient_nm,
       p.dob,
       p.gender_cd,
       gc.gender_title
FROM patients p
LEFT OUTER JOIN gender_codes gc
ON p.gender_cd = gc.gender_code_id

-- RIGHT OUTER JOIN
SELECT p.patient_id,
       p.patient_nm,
       p.dob,
       p.gender_cd,
       gc.gender_title
FROM patients p
RIGHT OUTER JOIN gender_codes gc
ON p.gender_cd = gc.gender_code_id

-- FULL OUTER JOIN
SELECT p.patient_id,
       p.patient_nm,
       p.dob,
       p.gender_cd,
       gc.gender_title
FROM edw_emr_ods.patients p
FULL OUTER JOIN edw_emr_ods.gender_codes gc
ON p.gender_cd = gc.gender_code_id

-- Self-join (Return a list of patients who are the same gender)
SELECT * from patients

SELECT p1.patient_nm AS Patient1, p2.patient_nm AS Patient2, p1.gender_cd
FROM patients p1, patients p2
WHERE p1.patient_id <> p2.patient_id
AND p1.gender_cd = p2.gender_cd
ORDER BY p1.gender_cd

-- Cross Join (DANGER!!!)
SELECT *
FROM patients p
CROSS JOIN gender_codes gc; -- Explicit

SELECT *
FROM patients p, gender_codes gc; -- Implicit

-- Aggregate Function: COUNT()
SELECT COUNT(*)
FROM encounters

-- Aggregate Functions: MIN(), MAX()
SELECT MIN(end_dts)
FROM encounters

-- Ranking Functions: RANK(), ROW_NUMBER()
-- “ROW_NUMBER numbers all rows sequentially. RANK provides the same numeric value for ties.
-- Returns a list of patients and their encounters ranked by the start time of their encounters, with the most recent listed first
SELECT p.patient_id,
       p.patient_nm,
       e.start_dts,
RANK() OVER (partition by p.patient_id
       ORDER BY e.start_dts
       DESC) AS enc_rnk
FROM patients p
INNER JOIN encounters e
       ON p.patient_id = e.patient_id

-- Data and Time Function: DATEDIFF()
SELECT p.patient_id,
       p.patient_nm,
       e.start_dts,
       e.end_dts,
DATEDIFF(DAY, e.start_dts, e.end_dts) AS los
FROM patients p
INNER JOIN encounters e
  	ON p.patient_id = e.patient_id

SELECT p.patient_id,
       p.patient_nm,
       e.start_dts,
       e.end_dts,
DATEDIFF(HOUR, e.start_dts, e.end_dts) AS los
FROM patients p
INNER JOIN encounters e
  	ON p.patient_id = e.patient_id

-- String Functions
SELECT UPPER('hello')
SELECT LOWER('HELLO')
SELECT LEN('HELLO')
SELECT LTRIM('   HELLO')
SELECT SUBSTRING('HELLO', 1, 2)
SELECT REPLACE('HELLO','LO','P!')
SELECT LEFT('HELLO', 2)

-- SUB QUERY
SELECT x.patient_id
		, x.patient_nm
		, x.start_dts
		, x.enc_rnk
FROM
(
	SELECT p.patient_id
			, p.patient_nm
			, e.start_dts
			, RANK() OVER (partition by p.patient_id ORDER BY e.start_dts DESC) AS enc_rnk
	FROM patients p
		INNER JOIN encounters e
		 ON p.patient_id = e.patient_id
)x
WHERE x.enc_rnk = 1

-- Same results with a Common Table Expression (CTE)
WITH patients_encounters AS -- can also add variable names that coincide with those from 'patients', e.g., (pat_id, pat_nm, s_date, enc_rank)
(
		SELECT p.patient_id
			, p.patient_nm
			, e.start_dts
			, RANK() OVER (partition by p.patient_id ORDER BY e.start_dts DESC) AS enc_rnk
		FROM patients p
			INNER JOIN encounters e
				ON p.patient_id = e.patient_id
)

SELECT *
FROM patients_encounters pe
WHERE pe.enc_rnk = 1

-- Same results using a TEMP TABLE
SELECT p.patient_id
	, p.patient_nm
	, e.start_dts
	, RANK() OVER (partition by p.patient_id ORDER BY e.start_dts DESC) AS enc_rnk
INTO #patients_encounters
FROM edw_emr_ods.patients p
	INNER JOIN encounters e
	  ON p.patient_id = e.patient_id

SELECT *
FROM #patients_encounters pe
WHERE pe.enc_rnk = 1

DROP TABLE #patients_encounters
