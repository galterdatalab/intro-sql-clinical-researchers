-- Example queries to be used with the NMEDW test database

SELECT 2 + 4

SELECT ROUND(2.5834, 2)

SELECT 'hello' + ' there ' + 'friends!'

SELECT UPPER('hello')


--INNER JOIN

SELECT p.patient_id
		, p.patient_nm
		, p.dob
		, p.gender_cd
		, gc.gender_title
FROM edw_emr_ods.patients p
	INNER JOIN edw_emr_ods.gender_codes gc
	 ON p.gender_cd = gc.gender_code_id




--LEFT OUTER JOIN

SELECT p.patient_id
		, p.patient_nm
		, p.dob
		, p.gender_cd
		, gc.gender_title
FROM edw_emr_ods.patients p
	LEFT OUTER JOIN edw_emr_ods.gender_codes gc
	 ON p.gender_cd = gc.gender_code_id



--The Cartesian JOIN

SELECT *
FROM edw_emr_ods.patients p, edw_emr_ods.gender_codes gc




--DISTINCT

SELECT pm.patient_id
FROM edw_emr_ods.patient_mrns pm

SELECT DISTINCT pm.patient_id
FROM edw_emr_ods.patient_mrns pm

--BETWEEN

SELECT *
FROM edw_emr_ods.encounters enc
WHERE enc.start_dts BETWEEN '01-01-2010' AND '01-01-2011'

--LIKE

SELECT *
FROM edw_emr_ods.diagnoses d
WHERE d.title LIKE '%HYPER%'




--Aggregates

--COUNT()

SELECT COUNT(*)
FROM edw_emr_ods.encounters e

SELECT COUNT(end_dts)
FROM edw_emr_ods.encounters e

--MAX(), MIN()

SELECT MIN(end_dts)
FROM edw_emr_ods.encounters e

SELECT MAX(end_dts)
FROM edw_emr_ods.encounters e


--GROUP BY clauses

SELECT p.patient_nm
		, COUNT(e.encounter_id) AS enc_cnt
		, YEAR(e.start_dts) AS enc_year
FROM edw_emr_ods.patients p
	INNER JOIN edw_emr_ods.encounters e
	 ON p.patient_id = e.patient_id
GROUP BY p.patient_nm
		, YEAR(e.start_dts)
ORDER BY patient_nm, enc_year

--HAVING clauses

SELECT p.patient_nm
		, COUNT(e.encounter_id) AS enc_cnt
		, YEAR(e.start_dts) AS enc_year
FROM edw_emr_ods.patients p
	INNER JOIN edw_emr_ods.encounters e
	 ON p.patient_id = e.patient_id
GROUP BY p.patient_nm
		, YEAR(e.start_dts)
HAVING COUNT(e.encounter_id) >= 2
ORDER BY patient_nm, enc_year

--RANK()

SELECT p.patient_id
		, p.patient_nm
		, e.start_dts
		, RANK() OVER (partition by p.patient_id ORDER BY e.start_dts DESC) AS enc_rnk
FROM edw_emr_ods.patients p
	INNER JOIN edw_emr_ods.encounters e
	 ON p.patient_id = e.patient_id

--DATEDIFF


SELECT p.patient_id
		, p.patient_nm
		, e.start_dts
		, e.end_dts
		, DATEDIFF(DAY, e.start_dts, e.end_dts) AS los
FROM edw_emr_ods.patients p
	INNER JOIN edw_emr_ods.encounters e
	 ON p.patient_id = e.patient_id





--SUB QUERY
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
	FROM edw_emr_ods.patients p
		INNER JOIN edw_emr_ods.encounters e
		 ON p.patient_id = e.patient_id
)x
WHERE x.enc_rnk = 1


--CTE
WITH patients_encounters AS
(
		SELECT p.patient_id
			, p.patient_nm
			, e.start_dts
			, RANK() OVER (partition by p.patient_id ORDER BY e.start_dts DESC) AS enc_rnk
		FROM edw_emr_ods.patients p
			INNER JOIN edw_emr_ods.encounters e
				ON p.patient_id = e.patient_id
)

SELECT *
FROM patients_encounters pe
WHERE pe.enc_rnk = 1


--TEMP TABLE
SELECT p.patient_id
	, p.patient_nm
	, e.start_dts
	, RANK() OVER (partition by p.patient_id ORDER BY e.start_dts DESC) AS enc_rnk
INTO #patients_encounters
FROM edw_emr_ods.patients p
	INNER JOIN edw_emr_ods.encounters e
	  ON p.patient_id = e.patient_id

SELECT *
FROM #patients_encounters pe
WHERE pe.enc_rnk = 1

DROP TABLE #patients_encounters
