# View Whole dataset
select * from staff;

-- STEP 1: View First Few Rows
SELECT * FROM staff
LIMIT 10;

-- Step 2: Check for Missing (NULL) Values
SELECT 
  SUM(staff_id IS NULL) AS null_staff_id,
  SUM(date IS NULL) AS null_date,
  SUM(department IS NULL) AS null_department,
  SUM(shift IS NULL) AS null_shift,
  SUM(absent IS NULL) AS null_absent
FROM staff;

--- conclusion: There are no null values

-- Step 3: Check for Duplicates

SELECT staff_id, date, COUNT(*) AS dup_count
FROM staff
GROUP BY staff_id, date
HAVING dup_count > 1;

-- Step 4: Check Column Values (Cleanliness)

# Distinct Departments
SELECT DISTINCT department FROM staff;


# Distinct Shifts
SELECT DISTINCT shift FROM staff;

# Check absent values
SELECT DISTINCT absent FROM staff;

-- Step 5: Check Date Format
SELECT date FROM staff LIMIT 5;

-- Step 6: Exploratory Data Analysis (EDA)

-- A. Staff count per department
SELECT department, COUNT(*) AS staff_count
FROM staff
GROUP BY department;

-- B. Staff count per shift
SELECT shift, COUNT(*) AS shift_count
FROM staff
GROUP BY shift;

-- C. Absences per department

SELECT department, COUNT(*) AS absents
FROM staff
WHERE absent = 'TRUE'
GROUP BY department;

-- D. Daily absentee trend
SELECT date, COUNT(*) AS total_absent
FROM staff
WHERE absent = 'TRUE'
GROUP BY date
ORDER BY STR_TO_DATE(date, '%d-%m-%Y');

-- Step 7: Outlier Detection(Only the daily absents can be treated numerically.)

--- So we will do outlier detection on daily absent

-- A. Absents per day (for IQR)

-- Get total absents per day
SELECT date, COUNT(*) AS daily_absents
FROM staff
WHERE absent = 'TRUE'
GROUP BY date;

-- since SQL doesn't directly support percentile functions in MySQL.
-- But we can do approximate quartiles like this:

WITH ranked AS (
  SELECT date,
         COUNT(*) AS daily_absents
  FROM staff
  WHERE absent = 'TRUE'
  GROUP BY date
),
quartiles AS (
  SELECT 
    daily_absents,
    NTILE(4) OVER (ORDER BY daily_absents) AS quartile
  FROM ranked
)
SELECT 
  MAX(CASE WHEN quartile = 1 THEN daily_absents END) AS Q1,
  MIN(CASE WHEN quartile = 3 THEN daily_absents END) AS Q3
FROM quartiles;

-- Step 1: Calculate IQR and Limits

-- IQR = Q3 - Q1 = 3 - 2 = 1
-- Lower Bound = Q1 - 1.5 * IQR = 2 - 1.5 * 1 = 0.5  
-- Upper Bound = Q3 + 1.5 * IQR = 3 + 1.5 * 1 = 4.5

-- Step 2: Find Outlier Dates (absents < 0.5 or > 4.5)

SELECT date, COUNT(*) AS daily_absents
FROM staff
WHERE absent = 'TRUE'
GROUP BY date
HAVING daily_absents < 1 OR daily_absents > 4;

-- Note: After running i got to know that On 2025-01-05, 5 absences were recorded, which is above the upper threshold of 4.5 (IQR method). This is considered an outlier and may indicate a special event, 
							-- staff issue, or data anomaly."
                            
SELECT *
FROM staff
WHERE date != '2025-01-05' OR absent = 'FALSE';

# Summary of above code
-- All rows not from 2025-01-05, or
-- Rows from 2025-01-05 where the staff was not absent

# QUESTIONS I think on this absent column , for my understanding
-- 1. How many staff were absent per day
-- 2. How many absences per department
-- 3. How many absences per shift