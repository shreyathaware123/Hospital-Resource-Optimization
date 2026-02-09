create database 360project;
select * from patients;

-- ✅ Step 1: Initial Check

select * from patients
limit 10;

-- 🧹 Step 2: Data Cleaning

SELECT 
  SUM(patient_id IS NULL) AS null_patient_id,
  SUM(admission_date IS NULL) AS null_admission_date,
  SUM(admission_time IS NULL) AS null_admission_time,
  SUM(discharge_time IS NULL) AS null_discharge_time,
  SUM(age IS NULL) AS null_age,
  SUM(gender IS NULL) AS null_gender,
  SUM(diagnosis IS NULL) AS null_diagnosis,
  SUM(severity IS NULL) AS null_severity,
  SUM(wait_time_min IS NULL) AS null_wait_time_min,
  SUM(bed_id IS NULL) AS null_bed_id
FROM patients;

 -- Conclusion: There are no null values in patients.csv
 
 --  Check for Duplicates:
 
 SELECT patient_id, COUNT(*) AS count
FROM patients
GROUP BY patient_id
HAVING count > 1;

-- Conclusion: There are no duplicates in patients.csv

-- Check Gender Validity: 
SELECT DISTINCT gender FROM patients;

-- Conclusion: gender column is unique

-- Check Age Distribution:

SELECT 
  COUNT(*) AS total,
  COUNT(CASE WHEN age < 0 THEN 1 END) AS negative_age,
  COUNT(CASE WHEN age > 120 THEN 1 END) AS age_above_120
FROM patients;

-- Conclusion:  age column is clean and realistic — no outliers, no bad data entries. 

-- Outlier Detection
-- 1. Using MIN/MAX and Percentiles
-- Basic stats for age
SELECT 
  MIN(age) AS min_age,
  MAX(age) AS max_age,
  AVG(age) AS avg_age
FROM patients;

-- Basic stats for wait_time_min
SELECT 
  MIN(wait_time_min) AS min_wait,
  MAX(wait_time_min) AS max_wait,
  AVG(wait_time_min) AS avg_wait
FROM patients;


--  Step 3: Exploratory Data Analysis (EDA)

-- 1 Gender Distribution:
SELECT gender, COUNT(*) AS total_patients
FROM patients
GROUP BY gender;

-- Conclusion: There are 1883 female patients (F)

	-- There are 1968 male patients (M)
	-- In total, 1883 + 1968 = 3851 patients — matches  total row count

 -- 2 Average Age by Severity:
 SELECT severity, ROUND(AVG(age), 1) AS avg_age
FROM patients
GROUP BY severity;

-- Conclusion: average age of patients grouped by severity of their diagnosis:
	-- Low severity: Average age is 49.6 years
	-- Medium severity: Average age is 47.5 years
	-- High severity: Average age is 49.9 years


 -- 3 Average Wait Time by Diagnosis:
SELECT diagnosis, ROUND(AVG(wait_time_min), 1) AS avg_wait_time
FROM patients
GROUP BY diagnosis
ORDER BY avg_wait_time DESC;

-- 4 Most Common Diagnoses:

SELECT diagnosis, COUNT(*) AS count
FROM patients
GROUP BY diagnosis
ORDER BY count DESC
LIMIT 10;

-- 5 Bed Utilization:
SELECT bed_id, COUNT(*) AS patients_assigned
FROM patients
GROUP BY bed_id
ORDER BY patients_assigned DESC;

-- 6 Admission Day/Hour Patterns:
	-- By admission date
SELECT DATE(admission_date) AS date, COUNT(*) AS admissions
FROM patients
GROUP BY DATE(admission_date)
ORDER BY date;

	-- By hour of day
SELECT HOUR(admission_time) AS hour, COUNT(*) AS admissions
FROM patients
GROUP BY HOUR(admission_time)
ORDER BY hour;


 -- Outlier Detection (For wait_time_min)
--  Step 1: Get the 25% (Q1) and 75% (Q3) values

WITH ranked_waits AS (
  SELECT wait_time_min,
         NTILE(4) OVER (ORDER BY wait_time_min) AS quartile
  FROM patients
)
SELECT 
  MAX(CASE WHEN quartile = 1 THEN wait_time_min END) AS Q1,
  MIN(CASE WHEN quartile = 3 THEN wait_time_min END) AS Q3
FROM ranked_waits;

--  Note : There are some values which are outside 14.5 to 46.5 minutes is an outlier
--  in wait_time_min. So we need to clean it or remove thows rows.alter

DELETE FROM patients
WHERE wait_time_min < 14.5 OR wait_time_min > 46.5;


-- ✅ Step 2: Find the Outliers
SELECT *
FROM patients
WHERE wait_time_min > 110;

-- for small values 
SELECT *
FROM patients
WHERE wait_time_min < 14.5 OR wait_time_min > 46.5;


-- Now we havve a clean data with no outliers, We can proceed now.

SELECT 
  MIN(wait_time_min) AS min_wait,
  MAX(wait_time_min) AS max_wait
FROM patients;

 --- 2) Outlier detection(age column)
--  Step 1: Get Q1 and Q3

WITH ranked_age AS (
  SELECT age,
         NTILE(4) OVER (ORDER BY age) AS quartile
  FROM patients
)
SELECT 
  MAX(CASE WHEN quartile = 1 THEN age END) AS Q1,
  MIN(CASE WHEN quartile = 3 THEN age END) AS Q3
FROM ranked_age;

--  Step 1: Calculate IQR , 
-- IQR = Q3 - Q1 = 49 - 23 = 26
-- Lower limit = 23 - (1.5 × 26) = -16
-- Upper limit = 49 + (1.5 × 26) = 88

-- Note: Here upper limit is 88, that is why i used 88 to deetect the outlier

-- Outlier detected in age 
SELECT *
FROM patients
WHERE age > 88;

-- now deleting them 
DELETE FROM patients
WHERE age > 88;

-- Sucessfully deleted the outliers in age

--- Final 
SELECT MIN(age) AS min_age, MAX(age) AS max_age
FROM patients;


--- For patient_id => No need for outlier detection, cause all the id's are unique

-- for admission_date, admission_time, discharge_time

SELECT *
FROM patients
WHERE discharge_time < admission_time;

-- In the above, code it says that The discharge_time assumes the same date as admission_date,
--  and it doesn't store the real discharge date. So need to fix this


-- Solution:  Assume Discharge Time Is Next Day If It's Earlier Than Admission Time

--  Step 1: Check the Time Format
SELECT admission_time 
FROM patients
LIMIT 5;   # This  code showing the fractional seconds also

-- Step 2: Strip Microseconds Using TIME_FORMAT() or CAST()

SELECT 
  patient_id,
  admission_date,
  admission_time,
  discharge_time,

  -- Combine date and time into full datetime
  TIMESTAMP(admission_date, admission_time) AS admit_time,
  
  -- If discharge time is earlier, assume next day
  TIMESTAMP(
    IF(discharge_time < admission_time, DATE_ADD(admission_date, INTERVAL 1 DAY), admission_date),
    discharge_time
  ) AS discharge_time_fixed,

  -- Stay duration in minutes
  TIMESTAMPDIFF(
    MINUTE,
    TIMESTAMP(admission_date, admission_time),
    TIMESTAMP(
      IF(discharge_time < admission_time, DATE_ADD(admission_date, INTERVAL 1 DAY), admission_date),
      discharge_time
    )
  ) AS stay_minutes
FROM patients;

---- microseconds needs to be fix

SELECT 
  patient_id,
  admission_date,
  admission_time,
  discharge_time,

  -- Clean admission datetime
  TIMESTAMP(admission_date, TIME_FORMAT(admission_time, '%H:%i:%s')) AS admit_time,

  -- Clean discharge datetime with fix
  TIMESTAMP(
    IF(TIME_FORMAT(discharge_time, '%H:%i:%s') < TIME_FORMAT(admission_time, '%H:%i:%s'),
       DATE_ADD(admission_date, INTERVAL 1 DAY),
       admission_date),
    TIME_FORMAT(discharge_time, '%H:%i:%s')
  ) AS discharge_time_fixed,

  -- Stay duration in minutes
  TIMESTAMPDIFF(
    MINUTE,
    TIMESTAMP(admission_date, TIME_FORMAT(admission_time, '%H:%i:%s')),
    TIMESTAMP(
      IF(TIME_FORMAT(discharge_time, '%H:%i:%s') < TIME_FORMAT(admission_time, '%H:%i:%s'),
         DATE_ADD(admission_date, INTERVAL 1 DAY),
         admission_date),
      TIME_FORMAT(discharge_time, '%H:%i:%s')
    )
  ) AS stay_minutes
FROM patients;

-- The above code satisfy below things
-- Microseconds stripped safely -  Yes      
-- Cross-day discharges handled -  Yes      
-- Time difference calculated   -  Yes     
-- Beginner-friendly query      - Achieved 

-- For bed_id

SELECT bed_id, COUNT(*) AS assigned_count
FROM patients
GROUP BY bed_id
ORDER BY assigned_count DESC;

-- For gender

 SELECT DISTINCT gender FROM patients;

-- diagnosis

SELECT diagnosis, COUNT(*) FROM patients
GROUP BY diagnosis
ORDER BY COUNT(*) DESC;

SELECT DISTINCT diagnosis FROM patients ORDER BY diagnosis;

--- Diagnosis has no outlier

-- severity
SELECT DISTINCT severity FROM patients;


