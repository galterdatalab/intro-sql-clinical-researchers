/*

Warm up!

*/

/* Query 1

How many departments are in the hospital database?

Answer = 5

*/

SELECT *
FROM departments d

-- or

SELECT COUNT(*)
FROM departments d

/* Query 2

How many encounters has the patient with 'patient_id' 1 have?

Answer = 4

*/

SELECT count(*)
FROM encounters
WHERE patient_id = '1'

/* Query 3

How many of Patient 1's encounters are missing a discharge time ('end_dts' value = NULL)?

Answer = 2

*/

SELECT *
FROM encounters
WHERE patient_id = '1'

-- or, even better...

SELECT *
FROM encounters
WHERE patient_id = '1' AND end_dts IS NULL

/* Query 4

Which provider has worked the most encounters in the database?

Answer = provider_id 5 has worked 11 encounters

*/

SELECT COUNT(encounter_id) AS "Number of Encounters", provider_id
FROM encounters
GROUP BY provider_id
ORDER BY  "Number of Encounters" DESC

/* Query 5

Which patient has the first (oldest) encounter in the hospital database?

Answer = Patient 4, Elaine Benes

*/

-- Using a TEMP TABLE
--
-- Returns a list of patients and their encounters ranked by the start time of their encounters, with the oldest listed first

SELECT p.patient_id
	, p.patient_nm
	, e.start_dts
	, RANK() OVER (partition by p.patient_id ORDER BY e.start_dts ASC) AS enc_rnk
INTO #patients_encounters
FROM edw_emr_ods.patients p
	INNER JOIN encounters e
	  ON p.patient_id = e.patient_id

-- Now that you have the oldest encounter for each patient, find out which patient has the oldest encounter of all

SELECT *
FROM #patients_encounters pe
WHERE pe.enc_rnk = 1
ORDER BY pe.start_dts


/* More Advanced Queries

	 NOTE:
   'edw.emr.ods' is the name of the database schema and it is sometimes added as a prefix to the table name. This is an explicit way
	 of identifying which schema the table comes from (some databases have more than one schema). This database has only one schema,
	 so it's not necessary to include it, but I've done so here to show how it works.

	 For reference, I've included SELECT * statements that are relevant for each query in case you want to check the table contents
*/


/* Query 6

List the provider's name and title (in one field) by the number of patient encounters they've had in order from most to least

*/

-- Reference

--select * FROM edw_emr_ods.departments
--select * FROM edw_emr_ods.diagnoses
--select * FROM edw_emr_ods.encounter_diagnoses
--select * FROM edw_emr_ods.encounter_type_code
select * FROM edw_emr_ods.encounters
--select * FROM edw_emr_ods.gender_codes
--select * FROM edw_emr_ods.patient_mrns
--select * FROM edw_emr_ods.patients
select * FROM edw_emr_ods.providers


SELECT p.provider_nm + ',' + p.title AS [name/title], COUNT(e.provider_id) AS [encounter count],
DENSE_RANK() OVER (ORDER BY COUNT(e.provider_id) DESC) AS ranking
FROM edw_emr_ods.providers as p
LEFT JOIN edw_emr_ods.encounters as e
ON p.provider_id=e.provider_id
AND deleted_ind <> 1 -- Record is not deleted
AND start_dts IS NOT NULL -- Make sure there's a start date
AND start_dts <= GETDATE() -- Ignore any "future dates" (bad data)
GROUP BY p.provider_nm,p.title


/* Query 7

	 List all patients with a diagnosis of 'hypertension', the diagnosis date, and their provider

*/

-- Reference

--select * FROM edw_emr_ods.departments
select * FROM edw_emr_ods.diagnoses
select * FROM edw_emr_ods.encounter_diagnoses
--select * FROM edw_emr_ods.encounter_type_codes
select * FROM edw_emr_ods.encounters
--select * FROM edw_emr_ods.gender_codes
--select * FROM edw_emr_ods.patient_mrns
select * FROM edw_emr_ods.patients
select * FROM edw_emr_ods.providers


SELECT p.patient_nm,e.start_dts,pr.provider_nm
FROM edw_emr_ods.encounters as e
LEFT JOIN edw_emr_ods.patients as p
ON e.patient_id=p.patient_id
LEFT JOIN edw_emr_ods.encounter_diagnoses as ed
ON e.encounter_id=ed.encounter_id
LEFT JOIN edw_emr_ods.diagnoses as d
ON ed.diagnosis_id=d.diagnosis_id
LEFT JOIN edw_emr_ods.providers as pr
ON e.provider_id=pr.provider_id
WHERE d.title='Hypertension'
AND deleted_ind <> 1
AND start_dts <= GETDATE()
AND start_dts IS NOT NULL
GROUP BY p.patient_nm,e.start_dts,pr.provider_nm


/* Query 8

	 List the code and title of each diagnosis and count how many diagnoses of each type there have been

*/

-- Reference

--select  * FROM edw_emr_ods.departments
select * FROM edw_emr_ods.diagnoses
select * FROM edw_emr_ods.encounter_diagnoses
--select * FROM edw_emr_ods.encounter_type_codes
select * FROM edw_emr_ods.encounters
--select * FROM edw_emr_ods.gender_codes
--select * FROM edw_emr_ods.patient_mrns
--select * FROM edw_emr_ods.patients
--select * FROM edw_emr_ods.providers

/* Two ways to do it...*/

-- Short way --

SELECT d.code,d.title,COUNT(ed.diagnosis_id) as [# diagnosed]
FROM edw_emr_ods.diagnoses as d
LEFT JOIN edw_emr_ods.encounter_diagnoses as ed
ON ed.diagnosis_id=d.diagnosis_id
LEFT JOIN edw_emr_ods.encounters as e
ON e.encounter_id=ed.encounter_id
AND deleted_ind <> 1
AND start_dts <= GETDATE()
AND start_dts IS NOT NULL
GROUP BY d.title,d.code
ORDER BY [# diagnosed] DESC

-- Using a common table expression (CTE) --

WITH Q AS
(
	SELECT ed.diagnosis_id
	FROM edw_emr_ods.encounter_diagnoses AS ed
	JOIN edw_emr_ods.encounters AS e
	ON e.encounter_id=ed.encounter_id
	WHERE e.start_dts IS NOT NULL
	AND e.start_dts <= GETDATE() --Not necessary in this case because encounter 18 (the only one with a future date) in not in the encounter_diagnosis table
	AND e.deleted_ind <> 1 --Not necessary in this case because encounter 12 (the only on that has deleted_ind = 1) is in the encounter_diagnosis table
)

SELECT d.code,d.title,COUNT(Q.diagnosis_id) AS count
FROM edw_emr_ods.diagnoses AS d
LEFT JOIN Q
ON d.diagnosis_id=Q.diagnosis_id
--WHERE Q.diagnosis_id IS NULL --Adding this line will return only the diagnoses with a '0' count
GROUP BY d.code,d.title
ORDER BY count DESC


/* Query 9

   List the current ages of all patients

*/

--This way is not precise
SELECT patient_nm,dob,DATEDIFF(year,dob,GETDATE()) AS age
FROM edw_emr_ods.patients

--Using 'day' is better, but still not precise enough
SELECT patient_nm,dob,FLOOR(DATEDIFF(day,dob,GETDATE()) / 365.242199)  AS age
FROM edw_emr_ods.patients

--Using hour and truncating the decimal is the best way (see 'AgeYearsIntTrunc' below)
SELECT patient_nm,dob,DATEDIFF(hour,dob,GETDATE())/8766.0 AS AgeYearsDecimal
    ,CONVERT(int,ROUND(DATEDIFF(hour,dob,GETDATE())/8766.0,0)) AS AgeYearsIntRound
    ,DATEDIFF(hour,dob,GETDATE())/8766 AS AgeYearsIntTrunc -------------------------------- Best way to report age
FROM edw_emr_ods.patients


/* Query 10

   List all of the encounter_ids from the internal medicine group, along with start and end dates and provider names

*/

-- Reference

select * FROM edw_emr_ods.departments
--select * FROM edw_emr_ods.diagnoses
--select * FROM edw_emr_ods.encounter_diagnoses
--select * FROM edw_emr_ods.encounter_type_codes
select * FROM edw_emr_ods.encounters
--select * FROM edw_emr_ods.gender_codes
--select * FROM edw_emr_ods.patient_mrns
--select * FROM edw_emr_ods.patients
select * FROM edw_emr_ods.providers
--

SELECT d.department_nm,e.encounter_id,e.start_dts,e.end_dts,p.provider_nm
FROM edw_emr_ods.encounters as e
JOIN edw_emr_ods.departments as d
ON e.department_id=d.department_id
JOIN edw_emr_ods.providers as p
ON e.provider_id=p.provider_id
WHERE e.department_id = 1
AND start_dts IS NOT NULL
AND deleted_ind <> 1
AND start_dts <= GETDATE()
ORDER BY p.provider_nm,e.start_dts


/* Query 11

   List all of the encounters recorded by nurses

*/

-- Reference

--select * FROM edw_emr_ods.departments
--select * FROM edw_emr_ods.diagnoses
--select * FROM edw_emr_ods.encounter_diagnoses
--select * FROM edw_emr_ods.encounter_type_codes
select * FROM edw_emr_ods.encounters
--select * FROM edw_emr_ods.gender_codes
--select * FROM edw_emr_ods.patient_mrns
--select * FROM edw_emr_ods.patients
select * FROM edw_emr_ods.providers
--

-- Best way
SELECT e.encounter_id,p.provider_nm + ',' + p.title AS [provider name / title]
FROM edw_emr_ods.encounters AS e
JOIN edw_emr_ods.providers AS p
ON e.provider_id=p.provider_id
WHERE p.title='RN'
AND start_dts IS NOT NULL
AND deleted_ind <> 1
AND start_dts <= GETDATE()

-- Unnecessarily verbose way
SELECT e.encounter_id,p.provider_nm + ',' + p.title AS [provider name / title]
FROM edw_emr_ods.encounters AS e
JOIN edw_emr_ods.providers AS p
ON e.provider_id=p.provider_id
AND start_dts IS NOT NULL
AND deleted_ind <> 1
AND start_dts <= GETDATE()
GROUP BY e.encounter_id,provider_nm,p.title
HAVING p.title = 'RN'
ORDER BY provider_nm

/* Query 12

   List all of the providers that share patients with Nick Riviera along with the number of patients they share with him

*/

-- Reference

--select * FROM edw_emr_ods.departments
--select * FROM edw_emr_ods.diagnoses
--select * FROM edw_emr_ods.encounter_diagnoses
--select * FROM edw_emr_ods.encounter_type_codes
select * FROM edw_emr_ods.encounters
--select * FROM edw_emr_ods.gender_codes
--select * FROM edw_emr_ods.patient_mrns
--select * FROM edw_emr_ods.patients
select * FROM edw_emr_ods.providers
--

-- Using a common table expression (CTE)
WITH Q AS
(
	SELECT p.provider_id,p.provider_nm,e.patient_id,
	ROW_NUMBER() OVER (PARTITION BY e.patient_id ORDER BY e.patient_id) AS RowNum
	FROM edw_emr_ods.encounters as e
	LEFT JOIN edw_emr_ods.providers as p
	ON e.provider_id=p.provider_id
	WHERE e.provider_id <> 1 AND e.patient_id IN
		(SELECT e2.patient_id
		 FROM edw_emr_ods.encounters as e2
		 WHERE e2.provider_id = 1)
	AND start_dts IS NOT NULL
	AND deleted_ind <> 1
	AND start_dts <= GETDATE()
	GROUP BY p.provider_id,p.provider_nm,e.patient_id
)

SELECT provider_nm,COUNT(provider_nm)
FROM Q
GROUP BY provider_nm


/* Query 13

   Which patient has had contact with the most doctors? (Order from greatest to least doctors seen)

*/

-- Reference

--select * FROM edw_emr_ods.departments
--select * FROM edw_emr_ods.diagnoses
--select * FROM edw_emr_ods.encounter_diagnoses
--select * FROM edw_emr_ods.encounter_type_codes
select * FROM edw_emr_ods.encounters
--select * FROM edw_emr_ods.gender_codes
--select * FROM edw_emr_ods.patient_mrns
select * FROM edw_emr_ods.patients
--select * FROM edw_emr_ods.providers
--

SELECT e.patient_id, p.patient_nm, COUNT (DISTINCT provider_id) AS [# of docs seen]
FROM edw_emr_ods.encounters AS e
JOIN edw_emr_ods.patients AS p
ON e.patient_id=p.patient_id
WHERE start_dts IS NOT NULL
	  AND deleted_ind <> 1
	  AND start_dts <= GETDATE()
GROUP BY e.patient_id,p.patient_nm
ORDER BY [# of docs seen] DESC

/* Query 14

   Create a new column that shows three categories of admission dates: Before 2005, 2005-2010, and After 2010. Next, find out 1) how many
   encounters and 2) how many patients occurred within these date categories

*/

-- Reference

--select * FROM edw_emr_ods.departments
--select * FROM edw_emr_ods.diagnoses
--select * FROM edw_emr_ods.encounter_diagnoses
--select * FROM edw_emr_ods.encounter_type_codes
select * FROM edw_emr_ods.encounters
--select * FROM edw_emr_ods.gender_codes
--select * FROM edw_emr_ods.patient_mrns
--select * FROM edw_emr_ods.patients
--select * FROM edw_emr_ods.providers
--
GO;

WITH Q AS
(
	SELECT e.encounter_id,e.patient_id,
	CASE
		WHEN start_dts < '2005-01-01' THEN '1:Before 2005'
		WHEN start_dts >= '2005-01-01' AND start_dts < '2011-01-01' THEN '2:2005-2010'
		WHEN start_dts >= '2011-01-01' THEN '3:After 2010'
		ELSE 'UNKNOWN'
	END AS [date category]
	FROM edw_emr_ods.encounters AS e
	WHERE deleted_ind <> 1
	AND start_dts IS NOT NULL
	AND start_dts <= GETDATE()
)


SELECT [date category],COUNT(encounter_id) as [# of encounters],COUNT(DISTINCT patient_id) AS [# of patients]
FROM Q
GROUP BY [date category]


/* Query 15

   List all encounters where end_dts is NULL (then list all encounters where end_dts is any year but 2011)

*/

-- Must use 'IS NULL' and not '='. See three value logic explanation at the top of the page
SELECT encounter_id,start_dts,end_dts
FROM edw_emr_ods.encounters
WHERE end_dts IS NULL

-- This is not sargable!
SELECT encounter_id,start_dts,end_dts
FROM edw_emr_ods.encounters
WHERE YEAR(end_dts) <> '2011'

-- The sargable way
SELECT encounter_id,start_dts,end_dts
FROM edw_emr_ods.encounters
WHERE end_dts < '1/1/2011' OR end_dts > '12/31/2011'


/* Query 16

   Find out how long each patient encounter lasted. There are only 5 encounters where the end_dts is not NULL, and two of those have 'negative time',
   which is obviously bad data.

*/

-- Reference

--select * FROM edw_emr_ods.departments
--select * FROM edw_emr_ods.diagnoses
--select * FROM edw_emr_ods.encounter_diagnoses
--select * FROM edw_emr_ods.encounter_type_codes
select * FROM edw_emr_ods.encounters
--select * FROM edw_emr_ods.gender_codes
--select * FROM edw_emr_ods.patient_mrns
--select * FROM edw_emr_ods.patients
--select * FROM edw_emr_ods.providers
--
GO;

SELECT encounter_id,start_dts,end_dts,
CASE
	WHEN start_dts > end_dts THEN CAST(DATEDIFF(hour,start_dts,end_dts) AS NVARCHAR) + ' hours: Not possible!'
	WHEN start_dts < end_dts THEN CAST(DATEDIFF(hour,start_dts,end_dts) AS NVARCHAR) + ' hours'
	WHEN start_dts > GETDATE() THEN 'Future start date: Not possible!'
	WHEN end_dts > GETDATE() THEN 'Future end date: Not possible!'
	ELSE 'UNKNOWN'
END AS duration
FROM edw_emr_ods.encounters

/* Query 17

   List all of the encounters and who the records were entered by, or '?' if this is unknown.

   An example using COALESCE(). Without using CONVERT() or CAST() to change entered_by_provider_id to an NVARCHAR, I get this error
   Msg 245, Level 16, State 1, Line 1
   Conversion failed when converting the nvarchar value '?' to data type tinyint.

   CAST() is preferred over CONVERT() and PARSE() because CAST() is ANSI-compliant (see page 82 in book)

*/

-- Reference

--select * FROM edw_emr_ods.departments
--select * FROM edw_emr_ods.diagnoses
select * FROM edw_emr_ods.encounter_diagnoses
--select * FROM edw_emr_ods.encounter_type_codes
--select * FROM edw_emr_ods.encounters
--select * FROM edw_emr_ods.gender_codes
--select * FROM edw_emr_ods.patient_mrns
--select * FROM edw_emr_ods.patients
--select * FROM edw_emr_ods.providers
--


SELECT encounter_id, encounter_diagnoses_id,diagnosis_id,COALESCE(CAST(entered_by_provider_id AS NVARCHAR), N'?') AS [entered by...]
FROM edw_emr_ods.encounter_diagnoses
ORDER BY [entered by...] DESC

/* Query 18

   Which department had the most admissions from 2005 to 2011?

*/

-- Reference

select * FROM edw_emr_ods.departments
--select * FROM edw_emr_ods.diagnoses
--select * FROM edw_emr_ods.encounter_diagnoses
--select * FROM edw_emr_ods.encounter_type_codes
select * FROM edw_emr_ods.encounters
--select * FROM edw_emr_ods.gender_codes
--select * FROM edw_emr_ods.patient_mrns
--select * FROM edw_emr_ods.patients
--select * FROM edw_emr_ods.providers


SELECT d.department_nm,COUNT(e.department_id) AS [admission count],
DENSE_RANK() OVER (ORDER BY COUNT(e.department_id) DESC) AS [admission ranking]
FROM edw_emr_ods.departments as d
LEFT JOIN edw_emr_ods.encounters AS e
ON e.department_id=d.department_id
WHERE start_dts >= '1/1/2005' AND start_dts <= '12/31/2011'
AND start_dts IS NOT NULL
AND start_dts <= GETDATE()
AND deleted_ind <> 1
GROUP BY e.department_id,d.department_nm


/* Query 19

List all of the providers that share patients with Nick Riviera along with the
number of patients they share with him

*/

WITH Q AS
(
	SELECT e.patient_id,e.encounter_id,e.start_dts,p.provider_nm,
	ROW_NUMBER() OVER (PARTITION BY e.provider_id ORDER BY e.provider_id) AS [rank]
	FROM edw_emr_ods.encounters AS e
	JOIN edw_emr_ods.providers AS p
	ON e.provider_id=p.provider_id
	WHERE e.provider_id <> '1' AND e.patient_id IN
	    (SELECT e2.patient_id
		 FROM edw_emr_ods.encounters AS e2
		 WHERE e2.provider_id = '1')
	AND e.deleted_ind <> 1
	GROUP BY e.encounter_id,e.start_dts,e.patient_id,e.provider_id,p.provider_nm
)

SELECT provider_nm,COUNT(DISTINCT(patient_id)) AS [Number of patients]
FROM Q
GROUP BY provider_nm
ORDER BY [Number of Patients] DESC
